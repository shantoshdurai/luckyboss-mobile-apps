import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/candidate.dart';

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

  @visibleForTesting
  static void resetCache() => _cache = null;
}
