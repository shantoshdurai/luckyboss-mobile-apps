import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/seeker_profile_model.dart';
import 'auth_service.dart';

/// Reads and writes the candidate profile on the server.
///
/// Before this, everything the onboarding wizard collected lived in a provider
/// and died with the process — which is why the app asked returning candidates
/// for details they had already given. [fetch] on launch and [push] on every
/// edit is what closes that.
class ProfileSyncService {
  ProfileSyncService._();

  static const Duration _timeout = Duration(seconds: 15);

  /// GET the stored profile. Null when signed out or unreachable — callers
  /// treat that as "nothing to merge" rather than as an error to surface.
  static Future<Map<String, dynamic>?> fetch() async {
    try {
      final headers = await AuthService.authHeaders();
      if (!headers.containsKey('Authorization')) return null;

      final res = await http
          .get(Uri.parse('${ApiConfig.v1}/job-seeker/profile'), headers: headers)
          .timeout(_timeout);

      if (res.statusCode != 200) return null;
      return (jsonDecode(res.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[ProfileSync] fetch failed: $e');
      return null;
    }
  }

  /// Whether the server already holds a usable profile for this candidate.
  ///
  /// THE BUG THIS FIXES. `AuthService.logout()` clears the on-device
  /// `profile_complete` flag — correctly, because a different person signing in
  /// on the same handset must not inherit the previous one's state. But the
  /// sign-in screens then read that same wiped flag to decide where to land,
  /// so **every returning candidate was sent back through onboarding** and
  /// asked for their name again, even though the server had their full profile
  /// the whole time. It looked like the account had not been saved.
  ///
  /// Asking the server is the only honest answer to "have they done this
  /// already?", because the server is the system of record.
  ///
  /// Falls back to the device flag when nothing answers: on a standalone build
  /// there is no server to ask, and sending an offline candidate through
  /// onboarding they already finished is the very complaint this fixes.
  static Future<bool> isCompleteOnServer() async {
    if (await AuthService.isLocalAccount()) {
      return AuthService.isProfileComplete();
    }

    final remote = await fetch();
    if (remote == null) return AuthService.isProfileComplete();

    // Same rule the provider uses after hydrating (`skills.isNotEmpty`), so the
    // two cannot disagree about what "complete" means and bounce the candidate
    // between the wizard and the dashboard.
    final skills = remote['skills'];
    final complete = skills is List && skills.isNotEmpty;

    // Cached so the next launch does not need a round trip before routing.
    if (complete) await AuthService.markProfileComplete();

    return complete;
  }

  /// PUT the whole profile.
  ///
  /// Sends every field rather than a delta: the server treats missing keys as
  /// "leave alone", so a partial payload from one editor would be
  /// indistinguishable from a field the candidate had cleared.
  static Future<bool> push(SeekerProfileModel p) async {
    try {
      final headers = await AuthService.authHeaders();
      if (!headers.containsKey('Authorization')) return false;

      final res = await http
          .put(
            Uri.parse('${ApiConfig.v1}/job-seeker/profile'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': p.name,
              'phone': p.phone,
              'headline': p.headline,
              'professional_summary': p.bio,
              'department': p.department,
              'preferred_category': p.preferredCategory,
              'current_title': p.currentTitle,
              'current_location': p.currentCity,
              'preferred_location': p.preferredCountry,
              'expected_salary': p.expectedSalary,
              'availability': p.availability,
              'notice_period': p.noticePeriod,
              'qualification': p.qualification,
              'course': p.course,
              'passing_year': p.passingYear,
              'resume_file_name': p.resumeFileName,
              'is_student': p.isStudent,
              'open_to_relocate': p.openToRelocate,
              'has_work_permit': p.hasWorkPermit,
              'skills': p.skills,
              'projects': p.projects,
              'languages': p.languages,
              'work_modes': p.workModes,
              'job_types': p.jobTypes,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) return true;

      // 403 is the demo account's read-only guard, which is expected rather
      // than broken.
      if (res.statusCode != 403) {
        debugPrint('[ProfileSync] push HTTP ${res.statusCode}: ${res.body}');
      }
      return false;
    } catch (e) {
      debugPrint('[ProfileSync] push failed: $e');
      return false;
    }
  }

  /// Merges a server payload into the in-memory profile.
  ///
  /// Server values are authoritative for anything the local profile has not
  /// set. Local values win where both exist, so an edit made offline is not
  /// clobbered by a stale fetch.
  static void applyTo(SeekerProfileModel p, Map<String, dynamic> d) {
    // JSON is not all strings, and casting as though it were crashed the app.
    //
    // `expected_salary` is a decimal column and `passing_year` an integer, so
    // both arrive as JSON *numbers*. The old `d[k] as String?` threw
    // "type 'int' is not a subtype of type 'String?'" inside hydrateProfile,
    // which runs on the splash screen — the exception killed _checkNavigation
    // before it reached any Navigator call, so the app sat on the loading
    // screen forever. A returning candidate simply could not get in.
    String str(String k) {
      final v = d[k];
      if (v == null) return '';
      if (v is String) return v.trim();
      if (v is num) {
        // 50000.0 should read as "50000" in a salary field, not "50000.0".
        return v == v.roundToDouble() && v.abs() < 1e15
            ? v.toInt().toString()
            : v.toString();
      }
      if (v is bool) return v.toString();
      return '';
    }

    // Tolerant for the same reason. A list of skill objects rather than plain
    // strings used to come back empty from whereType<String>(), which made a
    // complete profile look empty and sent the candidate back through the
    // onboarding wizard.
    List<String> list(String k) {
      final raw = d[k];
      if (raw is! List) return const [];
      return raw
          .map((e) {
            if (e is String) return e.trim();
            if (e is num || e is bool) return e.toString();
            if (e is Map) return (e['name'] ?? e['title'] ?? '').toString().trim();
            return '';
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (p.name.isEmpty) p.name = str('name');
    if (p.email.isEmpty) p.email = str('email');
    if (p.phone.isEmpty) p.phone = str('phone');
    if (p.headline.isEmpty) p.headline = str('headline');
    if (p.bio.isEmpty) p.bio = str('professional_summary');
    if (p.department.isEmpty) p.department = str('department');
    if (p.preferredCategory.isEmpty) {
      p.preferredCategory = str('preferred_category');
    }
    if (p.currentTitle.isEmpty) p.currentTitle = str('current_title');
    if (p.currentCity.isEmpty) p.currentCity = str('current_location');
    if (p.preferredCountries.isEmpty) {
      // The server still sends one market. Wrapping it keeps the client's
      // multi-market answer intact when there is one, and accepts the single
      // value when there is not.
      final remote = str('preferred_location');
      if (remote.isNotEmpty) p.preferredCountries = [remote];
    }
    if (p.expectedSalary.isEmpty) p.expectedSalary = str('expected_salary');
    if (p.availability.isEmpty) p.availability = str('availability');
    if (p.noticePeriod.isEmpty) p.noticePeriod = str('notice_period');
    if (p.course.isEmpty) p.course = str('course');
    if (p.passingYear.isEmpty) p.passingYear = str('passing_year');

    p.qualification ??= str('qualification').isEmpty ? null : str('qualification');
    p.resumeFileName ??=
        str('resume_file_name').isEmpty ? null : str('resume_file_name');

    if (p.skills.isEmpty) p.skills = list('skills');
    if (p.projects.isEmpty) p.projects = list('projects');
    if (p.languages.isEmpty) p.languages = list('languages');
    if (p.workModes.isEmpty) p.workModes = list('work_modes');
    if (p.jobTypes.isEmpty) p.jobTypes = list('job_types');

    p.isStudent = (d['is_student'] as bool?) ?? p.isStudent;
    p.openToRelocate ??= d['open_to_relocate'] as bool?;
    p.hasWorkPermit ??= d['has_work_permit'] as bool?;

    final photo = str('photo_url');
    if ((p.photoUrl ?? '').isEmpty && photo.isNotEmpty) {
      p.photoUrl = ApiConfig.storageUrl(photo);
    }
  }
}
