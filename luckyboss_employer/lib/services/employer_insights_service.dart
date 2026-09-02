import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'employer_auth_service.dart';

/// A usage figure against whatever the plan allows.
class PlanLimit {
  final int used;

  /// Null when the plan does not mention this limit at all.
  final int? allowed;
  final bool unlimited;

  const PlanLimit({required this.used, this.allowed, this.unlimited = false});

  factory PlanLimit.fromJson(Map<String, dynamic>? j) => PlanLimit(
        used: (j?['used'] ?? 0) as int,
        allowed: j?['allowed'] as int?,
        unlimited: (j?['unlimited'] ?? false) as bool,
      );

  String get label {
    if (unlimited) return '$used of unlimited';
    if (allowed == null) return '$used';
    return '$used of $allowed';
  }

  /// 0..1 for a progress bar, or null when there is no ceiling to draw against.
  double? get fraction {
    if (unlimited || allowed == null || allowed! <= 0) return null;
    return (used / allowed!).clamp(0.0, 1.0);
  }
}

/// The account overview: plan, what it unlocks, and what it has produced.
class EmployerInsights {
  final String companyName;
  final bool verified;
  final String planName;
  final bool planActive;
  final int? daysRemaining;

  final PlanLimit jobPosts;
  final PlanLimit candidateViews;

  final bool aiAvailable;
  final bool aiUpgradeRequired;
  final String? aiReason;

  final int activeJobs;
  final int applications;
  final int views;

  /// Null until the first view is ever recorded. The app says "not measured
  /// yet" rather than showing a confident zero for a period nobody was counting.
  final DateTime? trackingSince;

  final int activeBoosts;
  final int boostSpend;
  final String currency;

  const EmployerInsights({
    required this.companyName,
    required this.verified,
    required this.planName,
    required this.planActive,
    required this.jobPosts,
    required this.candidateViews,
    required this.aiAvailable,
    required this.aiUpgradeRequired,
    required this.activeJobs,
    required this.applications,
    required this.views,
    required this.activeBoosts,
    required this.boostSpend,
    required this.currency,
    this.daysRemaining,
    this.aiReason,
    this.trackingSince,
  });

  factory EmployerInsights.fromJson(Map<String, dynamic> j) {
    final plan = (j['plan'] as Map<String, dynamic>?) ?? const {};
    final limits = (j['limits'] as Map<String, dynamic>?) ?? const {};
    final ai = (j['ai'] as Map<String, dynamic>?) ?? const {};
    final totals = (j['totals'] as Map<String, dynamic>?) ?? const {};
    final boosts = (j['boosts'] as Map<String, dynamic>?) ?? const {};
    final company = (j['company'] as Map<String, dynamic>?) ?? const {};

    return EmployerInsights(
      companyName: (company['name'] ?? '') as String,
      verified: (company['verified'] ?? false) as bool,
      planName: (plan['name'] ?? 'No active plan') as String,
      planActive: (plan['active'] ?? false) as bool,
      daysRemaining: plan['days_remaining'] as int?,
      jobPosts: PlanLimit.fromJson(limits['job_posts'] as Map<String, dynamic>?),
      candidateViews:
          PlanLimit.fromJson(limits['candidate_views'] as Map<String, dynamic>?),
      aiAvailable: (ai['ai_available'] ?? false) as bool,
      aiUpgradeRequired: (ai['upgrade_required'] ?? false) as bool,
      aiReason: ai['reason'] as String?,
      activeJobs: (totals['active_jobs'] ?? 0) as int,
      applications: (totals['applications'] ?? 0) as int,
      views: (totals['views'] ?? 0) as int,
      trackingSince: totals['tracking_since'] == null
          ? null
          : DateTime.tryParse(totals['tracking_since'].toString()),
      activeBoosts: (boosts['active'] ?? 0) as int,
      boostSpend: (boosts['total_spent'] ?? 0) as int,
      currency: (boosts['currency'] ?? 'SGD') as String,
    );
  }
}

/// What one boost did, measured rather than estimated.
class BoostReport {
  final String type;
  final bool active;
  final int daysRemaining;
  final int amount;
  final String currency;
  final int viewsDuring;

  /// Null when the vacancy was not live long enough before the boost for a
  /// like-for-like window to exist.
  final int? viewsBefore;
  final int applicationsDuring;
  final bool comparable;

  const BoostReport({
    required this.type,
    required this.active,
    required this.daysRemaining,
    required this.amount,
    required this.currency,
    required this.viewsDuring,
    required this.applicationsDuring,
    required this.comparable,
    this.viewsBefore,
  });

  factory BoostReport.fromJson(Map<String, dynamic> j) => BoostReport(
        type: (j['type'] ?? '') as String,
        active: (j['active'] ?? false) as bool,
        daysRemaining: (j['days_remaining'] ?? 0) as int,
        amount: (j['amount'] ?? 0) as int,
        currency: (j['currency'] ?? 'SGD') as String,
        viewsDuring: (j['views_during'] ?? 0) as int,
        viewsBefore: j['views_before'] as int?,
        applicationsDuring: (j['applications_during'] ?? 0) as int,
        comparable: (j['comparable'] ?? false) as bool,
      );

  /// The lift the boost produced, as a percentage, or null when there is
  /// nothing honest to compare against.
  int? get liftPercent {
    if (!comparable || viewsBefore == null) return null;
    if (viewsBefore == 0) return viewsDuring > 0 ? null : 0;
    return (((viewsDuring - viewsBefore!) / viewsBefore!) * 100).round();
  }
}

/// One vacancy's numbers.
class JobInsights {
  final String title;
  final int views;
  final int applications;

  /// Null when nobody has looked yet — which is a different fact from nobody
  /// applying, and must not be shown as 0%.
  final double? applyRate;
  final List<int> dailyViews;
  final BoostReport? boost;

  const JobInsights({
    required this.title,
    required this.views,
    required this.applications,
    required this.dailyViews,
    this.applyRate,
    this.boost,
  });

  factory JobInsights.fromJson(Map<String, dynamic> j) {
    final job = (j['job'] as Map<String, dynamic>?) ?? const {};
    final daily = (j['daily'] as List?) ?? const [];

    return JobInsights(
      title: (job['title'] ?? '') as String,
      views: (j['views'] ?? 0) as int,
      applications: (j['applications'] ?? 0) as int,
      applyRate: (j['apply_rate'] as num?)?.toDouble(),
      dailyViews: daily
          .map((d) => ((d as Map<String, dynamic>)['views'] ?? 0) as int)
          .toList(),
      boost: j['boost'] == null
          ? null
          : BoostReport.fromJson(j['boost'] as Map<String, dynamic>),
    );
  }
}

/// Reads the employer's own numbers from Laravel.
///
/// The portal sold a subscription without showing what was in it, and sold a
/// boost without ever reporting what it did. Everything here is measured
/// server-side; where nothing has been measured the value is null and the UI
/// says so, because on a feature somebody paid for an invented number is worse
/// than an empty one.
class EmployerInsightsService {
  EmployerInsightsService._();

  static const Duration _timeout = Duration(seconds: 20);

  static Future<EmployerInsights?> overview() async {
    final body = await _get('${ApiConfig.v1}/employer/insights');
    return body == null ? null : EmployerInsights.fromJson(body);
  }

  static Future<JobInsights?> forJob(int jobId) async {
    final body = await _get('${ApiConfig.v1}/employer/jobs/$jobId/insights');
    return body == null ? null : JobInsights.fromJson(body);
  }

  static Future<Map<String, dynamic>?> _get(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: await EmployerAuthService.authHeaders())
          .timeout(_timeout);

      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[EmployerInsights] $url -> $e');
      return null;
    }
  }
}
