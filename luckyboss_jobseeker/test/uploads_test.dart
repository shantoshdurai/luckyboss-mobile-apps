import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckyboss_jobseeker/core/constants/app_data.dart';
import 'package:luckyboss_jobseeker/models/job_model.dart';
import 'package:luckyboss_jobseeker/models/seeker_profile_model.dart';
import 'package:luckyboss_jobseeker/models/uploaded_document.dart';
import 'package:luckyboss_jobseeker/providers/job_seeker_provider.dart';
import 'package:luckyboss_jobseeker/services/document_service.dart';
import 'package:luckyboss_jobseeker/services/gemini_copilot_service.dart';
import 'package:luckyboss_jobseeker/services/job_catalog_service.dart';
import 'package:luckyboss_jobseeker/services/local_store.dart';

/// Covers the second round of Shantosh's review: uploads that were not
/// uploading, licences that ignored the trade, and a feed with nothing in it
/// for a field candidate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    JobCatalogService.resetCache();
  });

  PickedFile file([String name = 'card.jpg']) => PickedFile(
        bytes: Uint8List.fromList(List<int>.generate(64, (i) => i)),
        fileName: name,
        mimeType: DocumentService.mimeFor(name),
      );

  group('documents are really stored', () {
    test('a saved licence keeps its bytes and survives a restart', () async {
      final document = await DocumentService.save(
        file: file('forklift.jpg'),
        kind: DocumentKind.certificate,
        label: 'Forklift Licence',
      );

      expect(document.status, DocumentStatus.pending,
          reason: 'only the server may mark a document verified');
      expect(document.sizeBytes, 64);

      final bytes = await DocumentService.bytesFor(document.id);
      expect(bytes, isNotNull);
      expect(DocumentService.bytesFromDataUri(bytes), hasLength(64));

      final index = await LocalStore.loadDocuments();
      expect(index.map((d) => d.label), contains('Forklift Licence'));
    });

    test('uploading a card also records the claim', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();

      final document = await DocumentService.save(
        file: file(),
        kind: DocumentKind.certificate,
        label: 'Class 4 Licence',
      );
      await provider.addDocument(document);

      expect(provider.profile.certificates, contains('Class 4 Licence'));
      expect(provider.hasProofFor('Class 4 Licence'), isTrue);
      // The distinction the profile renders: a ticked licence is a claim, an
      // uploaded one is evidence, and they must not look the same.
      expect(provider.hasProofFor('Forklift Licence'), isFalse);
    });

    test('removing a licence deletes the file behind it', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();
      final document = await DocumentService.save(
        file: file(),
        kind: DocumentKind.certificate,
        label: 'Security Licence',
      );
      await provider.addDocument(document);

      await provider.removeCertificate('Security Licence');

      expect(provider.profile.certificates, isNot(contains('Security Licence')));
      expect(await DocumentService.bytesFor(document.id), isNull,
          reason: 'orphaned bytes would sit in preferences unreachable forever');
    });

    test('documents survive a restart', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();
      await provider.addDocument(await DocumentService.save(
        file: file('resume.pdf'),
        kind: DocumentKind.resume,
        label: 'Resume',
      ));
      await provider.flush();

      final reopened = JobSeekerProvider();
      await reopened.hydrateFromDevice();

      expect(reopened.documentsOfKind(DocumentKind.resume), hasLength(1));
      expect(reopened.profile.resumeFileName, 'resume.pdf');
    });

    test('signing out removes the files too', () async {
      final provider = JobSeekerProvider();
      await provider.hydrateFromDevice();
      final document = await DocumentService.save(
        file: file(),
        kind: DocumentKind.certificate,
        label: 'First Aid',
      );
      await provider.addDocument(document);
      await provider.flush();

      await provider.signOut();

      expect(await LocalStore.loadDocuments(), isEmpty);
      expect(await DocumentService.bytesFor(document.id), isNull);
    });

    test('a data URI round-trips', () {
      final bytes = Uint8List.fromList([1, 2, 3, 250]);
      final uri = DocumentService.dataUri(bytes, 'image/png');

      expect(uri.startsWith('data:image/png;base64,'), isTrue);
      expect(DocumentService.bytesFromDataUri(uri), bytes);
      expect(DocumentService.bytesFromDataUri('https://example.com/a.png'), isNull);
      expect(base64Decode(uri.split(',').last), bytes);
    });

    test('mime types follow the extension', () {
      expect(DocumentService.mimeFor('licence.pdf'), 'application/pdf');
      expect(DocumentService.mimeFor('card.PNG'), 'image/png');
      expect(DocumentService.mimeFor('photo.jpeg'), 'image/jpeg');
    });
  });

  group('licences follow the trade, not the category', () {
    test('a plumber is not offered a crane licence', () {
      final plumber = AppData.certificatesFor(
          category: 'Construction', role: 'Plumber');

      expect(plumber, contains('Plumbing Licence'));
      expect(plumber, isNot(contains('Crane Operator Licence')),
          reason: 'the picker showed every trade the same five cards');
      expect(plumber, isNot(contains('Scaffolding Certificate')));
    });

    test('a forklift driver is offered the ticket that is their job', () {
      expect(
        AppData.certificatesFor(
            category: 'Warehouse & Logistics', role: 'Forklift Driver'),
        contains('Forklift Licence'),
      );
    });

    test('abilities lead with the role and then widen', () {
      final abilities =
          AppData.abilitiesFor(category: 'Construction', role: 'Plumber');

      expect(abilities.first, 'Pipe Fitting');
      // The rest of the category still follows: a plumber who also lays tiles
      // has to be able to say so.
      expect(abilities, contains('Tiling'));
    });

    test('office roles honestly offer no licence', () {
      expect(
        AppData.certificatesFor(
            category: 'Office & Administration', role: 'Data Entry Clerk'),
        isEmpty,
        reason: 'inventing a licence is worse than offering none',
      );
    });
  });

  group('a field candidate gets recommendations', () {
    test('a mason with no ticked skills is still matched', () async {
      final provider = JobSeekerProvider();
      await provider.loadJobs(force: true);
      await provider.hydrateFromDevice();
      provider.setCountry('IN');
      provider.applyOnboarding(
        category: 'Construction',
        roleTitle: 'Mason',
        isStudent: false,
        currentCity: 'Chennai',
      );

      // The old scorer returned 0 for an empty skills list and the home screen
      // said "add a few skills and recommendations start appearing". He had
      // nothing to add — the trade path never fills that field first.
      expect(provider.recommendedJobs, isNotEmpty);
      expect(provider.recommendedJobs.first.category, 'Construction');
      expect(provider.recommendedJobs.every((j) => j.countryCode == 'IN'), isTrue,
          reason: 'recommending work in another country is not a recommendation');
    });

    test('the partner feed is ordered by match, not by luck', () async {
      final provider = JobSeekerProvider();
      await provider.loadJobs(force: true);
      provider.setCountry('SG');
      provider.applyOnboarding(
        category: 'Construction',
        roleTitle: 'Welder',
        isStudent: false,
        currentCity: 'Woodlands',
      );

      final partner = provider.externalJobs;
      if (partner.length >= 2) {
        final first = provider.matchScoreFor(partner.first) ?? 0;
        final last = provider.matchScoreFor(partner.last) ?? 0;
        expect(first >= last, isTrue,
            reason: 'a construction candidate was shown a Backend Engineer '
                'at the top of the partner feed');
      }
    });

    test('a missing required licence caps the match', () {
      final provider = JobSeekerProvider();
      final job = _forkliftJob();

      provider.applyOnboarding(
        category: 'Warehouse & Logistics',
        roleTitle: 'Forklift Driver',
        isStudent: false,
        currentCity: 'Chennai',
      );
      provider.setSkills(const ['Forklift Operating', 'Pallet Jack']);

      final without = provider.matchScoreFor(job)!;
      expect(without, lessThanOrEqualTo(55),
          reason: 'no ticket means the job is closed, not a 90% match');
    });
  });

  group('the copilot never invents figures', () {
    test('an offline answer comes from the real catalogue', () async {
      // Taken from the catalogue rather than hardcoded: it samples four roles
      // per category per market, so naming a trade here would make the test
      // fail whenever the samples were regenerated without that one.
      final jobs = await JobCatalogService.loadSeed();
      final role = jobs.first.role;

      // No server in a test, so this takes the offline path — the one that used
      // to return hardcoded salary bands marked as live.
      final result = await GeminiCopilotService.ask('$role jobs');

      expect(result.isLive, isFalse,
          reason: 'a catalogue answer must not be dressed up as a model reply');
      expect(result.reply, contains('from the vacancies already on your phone'));

      // Every figure quoted has to exist in the bundled catalogue.
      final realPay =
          jobs.where((j) => j.role == role).map((j) => j.minSalary).toSet();
      expect(realPay.any(result.reply.contains), isTrue,
          reason: 'a quoted salary must come from a real vacancy');
    });

    test('it says nothing rather than guessing a salary band', () async {
      final result =
          await GeminiCopilotService.ask('what salary should I expect');

      expect(result.isLive, isFalse);
      // The old fallback answered this with invented bands for three countries.
      for (final invented in ['3,500', '8 LPA', 'RM 4,500']) {
        expect(result.reply, isNot(contains(invented)),
            reason: 'this figure was fabricated by the previous fallback');
      }
    });
  });

  group('profile strength counts uploads', () {
    test('a field profile still reaches 100 with licences on file', () {
      final driver = SeekerProfileModel(
        name: 'Test Candidate',
        phone: '+919944995493',
        preferredCategories: const ['Driving & Delivery'],
        roleTitle: 'Lorry Driver',
        skills: const ['Heavy Vehicle', 'Route Planning', 'Night Driving'],
        certificates: const ['Class 4 Licence'],
        languages: const ['Tamil'],
        workPermitStatuses: const ['Citizen'],
        availability: 'Immediately',
        photoUrl: 'data:image/jpeg;base64,AAAA',
        // Worth 7% on the field table: an employer hiring a lorry driver asks
        // where he is based before almost anything else.
        currentCity: 'Chennai',
      );

      expect(driver.profileStrengthPercent, 100);
    });
  });
}

/// A vacancy that hard-requires a licence, built here rather than plucked from
/// the catalogue so the expectation cannot drift when the samples are
/// regenerated.
JobModel _forkliftJob() => JobModel(
      id: 'test-forklift',
      title: 'Forklift Driver',
      companyName: 'Test Logistics',
      countryCode: 'IN',
      location: 'Chennai, India',
      workMode: 'On-site',
      minSalary: '18,000',
      maxSalary: '24,000',
      currency: 'INR',
      category: 'Warehouse & Logistics',
      description: 'Forklift Licence required.',
      requiredSkills: const ['Forklift Operating', 'Pallet Jack'],
      requiredCertificates: const ['Forklift Licence'],
      role: 'Forklift Driver',
      postedDate: DateTime.now(),
    );
