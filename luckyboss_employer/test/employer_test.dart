import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckybossemployer/core/constants/app_data.dart';
import 'package:luckybossemployer/core/theme/app_theme.dart';
import 'package:luckybossemployer/models/candidate.dart';
import 'package:luckybossemployer/models/employer_job.dart';
import 'package:luckybossemployer/providers/employer_provider.dart';
import 'package:luckybossemployer/services/candidate_pool_service.dart';
import 'package:luckybossemployer/services/local_store.dart';

/// The employer portal, rebuilt on the same foundation as the seeker app.
///
/// These cover the three things that were wrong with it and are easy to break
/// again: nothing was written to the device, a vacancy could not describe field
/// work, and the candidate pool was three software engineers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CandidatePoolService.resetCache();
  });

  /// Puts the provider in the state a verified company is in.
  ///
  /// Set directly because nothing in the app may set it — verification is a
  /// server decision, and a test that reached it through the UI would be
  /// testing a path that must not exist.
  void verify(EmployerProvider provider) => provider.updateCompany(
        provider.company.copyWith(
          name: 'Test Builders',
          email: 'hr@test.com',
          status: CompanyStatus.verified,
        ),
      );

  EmployerJobModel masonJob({
    List<String> certificates = const [],
    String country = 'IN',
  }) =>
      EmployerJobModel(
        id: 'job-test',
        role: 'Mason',
        title: 'Mason',
        category: 'Construction',
        companyName: 'Test Builders',
        location: 'Chennai',
        countryCode: country,
        minSalary: '22000',
        maxSalary: '30000',
        currency: 'INR',
        payPeriod: 'Per month',
        requiredSkills: const ['Brickwork', 'Plastering'],
        requiredCertificates: certificates,
        postedDate: DateTime.now(),
      );

  group('a posted vacancy survives the app closing', () {
    test('jobs and company are written and read back', () async {
      final provider = EmployerProvider();
      await provider.hydrate();

      provider.updateCompany(const CompanyProfile(
        name: 'Ravi Constructions',
        email: 'hr@ravi-constructions.com',
        type: 'Construction',
      ));
      provider.postJob(masonJob());
      await provider.flush();

      final reopened = EmployerProvider();
      await reopened.hydrate();

      expect(reopened.company.name, 'Ravi Constructions');
      expect(reopened.jobs, hasLength(1));
      expect(reopened.jobs.first.role, 'Mason');
    });

    test('a vacancy keeps everything field work needs', () async {
      final provider = EmployerProvider();
      await provider.hydrate();

      provider.postJob(EmployerJobModel(
        id: 'job-perks',
        role: 'General Worker',
        title: 'General Worker',
        category: 'Construction',
        companyName: 'Test Builders',
        location: 'Woodlands',
        countryCode: 'SG',
        minSalary: '1600',
        maxSalary: '2200',
        currency: 'SGD',
        payPeriod: 'Per day',
        accommodationProvided: true,
        transportProvided: true,
        permitSponsored: true,
        trainingProvided: true,
        vacancies: 12,
        postedDate: DateTime.now(),
      ));
      await provider.flush();

      final reopened = EmployerProvider();
      await reopened.hydrate();
      final job = reopened.jobs.first;

      // None of this could be expressed at all before: the old model had a
      // title, a category, a location, one salary string and a count.
      expect(job.payPeriod, 'Per day');
      expect(job.salaryDisplay, contains('/ day'));
      expect(job.benefits, containsAll(<String>[
        'Accommodation',
        'Transport',
        'Permit sponsored',
        'Training given',
      ]));
      expect(job.vacancies, 12);
    });

    test('signing out clears the company data', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.updateCompany(const CompanyProfile(name: 'Test', email: 'a@b.com'));
      provider.postJob(masonJob());
      await provider.flush();

      await provider.signOut();

      expect(await EmployerStore.loadJobs(), isEmpty);
      expect(await EmployerStore.loadCompany(), isNull);
    });
  });

  group('the candidate pool covers the work the agency places', () {
    test('every category has candidates', () async {
      final pool = await CandidatePoolService.fetch();

      expect(pool, isNotEmpty);
      for (final category in AppData.workCategories) {
        expect(pool.any((c) => c.category == category.name), isTrue,
            reason: '${category.name} has no candidates');
      }
    });

    test('the pool stays removable', () async {
      final pool = await CandidatePoolService.fetch();

      expect(pool.every((c) => c.isSeed), isTrue);
      expect(pool.every((c) => c.id.startsWith('seed-cand-')), isTrue);
    });

    test('a candidate never claims a licence their trade does not use',
        () async {
      for (final candidate in await CandidatePoolService.fetch()) {
        final valid = AppData.certificatesFor(
            category: candidate.category, role: candidate.role);
        for (final held in candidate.certificates) {
          expect(valid, contains(held),
              reason: '${candidate.role} would not hold $held');
        }
      }
    });

    test('all three tables have rows for a posted job', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.postJob(masonJob());

      for (final source in CandidateSource.values) {
        expect(provider.candidatesFor('job-test', source: source), isNotEmpty,
            reason: '${source.label} table is empty');
      }
    });
  });

  group('matching', () {
    test('the right trade ranks first', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.postJob(masonJob());

      final top = provider.candidatesFor('job-test').first;
      expect(top.category, 'Construction');
      expect(provider.matchFor(top, 'job-test'), greaterThan(60));
    });

    test('a missing required licence caps the score', () {
      final job = masonJob(certificates: const ['Trade Test Certificate']);
      final without = Candidate(
        id: 'c1',
        name: 'Test',
        role: 'Mason',
        category: 'Construction',
        yearsExperience: 8,
        city: 'Chennai',
        countryCode: 'IN',
        phone: '+91 90000 00000',
        email: 'a@b.com',
        skills: const ['Brickwork', 'Plastering'],
        appliedDate: DateTime.now(),
      );

      // Everything else about this candidate is a perfect fit, which is exactly
      // when a hard requirement matters: ranking them at 90% sends a recruiter
      // to a call that cannot go anywhere.
      expect(without.matchFor(job), lessThanOrEqualTo(55));

      final with_ = Candidate(
        id: 'c2',
        name: 'Test',
        role: 'Mason',
        category: 'Construction',
        yearsExperience: 8,
        city: 'Chennai',
        countryCode: 'IN',
        phone: '+91 90000 00000',
        email: 'a@b.com',
        skills: const ['Brickwork', 'Plastering'],
        certificates: const ['Trade Test Certificate'],
        appliedDate: DateTime.now(),
      );
      expect(with_.matchFor(job), greaterThan(90));
    });

    test('the score is explained, not just asserted', () {
      final job = masonJob(certificates: const ['Trade Test Certificate']);
      final candidate = Candidate(
        id: 'c3',
        name: 'Test',
        role: 'Mason',
        category: 'Construction',
        yearsExperience: 5,
        city: 'Chennai',
        countryCode: 'IN',
        phone: '+91 90000 00000',
        email: 'a@b.com',
        skills: const ['Brickwork'],
        languages: const ['Tamil'],
        availability: 'Immediately',
        appliedDate: DateTime.now(),
      );

      final reasons = candidate.matchReasons(job);
      expect(reasons, contains('Works as a Mason'));
      // Spec §26: what is missing has to be said out loud, or a recruiter finds
      // out on the phone.
      expect(reasons.any((r) => r.startsWith('Missing')), isTrue);
    });
  });

  group('contact credits, spec §71-72', () {
    test('an applicant costs nothing to contact', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.postJob(masonJob());

      final applied =
          provider.candidatesFor('job-test', source: CandidateSource.applied);
      expect(applied.first.contactRevealed, isTrue,
          reason: 'they chose to make contact; charging for it is indefensible');
      expect(provider.contactCreditsUsed, 0);
    });

    test('revealing a recommended candidate spends one credit', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.postJob(masonJob());

      verify(provider);
      final recommended = provider
          .candidatesFor('job-test', source: CandidateSource.recommended)
          .first;
      expect(recommended.contactRevealed, isFalse);
      expect(recommended.maskedPhone, contains('•'));

      expect(provider.revealContact(recommended.id), isTrue);
      expect(recommended.contactRevealed, isTrue);
      expect(provider.contactCreditsUsed, 1);

      // Revealing the same person twice must not charge twice.
      expect(provider.revealContact(recommended.id), isTrue);
      expect(provider.contactCreditsUsed, 1);
    });

    test('spent credits survive a restart', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.postJob(masonJob());
      verify(provider);
      final id = provider
          .candidatesFor('job-test', source: CandidateSource.recommended)
          .first
          .id;
      provider.revealContact(id);
      await provider.flush();

      final reopened = EmployerProvider();
      await reopened.hydrate();

      expect(reopened.candidateById(id)!.contactRevealed, isTrue);
      expect(reopened.contactCreditsUsed, 1,
          reason: 'a credit the company already paid must not be refunded, '
              'nor charged again');
    });
  });

  group('verification gates what a company can do', () {
    test('a new company cannot post or reach out', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.updateCompany(
          const CompanyProfile(name: 'Unchecked Ltd', email: 'a@b.com'));

      expect(provider.canPost, isFalse,
          reason: 'anyone with an email could post to candidates before this');

      provider.postJob(masonJob());
      final recommended = provider
          .candidatesFor('job-test', source: CandidateSource.recommended)
          .first;

      expect(provider.revealContact(recommended.id), isFalse,
          reason: "an unchecked business must not get a candidate's number");
      expect(provider.contactCreditsUsed, 0);
    });

    test('submitting stops at awaiting verification', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.updateCompany(const CompanyProfile(
        name: 'Ravi Constructions',
        email: 'hr@ravi.com',
        registrationNumber: '200812345K',
        type: 'Construction',
        contactName: 'Ravi',
        phone: '+65 9000 0000',
      ));

      provider.submitForVerification();

      // The app can move a company to `submitted` and no further. Verifying
      // itself would be the same lie as the old fake auth, and an employer
      // badge nobody checked is worse than no badge at all.
      expect(provider.company.status, CompanyStatus.submitted);
      expect(provider.company.isVerified, isFalse);
      expect(provider.canPost, isFalse);
      expect(provider.company.submittedAt, isNotNull);
      expect(provider.companyId, isNotEmpty);
    });

    test('an unverified company gets a draft, not a lost vacancy', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.updateCompany(
          const CompanyProfile(name: 'Unchecked Ltd', email: 'a@b.com'));

      // What the wizard does on publish when `canPost` is false.
      provider.postJob(masonJob().copyWith(status: JobStatus.draft));
      await provider.flush();

      final reopened = EmployerProvider();
      await reopened.hydrate();

      expect(reopened.jobs, hasLength(1),
          reason: 'four screens of work must not be thrown away at the gate');
      expect(reopened.jobs.first.status, JobStatus.draft);
      expect(reopened.publishedJobs, isEmpty,
          reason: 'a draft must not reach candidates');
    });

    test('a posting carries the company that made it', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      verify(provider);

      final job = masonJob().copyWith(
        companyName: provider.company.name,
        companyVerified: provider.company.isVerified,
      );
      provider.postJob(job);
      await provider.flush();

      final reopened = EmployerProvider();
      await reopened.hydrate();
      final stored = reopened.jobs.first;

      // The bug this covers: a job card named no employer at all, because the
      // field was empty at posting time and rendered nowhere afterwards.
      expect(stored.companyName, 'Test Builders');
      expect(stored.companyVerified, isTrue);
      expect(stored.toJson()['company_name'], 'Test Builders');
    });
  });

  group('pipeline', () {
    test('a stage change and a note survive a restart', () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.postJob(masonJob());
      final candidate = provider.candidatesFor('job-test').first;

      provider.setCandidateStatus(candidate.id, CandidateStages.interview);
      provider.addNote(candidate.id, 'Called 28 Aug, free next week.');
      await provider.flush();

      final reopened = EmployerProvider();
      await reopened.hydrate();

      expect(reopened.candidateById(candidate.id)!.status,
          CandidateStages.interview);
      expect(reopened.notesFor(candidate.id), hasLength(1));
      expect(reopened.interviewsCount, greaterThan(0));
    });

    test('archiving removes a candidate from the tables but not the database',
        () async {
      final provider = EmployerProvider();
      await provider.hydrate();
      provider.postJob(masonJob());
      final candidate = provider.candidatesFor('job-test').first;

      provider.archiveCandidate(candidate.id, 'Not suitable');

      expect(provider.candidatesFor('job-test').map((c) => c.id),
          isNot(contains(candidate.id)));
      expect(provider.archivedFor('job-test').map((c) => c.id),
          contains(candidate.id));
      expect(provider.candidateById(candidate.id), isNotNull,
          reason: 'archiving is scoped to this job, never global');

      provider.restoreCandidate(candidate.id);
      expect(provider.candidatesFor('job-test').map((c) => c.id),
          contains(candidate.id));
    });
  });
}
