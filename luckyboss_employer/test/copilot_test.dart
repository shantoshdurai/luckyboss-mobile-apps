import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'package:luckybossemployer/models/candidate.dart';
import 'package:luckybossemployer/models/employer_job.dart';
import 'package:luckybossemployer/services/employer_copilot_service.dart';

/// The hiring assistant's offline behaviour.
///
/// This exists because the candidate copilot got it wrong in a way nobody
/// noticed for weeks: with the server unreachable it returned hardcoded salary
/// bands marked `isLive: true`, so invented figures arrived looking exactly
/// like a model's answer — directly under a docstring promising "no fabricated
/// fallback". These tests pin the employer side to the opposite rule: every
/// offline number is counted from real rows, and the reply says so.
void main() {
  Candidate candidate({
    required String role,
    String category = 'Warehouse & Logistics',
    String country = 'MY',
    List<String> certificates = const [],
    int years = 4,
    String availability = 'Immediately',
  }) =>
      Candidate(
        id: 'c-$role-$country-$years-${certificates.length}',
        name: 'Test Person',
        role: role,
        category: category,
        yearsExperience: years,
        city: 'Klang',
        countryCode: country,
        phone: '+60 12 000 0000',
        email: 'a@b.com',
        certificates: certificates,
        languages: const ['Malay'],
        availability: availability,
        appliedDate: DateTime.now(),
      );

  EmployerJobModel job({
    String role = 'Forklift Driver',
    String country = 'MY',
    String min = '2,200',
    String max = '2,900',
  }) =>
      EmployerJobModel(
        id: 'j-$role',
        role: role,
        title: role,
        category: 'Warehouse & Logistics',
        companyName: 'Klang Freight',
        location: 'Port Klang',
        countryCode: country,
        minSalary: min,
        maxSalary: max,
        currency: 'MYR',
        postedDate: DateTime.now(),
      );

  group('the assistant answers from real data when offline', () {
    // The offline path is the path under test, so the absence of a server is
    // enforced rather than assumed.
    //
    // These tests used to rely on nothing answering, which was false whenever
    // anyone had `php artisan serve` running: the copilot reached the real
    // endpoint, came back with a model reply, and four tests failed for a
    // reason unrelated to the code they cover.
    setUp(() {
      EmployerCopilotService.clientOverride = MockClient(
        (_) async => throw const SocketException('no server in tests'),
      );
    });

    tearDown(() => EmployerCopilotService.clientOverride = null);

    test('counts a trade in a market, and never invents one', () async {
      final pool = [
        candidate(role: 'Forklift Driver', certificates: const ['Forklift Licence']),
        candidate(role: 'Forklift Driver', years: 1),
        candidate(role: 'Forklift Driver', country: 'SG'),
        candidate(role: 'Picker & Packer'),
      ];

      final reply = await EmployerCopilotService.ask(
        'how many forklift drivers do we have in malaysia',
        pool: pool,
        jobs: [job()],
      );

      expect(reply.source, ReplySource.localData);
      // Two in Malaysia, not the three in the pool and not a round number.
      expect(reply.text, contains('2 forklift drivers'));
      expect(reply.text, contains('Malaysia'));
    });

    test('says so plainly when nobody matches', () async {
      final reply = await EmployerCopilotService.ask(
        'how many masons in chennai',
        pool: [candidate(role: 'Forklift Driver')],
        jobs: const [],
      );

      expect(reply.source, ReplySource.localData);
      // Not a fabricated encouraging number, and not silence either.
      expect(reply.text.toLowerCase(), contains('no'));
      expect(reply.text, contains('Post the vacancy anyway'));
    });

    test('quotes pay from real postings, never a made-up band', () async {
      final reply = await EmployerCopilotService.ask(
        'what do my jobs pay',
        pool: const [],
        jobs: [job(min: '2,200', max: '2,900')],
      );

      expect(reply.source, ReplySource.localData);
      expect(reply.text, contains('MYR 2,200 – 2,900'));
    });

    test('offers nothing rather than a guess with no postings', () async {
      final reply = await EmployerCopilotService.ask(
        'what should I pay',
        pool: const [],
        jobs: const [],
      );

      expect(reply.source, ReplySource.localData);
      // The candidate app would have answered this with invented figures for
      // three countries. This says it has nothing to go on.
      expect(reply.text, contains('once you have posted a vacancy'));
      expect(reply.text, isNot(contains('SGD')));
    });

    test('counts licences actually held', () async {
      final reply = await EmployerCopilotService.ask(
        'which licences do candidates hold',
        pool: [
          candidate(role: 'Forklift Driver', certificates: const ['Forklift Licence']),
          candidate(role: 'Forklift Driver', years: 2, certificates: const ['Forklift Licence']),
          candidate(role: 'Picker & Packer'),
        ],
        jobs: const [],
      );

      expect(reply.source, ReplySource.localData);
      expect(reply.text, contains('Forklift Licence — 2 candidates'));
    });

    test('a reply is never passed off as a model answer', () async {
      final reply = await EmployerCopilotService.ask(
        'anything at all',
        pool: const [],
        jobs: const [],
      );

      expect(reply.source, ReplySource.localData,
          reason: 'the UI labels this "from your data — not AI", and that '
              'label depends on the source being honest');
      expect(reply.text, contains('cannot reach the server'));
    });
  });
}
