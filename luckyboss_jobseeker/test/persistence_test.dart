import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckyboss_jobseeker/core/constants/app_data.dart';
import 'package:luckyboss_jobseeker/models/onboarding_model.dart';
import 'package:luckyboss_jobseeker/models/seeker_profile_model.dart';
import 'package:luckyboss_jobseeker/providers/job_seeker_provider.dart';
import 'package:luckyboss_jobseeker/services/auth_service.dart';
import 'package:luckyboss_jobseeker/services/job_catalog_service.dart';
import 'package:luckyboss_jobseeker/services/local_store.dart';

/// Covers the two failures sir hit on the handset, and the category rework.
///
/// Both bugs looked unrelated on screen — one was "the app forgot I signed in",
/// the other was a toast saying "Please sign in again to update your photo" —
/// and both came from the same omission: an offline sign-in returned success
/// without writing anything to storage. These tests exist so that cannot come
/// back silently.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('sign-in survives a restart', () {
    test('an on-device account is persisted and reads back', () async {
      // No server is reachable in a test, so this takes the offline path —
      // exactly what happens on sir's handset. Registering first, because
      // sign-in now refuses an email it has never seen.
      await AuthService.register(
        name: 'Raja',
        email: 'raja@example.com',
        phone: '', countryCode: '+91',
        password: 'password123',
      );
      await AuthService.logout();

      final result = await AuthService.login(
        email: 'raja@example.com',
        password: 'password123',
      );

      expect(result.success, isTrue);
      expect(result.session!.isLocal, isTrue,
          reason: 'an account no server issued must be marked local');

      // The restart: nothing in memory, everything read back from storage.
      final restored = await AuthService.currentSession();
      expect(restored, isNotNull,
          reason: 'this returned null before the fix, which threw the '
              'candidate back to the sign-in screen on every launch');
      expect(restored!.email, 'raja@example.com');
      expect(restored.isLocal, isTrue);
      expect(await AuthService.isLoggedIn(), isTrue);
    });

    test('a verified phone sign-in is persisted', () async {
      final result = await AuthService.exchangeFirebaseToken(
        'test-token',
        phone: '+919944995493',
      );

      expect(result.success, isTrue);
      expect((await AuthService.currentSession())?.phone, '+919944995493');
    });

    test('reaching the OTP screen does not sign anyone in', () async {
      await AuthService.sendPhoneOtp(fullPhoneNumber: '+6591234567');

      expect(await AuthService.currentSession(), isNull,
          reason: 'a session must only exist after the code is verified');
    });

    test('an unknown email is refused rather than invented', () async {
      // Sir has to see the path every real user hits first. Any email with any
      // password used to succeed, so there was no such thing as a wrong
      // sign-in and a typo silently made a second, empty account.
      final result =
          await AuthService.login(email: 'nobody@example.com', password: 'password123');

      expect(result.success, isFalse);
      expect(AuthService.isUnknownAccount(result.message), isTrue);
      expect(await AuthService.currentSession(), isNull);
    });

    test('the wrong password is refused', () async {
      await AuthService.register(
        name: 'Raja',
        email: 'raja@example.com',
        phone: '', countryCode: '+91',
        password: 'password123',
      );
      await AuthService.logout();

      final result = await AuthService.login(
        email: 'raja@example.com',
        password: 'not-the-password',
      );

      expect(result.success, isFalse);
      expect(AuthService.isUnknownAccount(result.message), isFalse,
          reason: 'a wrong password is not a missing account, and offering to '
              'create one here would make a duplicate');
    });

    test('no invented phone number or name is stored', () async {
      await AuthService.register(
        name: 'A', email: 'a@b.com', phone: '', countryCode: '+91', password: 'password123');
      final session = (await AuthService.currentSession())!;

      expect(session.phone, isNull,
          reason: "the app used to store a stranger's number, +919876543210");

      SharedPreferences.setMockInitialValues({});
      await AuthService.loginDemo();
      expect((await AuthService.currentSession())!.name, isEmpty,
          reason: "the demo account used to claim to be 'Santosh Durai'");
    });

    test('signing out clears the session', () async {
      await AuthService.register(
          name: 'A', email: 'a@b.com', phone: '', countryCode: '+91', password: 'password123');
      await AuthService.logout();

      expect(await AuthService.currentSession(), isNull);
    });
  });

  group('the profile photo can be set without a server', () {
    test('a local account sends no Authorization header', () async {
      await AuthService.register(
          name: 'A', email: 'a@b.com', phone: '', countryCode: '+91', password: 'password123');

      final headers = await AuthService.authHeaders();

      // This is what makes the photo save locally instead of reporting
      // "Please sign in again to update your photo": the upload path sees no
      // token, concludes there is no server to talk to, and keeps the bytes on
      // the device rather than treating it as a failure.
      expect(headers.containsKey('Authorization'), isFalse);
      expect(await AuthService.isLocalAccount(), isTrue);
    });
  });

  group('the candidate profile survives a restart', () {
    test('profile, saved jobs and applications are written and read', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();

      provider.applyOnboarding(
        category: 'Construction',
        roleTitle: 'Mason',
        certificates: const ['Safety Orientation Course'],
        languages: const ['Tamil', 'English'],
        workPermitStatuses: const ['Have a valid work permit'],
        payPeriod: 'Per day',
        isStudent: false,
        currentCity: 'Chennai',
      );
      provider.setSkills(const ['Brickwork', 'Plastering']);
      provider.toggleSaved('job-201');
      await provider.flush();

      final reopened = JobSeekerProvider();
      await reopened.hydrateFromDevice();

      expect(reopened.profile.roleTitle, 'Mason');
      expect(reopened.profile.preferredCategory, 'Construction');
      expect(reopened.profile.certificates, contains('Safety Orientation Course'));
      expect(reopened.profile.languages, contains('Tamil'));
      expect(reopened.profile.workPermitStatus, 'Have a valid work permit');
      expect(reopened.profile.payPeriod, 'Per day');
      expect(reopened.profile.currentCity, 'Chennai');
      expect(reopened.profile.skills, contains('Brickwork'));
      expect(reopened.isSaved('job-201'), isTrue);
    });

    test('signing out wipes the device copy', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();
      provider.setSkills(const ['Brickwork']);
      await provider.flush();

      await provider.signOut();

      expect(await LocalStore.loadProfile(), isNull,
          reason: 'the next person to sign in on this handset must not see '
              'the previous one’s profile');
    });

    test('an older profile keeps the market it chose', () async {
      // A build before multi-market support wrote a single 'preferredCountry'.
      // Reading only the new key would silently discard the answer of every
      // candidate who onboarded before this change.
      SharedPreferences.setMockInitialValues({
        'luckyboss_profile_v1': jsonEncode({
          'name': 'Returning Candidate',
          'preferredCountry': 'SG',
        }),
      });

      final profile = await LocalStore.loadProfile();

      expect(profile, isNotNull);
      expect(profile!.preferredCountries, ['SG']);
      expect(profile.preferredCountry, 'SG');
    });

    test('several markets can be chosen and read back', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();

      provider.answerPrompt('preferred_country', ['Singapore', 'Malaysia']);
      await provider.flush();

      final reopened = JobSeekerProvider();
      await reopened.hydrateFromDevice();

      expect(reopened.profile.preferredCountries, ['SG', 'MY']);
      expect(reopened.profile.wantsCountry('MY'), isTrue);
      expect(reopened.profile.wantsCountry('IN'), isFalse);
    });

    test('a corrupt stored profile does not stop the app opening', () async {
      SharedPreferences.setMockInitialValues({
        'luckyboss_profile_v1': 'not json at all',
      });

      expect(await LocalStore.loadProfile(), isNull);
    });
  });

  group('onboarding asks for a name before anything else', () {
    test('the account step gates the wizard', () {
      final data = OnboardingData();

      // The nag that would not go away: the app told candidates to add their
      // name on every launch and never asked for one.
      expect(data.accountStepComplete, isFalse);
      data.name = 'Santosh';
      expect(data.accountStepComplete, isTrue);
    });

    test('one category, not several', () {
      final data = OnboardingData()..category = 'Construction';

      expect(data.categoryStepComplete, isTrue);
      expect(data.categories, ['Construction']);

      // Reverted deliberately: every screen after this is built from the
      // chosen category's vocabulary, so a second choice had nowhere to go.
      data.category = 'Warehouse & Logistics';
      expect(data.categories, ['Warehouse & Logistics']);
    });

    test('the name reaches the profile and the session', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();

      await provider.setProfileField('name', 'Santosh Durai');
      await provider.setProfileField('email', 'santosh@example.com');
      await provider.flush();

      final reopened = JobSeekerProvider();
      await reopened.hydrateFromDevice();

      expect(reopened.profile.name, 'Santosh Durai');
      expect(reopened.profile.email, 'santosh@example.com');
      // With a name on file the completion nudge stops asking for one.
      expect(reopened.nextProfileStep, isNot('Add your name'));
    });

    test('an unset category no longer reports itself as "All Roles"', () {
      final profile = SeekerProfileModel();

      // It used to return the filter label, so every lookup missed and the
      // candidate was offered every ability in the app at once.
      expect(profile.preferredCategory, isEmpty);
      expect(AppData.abilitiesFor(category: '', role: 'Warehouse Assistant'),
          isNot(contains('Brickwork')));
    });
  });

  group('the app covers work beyond desk jobs', () {
    test('categories are ordered by demand, construction first', () {
      // Not §58's order any more. Shantosh asked for a fixed demand ranking
      // with IT high rather than buried at thirteenth, after I flagged that it
      // deviates from the spec. Construction still leads — it is the agency's
      // core business and the reason the app was rebuilt around field work.
      expect(AppData.workCategories.first.name, 'Construction');
      expect(AppData.workCategories[1].name, 'IT & Software');
      expect(AppData.workCategories[2].name, 'Manufacturing');

      // The point of the change: IT is near the top, and the field categories
      // that carry this agency's volume are not pushed off the first screen.
      final names = AppData.workCategories.map((c) => c.name).toList();
      expect(names.indexOf('Warehouse & Logistics'), lessThan(6));
      expect(names.indexOf('Maid & Caregiver'), lessThan(10));
    });

    test('every field category offers roles and abilities to tap', () {
      for (final category in AppData.workCategories) {
        expect(category.roles, isNotEmpty, reason: category.name);
        expect(category.abilities, isNotEmpty, reason: category.name);
      }
    });

    test('trade vocabulary is searchable', () {
      final terms = AppData.verifiedSkillDictionary.map((s) => s.toLowerCase());
      for (final expected in ['brickwork', 'arc welding', 'forklift operating']) {
        expect(terms, contains(expected));
      }
      expect(AppData.allRoleTitles, contains('Plumber'));
    });

    test('a field profile can reach 100% without a resume or a bio', () {
      final mason = SeekerProfileModel(
        name: 'Test Candidate',
        phone: '+919944995493',
        preferredCategories: const ['Construction'],
        roleTitle: 'Mason',
        skills: const ['Brickwork', 'Plastering', 'Concreting'],
        certificates: const ['Safety Orientation Course'],
        languages: const ['Tamil'],
        workPermitStatuses: const ['Citizen'],
        availability: 'Immediately',
        photoUrl: 'data:image/jpeg;base64,AAAA',
      );

      expect(mason.isFieldWork, isTrue);
      // Under the old single formula this profile capped out in the sixties,
      // because 40% of the score sat behind a resume document and an
      // "Executive Bio" that a mason has no way to produce.
      expect(mason.profileStrengthPercent, 100);
    });

    test('a professional profile is still scored as a CV', () {
      final engineer = SeekerProfileModel(
        name: 'Test Candidate',
        phone: '+6591234567',
        email: 'test@example.com',
        preferredCategories: const ['IT & Software'],
        skills: const ['Flutter', 'Dart', 'SQL'],
        resumeFileName: 'cv.pdf',
        bio: 'Mobile engineer with several years building recruitment products.',
      );

      expect(engineer.isFieldWork, isFalse);
      expect(engineer.profileStrengthPercent, 100);
    });

    test('every category has vacancies in every market', () async {
      // Checked per country, not globally. The feed opens filtered to the
      // candidate's own market, so a category seeded only in Singapore is still
      // an empty feed for someone in Chennai — which is the failure the whole
      // category rework exists to remove.
      for (final country in const ['IN', 'SG', 'MY']) {
        final provider = JobSeekerProvider();
        await provider.loadJobs(force: true);
        provider.setCountry(country);
        final covered = <String>{};
        for (final category in AppData.workCategories) {
          provider.setCategory(category.name);
          if (provider.filteredJobs.isNotEmpty) covered.add(category.name);
        }
        _expectFieldCategoriesCovered(covered, country);
      }
    });

    test('the bundled catalogue stays removable', () async {
      final jobs = await JobCatalogService.loadSeed();

      expect(jobs, isNotEmpty);
      // Both markers matter. `isSeed` is the column a later
      // `DELETE FROM jobs WHERE seed = 1` keys on, and the id prefix is what
      // makes a stray sample obvious in the database by eye.
      expect(jobs.every((j) => j.isSeed), isTrue);
      expect(jobs.every((j) => j.id.startsWith('seed-')), isTrue);
    });

    test('a vacancy never asks for a licence its trade does not use', () async {
      final jobs = await JobCatalogService.loadSeed();

      for (final job in jobs) {
        final expected = AppData.certificatesFor(
            category: job.category, role: job.role);
        for (final certificate in job.requiredCertificates) {
          // The generated catalogue advertised an Electrician who needed a
          // Crane Operator Licence, because skills and licences were sampled
          // across the whole category. Both now come from the role itself.
          expect(expected, contains(certificate),
              reason: '${job.role} does not need $certificate');
        }
        for (final skill in job.requiredSkills) {
          expect(AppData.abilitiesFor(category: job.category, role: job.role),
              contains(skill),
              reason: '${job.role} does not involve $skill');
        }
      }
    });
  });
}

/// Not every category needs a seeded vacancy, but the field ones do — choosing
/// Construction and landing on an empty feed is the clearest possible way to
/// tell a candidate the app has no work for them.
void _expectFieldCategoriesCovered(Set<String> covered, String country) {
  for (final category in AppData.workCategories) {
    if (!category.isField) continue;
    expect(covered, contains(category.name),
        reason: '${category.name} has no vacancy in $country');
  }
}
