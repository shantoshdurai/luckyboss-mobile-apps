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
    String str(String k) => (d[k] as String?)?.trim() ?? '';
    List<String> list(String k) =>
        ((d[k] as List<dynamic>?) ?? const []).whereType<String>().toList();

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
    if (p.preferredCountry.isEmpty) {
      p.preferredCountry = str('preferred_location');
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
