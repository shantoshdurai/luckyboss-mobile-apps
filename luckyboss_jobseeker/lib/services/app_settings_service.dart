import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

/// Which features the admin has switched on.
///
/// The app used to assume everything was available. An admin turning the AI
/// copilot off in the web panel left the button on every phone: the server
/// refused the call correctly, so nothing was insecure, but the candidate saw
/// a feature that simply appeared broken.
///
/// This is a display convenience and nothing more. Hiding a button is not a
/// control — every gated endpoint checks the flag itself server-side, which is
/// what spec §93 requires and what actually protects anything.
class AppFeatures {
  final bool aiAssistant;
  final bool jobMatching;
  final bool resumeAutofill;
  final bool partnerJobs;
  final bool paidApplications;
  final bool calendar;

  const AppFeatures({
    this.aiAssistant = true,
    this.jobMatching = true,
    this.resumeAutofill = true,
    this.partnerJobs = true,
    this.paidApplications = false,
    this.calendar = true,
  });

  /// What to assume before the server has answered.
  ///
  /// Everything on except paid applications. A candidate briefly seeing a
  /// button that turns out to be off is a small annoyance; briefly hiding the
  /// whole app behind flags that have not loaded yet is a broken first launch.
  /// Charging is the one thing that must never appear by accident.
  static const AppFeatures optimistic = AppFeatures();

  factory AppFeatures.fromJson(Map<String, dynamic> j) => AppFeatures(
        aiAssistant: (j['ai_assistant'] ?? true) as bool,
        jobMatching: (j['job_matching'] ?? true) as bool,
        resumeAutofill: (j['resume_autofill'] ?? true) as bool,
        partnerJobs: (j['partner_jobs'] ?? true) as bool,
        paidApplications: (j['paid_applications'] ?? false) as bool,
        calendar: (j['calendar'] ?? true) as bool,
      );

  Map<String, dynamic> toJson() => {
        'ai_assistant': aiAssistant,
        'job_matching': jobMatching,
        'resume_autofill': resumeAutofill,
        'partner_jobs': partnerJobs,
        'paid_applications': paidApplications,
        'calendar': calendar,
      };
}

/// Fetches and caches the feature flags.
class AppSettingsService {
  AppSettingsService._();

  static const String _cacheKey = 'luckyboss_app_features_v1';
  static const Duration _timeout = Duration(seconds: 10);

  static AppFeatures _current = AppFeatures.optimistic;

  /// The flags in force right now. Safe to read on the first frame.
  static AppFeatures get current => _current;

  /// Loads the cached flags, then refreshes from the server.
  ///
  /// The cache is what makes this usable on a slow connection: yesterday's
  /// answer is far closer to the truth than assuming everything is on, and a
  /// standalone build with no server keeps whatever it last knew.
  static Future<AppFeatures> load() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _current = AppFeatures.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_cacheKey);
      }
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.v1}/app-settings'),
        headers: const {'Accept': 'application/json'},
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final features =
            (body['data'] as Map<String, dynamic>?)?['features'];

        if (features is Map<String, dynamic>) {
          _current = AppFeatures.fromJson(features);
          await prefs.setString(_cacheKey, jsonEncode(_current.toJson()));
        }
      }
    } catch (e) {
      // Offline, or no server at all on a standalone build. Whatever was
      // cached stays in force.
      debugPrint('[AppSettings] $e');
    }

    return _current;
  }
}
