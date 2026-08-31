import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/job_model.dart';
import 'api_service.dart';

/// Where the app's vacancies come from.
///
/// One method, two sources, in a deliberate order:
///
/// 1. **The server**, when one answers. That is the real product.
/// 2. **`assets/data/seed_jobs.json`**, always. 168 sample vacancies covering
///    every category in all three markets.
///
/// The bundled catalogue is not a placeholder to be deleted in a hurry. The
/// agreed end product is a standalone APK, and a job board with an empty feed
/// is not a demonstration of anything — Shantosh opened the app as a
/// construction candidate and found two software vacancies, which is a more
/// convincing argument that the app is not for him than any wording could be.
///
/// It is also written to be thrown away cleanly. Every row carries `seed: true`
/// and an id prefixed `seed-`, and the JSON columns are the MySQL `jobs`
/// columns, so the whole set can be imported server-side and later removed with
/// one statement:
///
/// ```sql
/// DELETE FROM jobs WHERE seed = 1;
/// ```
///
/// When that day comes, nothing in the app changes: [fetch] already prefers the
/// server, and real postings simply displace the samples.
class JobCatalogService {
  JobCatalogService._();

  static const String _assetPath = 'assets/data/seed_jobs.json';

  /// Parsed once. The asset is ~200KB of JSON and the feed rebuilds on every
  /// filter change, so re-reading it per call would be a visible stutter.
  static List<JobModel>? _seedCache;

  /// Live vacancies where a server answers, plus the bundled samples.
  ///
  /// Server rows win on id collision — once a real posting exists it replaces
  /// any sample sharing its identifier rather than appearing twice.
  static Future<List<JobModel>> fetch({String? country}) async {
    final seeds = await loadSeed();

    List<JobModel>? live;
    try {
      live = await ApiService.fetchLiveJobs(country: country);
    } catch (e) {
      debugPrint('[JobCatalogService] live fetch failed: $e');
    }

    if (live == null || live.isEmpty) return seeds;

    final byId = {for (final job in seeds) job.id: job};
    for (final job in live) {
      byId[job.id] = job;
    }
    return byId.values.toList();
  }

  /// The bundled catalogue on its own.
  ///
  /// Never throws. This runs on the startup path, and a malformed asset must
  /// leave the app with an empty feed rather than a crash on a candidate's
  /// first launch.
  static Future<List<JobModel>> loadSeed() async {
    final cached = _seedCache;
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      String raw;
      try {
        raw = await rootBundle.loadString(_assetPath);
      } catch (_) {
        raw = await rootBundle.loadString('assets/assets/data/seed_jobs.json');
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rows = (decoded['jobs'] as List<dynamic>?) ?? const [];
      final jobs = <JobModel>[];
      for (final row in rows) {
        try {
          jobs.add(JobModel.fromCatalogJson(row as Map<String, dynamic>));
        } catch (e) {
          debugPrint('[JobCatalogService] skipped a row: $e');
        }
      }
      _seedCache = jobs;
      return jobs;
    } catch (e) {
      debugPrint('[JobCatalogService] catalogue unreadable: $e');
      _seedCache = const [];
      return const [];
    }
  }

  @visibleForTesting
  static void resetCache() => _seedCache = null;
}
