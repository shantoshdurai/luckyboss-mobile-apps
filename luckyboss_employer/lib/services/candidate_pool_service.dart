import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/config/api_config.dart';
import '../core/theme/app_theme.dart' show CandidateSource;
import '../models/candidate.dart';
import 'employer_auth_service.dart';

/// The Lucky Boss candidate database, as this handset sees it.
///
/// Loads `assets/data/seed_candidates.json` — 252 sample candidates across all
/// fourteen categories in three markets. The employer app previously shipped
/// three hardcoded candidates, all software engineers, so an agency placing
/// masons and domestic helpers opened its own ATS and found nobody it could
/// place.
///
/// Same disposal contract as the seeker app's job catalogue: every row carries
/// `seed: true` and an id prefixed `seed-cand-`, and the JSON columns are the
/// MySQL `candidates` columns, so the set imports server-side unchanged and
/// later clears with `DELETE FROM candidates WHERE seed = 1`. When the API
/// exists, it goes in [fetch] and real applicants displace the samples.
class CandidatePoolService {
  CandidatePoolService._();

  static const String _assetPath = 'assets/data/seed_candidates.json';

  static List<Candidate>? _cache;

  /// The pool. Never throws — this runs on the startup path, and a malformed
  /// asset must leave the ATS empty rather than refuse to open.
  static Future<List<Candidate>> fetch() async {
    final cached = _cache;
    if (cached != null) return cached;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rows = (decoded['candidates'] as List<dynamic>?) ?? const [];

      final out = <Candidate>[];
      for (final row in rows) {
        try {
          out.add(Candidate.fromJson(row as Map<String, dynamic>));
        } catch (e) {
          // One bad row must not cost the recruiter the other 251.
          debugPrint('[CandidatePoolService] skipped a row: $e');
        }
      }
      _cache = out;
      return out;
    } catch (e) {
      debugPrint('[CandidatePoolService] pool unreadable: $e');
      _cache = const [];
      return const [];
    }
  }

  /// Real applicants from Laravel, which displace the bundled samples.
  ///
  /// This is the "when it exists, it goes in fetch()" the docstring above has
  /// been promising. Until now the employer portal showed seed records to
  /// everybody: a recruiter scrolling their pipeline was reading sample data,
  /// not the people who had actually applied to them.
  ///
  /// Falls back to the samples when nothing answers, because the standalone
  /// build has to open with something — but a real applicant list, even an
  /// empty one, always wins over samples. An employer with no applicants needs
  /// to see that they have none.
  static Future<List<Candidate>> fetchFromServer() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.v1}/employer/candidates'),
              headers: await EmployerAuthService.authHeaders())
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) return fetch();

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rows = (body['candidates'] as List<dynamic>?) ?? const [];

      final out = <Candidate>[];
      for (final row in rows) {
        try {
          out.add(_fromApi(row as Map<String, dynamic>));
        } catch (e) {
          debugPrint('[CandidatePoolService] skipped an applicant: $e');
        }
      }

      _cache = out;
      return out;
    } catch (e) {
      debugPrint('[CandidatePoolService] server unreachable: $e');
      return fetch();
    }
  }

  /// Maps one server applicant.
  ///
  /// The server sends null for anything the candidate did not fill in, and that
  /// is carried through as an empty string rather than replaced with something
  /// plausible. An incomplete profile is a fact the recruiter needs — it is the
  /// difference between a candidate worth calling and one worth chasing for
  /// details first.
  static Candidate _fromApi(Map<String, dynamic> j) {
    final skills = (j['skills'] as List<dynamic>?)?.cast<String>() ?? const [];
    final languages =
        (j['languages'] as List<dynamic>?)?.cast<String>() ?? const [];

    return Candidate(
      id: (j['id'] ?? 'cand-${j['application_id']}').toString(),
      applicationId: j['application_id'] as int?,
      name: (j['candidate_name'] ?? '') as String,
      role: (j['current_title'] ?? j['headline'] ?? '') as String,
      category: (j['job_title'] ?? '') as String,
      yearsExperience: (j['years_experience'] as int?) ?? 0,
      city: (j['location'] ?? '') as String,
      countryCode: (j['country_code'] ?? 'SG') as String,
      phone: (j['candidate_phone'] ?? '') as String,
      email: (j['candidate_email'] ?? '') as String,
      skills: skills,
      languages: languages,
      availability: (j['availability'] ?? '') as String,
      appliedDate:
          DateTime.tryParse((j['applied_at'] ?? '').toString()) ?? DateTime.now(),
      isSeed: false,
      status: (j['status'] ?? 'Applied') as String,
      contactRevealed: (j['contact_revealed'] ?? false) as bool,
      source: CandidateSource.applied,
    );
  }

  @visibleForTesting
  static void resetCache() => _cache = null;
}
