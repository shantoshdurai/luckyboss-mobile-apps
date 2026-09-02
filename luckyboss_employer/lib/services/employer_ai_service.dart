import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'employer_auth_service.dart';

/// What this employer's subscription unlocks.
///
/// The portal asks the server rather than deciding locally, and it is never the
/// authority: every endpoint re-checks the plan. This exists so the UI can show
/// a locked card with an upgrade prompt instead of a button that always
/// refuses.
class EmployerAiStatus {
  final bool available;
  final bool upgradeRequired;
  final bool platformWide;

  /// 'platform' when the plan includes our AI, 'byoai' when the employer
  /// supplied their own key, null when neither.
  final String? source;

  /// Why AI is unavailable, in words fit to show a hiring manager.
  final String? reason;

  const EmployerAiStatus({
    required this.available,
    required this.upgradeRequired,
    required this.platformWide,
    this.source,
    this.reason,
  });

  /// The safe assumption when the server cannot be reached: no AI, and nothing
  /// to upsell, because we do not know what the plan says.
  const EmployerAiStatus.unknown()
      : available = false,
        upgradeRequired = false,
        platformWide = false,
        source = null,
        reason = null;

  factory EmployerAiStatus.fromJson(Map<String, dynamic> j) => EmployerAiStatus(
        available: (j['ai_available'] ?? false) as bool,
        upgradeRequired: (j['upgrade_required'] ?? false) as bool,
        platformWide: (j['ai_enabled_platform_wide'] ?? false) as bool,
        source: j['source'] as String?,
        reason: j['reason'] as String?,
      );
}

/// A drafted vacancy, or the ranked shortlist for one.
class AiResult {
  /// True when this came from the AI model rather than the rule-based engine.
  final bool fromAi;
  final bool upgradeRequired;
  final String? message;
  final Map<String, dynamic> data;

  const AiResult({
    required this.fromAi,
    required this.upgradeRequired,
    required this.data,
    this.message,
  });
}

/// Failure carrying a message fit to show a user.
class AiFailure implements Exception {
  final String message;
  const AiFailure(this.message);
  @override
  String toString() => message;
}

/// The AI tools the employer subscription is sold on.
///
/// Every call here is re-checked server-side against the company's package, so
/// a denied request still returns something usable — a template draft or a
/// heuristic ranking — with `fromAi` false and `upgradeRequired` true. The app
/// shows that difference honestly rather than passing a template off as AI.
class EmployerAiService {
  EmployerAiService._();

  static const Duration _timeout = Duration(seconds: 45);

  static Future<Map<String, String>> _headers() async => {
        ...await EmployerAuthService.authHeaders(),
        'Content-Type': 'application/json',
      };

  /// What the plan unlocks. Never throws — the UI falls back to locked.
  static Future<EmployerAiStatus> status() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.v1}/employer/ai/status'),
              headers: await _headers())
          .timeout(_timeout);

      if (res.statusCode != 200) return const EmployerAiStatus.unknown();

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return EmployerAiStatus.fromJson(
          (body['data'] as Map<String, dynamic>?) ?? const {});
    } catch (e) {
      debugPrint('[EmployerAi] status: $e');
      return const EmployerAiStatus.unknown();
    }
  }

  /// Drafts a vacancy from a job title. The reason posting a job stops being a
  /// blank page.
  static Future<AiResult> draftJobDescription({
    required String title,
    String? category,
    String? location,
  }) {
    return _post('${ApiConfig.v1}/employer/ai/job-description', {
      'title': title.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (location != null && location.isNotEmpty) 'location': location,
    });
  }

  /// Interview questions for one applicant on one vacancy.
  static Future<AiResult> interviewQuestions({
    required int jobId,
    required int applicationId,
  }) {
    return _post('${ApiConfig.v1}/employer/ai/interview-questions', {
      'job_id': jobId,
      'application_id': applicationId,
    });
  }

  /// Applicants on one vacancy, ranked best first.
  static Future<AiResult> shortlist({required int jobId}) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.v1}/employer/jobs/$jobId/ai-shortlist'),
              headers: await _headers())
          .timeout(_timeout);

      return _read(res);
    } catch (e) {
      debugPrint('[EmployerAi] shortlist: $e');
      throw const AiFailure(
          'Could not reach the Luckyboss server. Check your connection.');
    }
  }

  static Future<AiResult> _post(String url, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse(url),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(_timeout);

      return _read(res);
    } catch (e) {
      if (e is AiFailure) rethrow;
      debugPrint('[EmployerAi] $url: $e');
      throw const AiFailure(
          'Could not reach the Luckyboss server. Check your connection.');
    }
  }

  static AiResult _read(http.Response res) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (res.statusCode == 401) {
      throw const AiFailure('Please sign in again.');
    }
    if (res.statusCode != 200) {
      throw AiFailure(
          (body?['message'] as String?) ?? 'That request could not be completed.');
    }

    final raw = body?['data'];
    return AiResult(
      fromAi: (body?['ai'] ?? false) as bool,
      upgradeRequired: (body?['upgrade_required'] ?? false) as bool,
      message: body?['message'] as String?,
      data: raw is Map<String, dynamic> ? raw : {'items': raw},
    );
  }
}
