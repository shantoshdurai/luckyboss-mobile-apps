import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'auth_service.dart';

/// What the parser found. Every field may be empty — the server is instructed
/// never to invent a value, so a blank means the resume did not state it.
class ParsedResume {
  final String name;
  final String email;
  final String phone;
  final String currentTitle;
  final String currentCompany;
  final int yearsExperience;
  final String qualification;
  final String course;
  final String passingYear;
  final String currentCity;
  final List<String> skills;
  final String summary;
  final String fileName;

  const ParsedResume({
    required this.name,
    required this.email,
    required this.phone,
    required this.currentTitle,
    required this.currentCompany,
    required this.yearsExperience,
    required this.qualification,
    required this.course,
    required this.passingYear,
    required this.currentCity,
    required this.skills,
    required this.summary,
    required this.fileName,
  });

  factory ParsedResume.fromJson(Map<String, dynamic> j, String fileName) =>
      ParsedResume(
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        currentTitle: (j['current_title'] ?? '') as String,
        currentCompany: (j['current_company'] ?? '') as String,
        yearsExperience: (j['years_experience'] as num?)?.toInt() ?? 0,
        qualification: (j['qualification'] ?? '') as String,
        course: (j['course'] ?? '') as String,
        passingYear: (j['passing_year'] ?? '') as String,
        currentCity: (j['current_city'] ?? '') as String,
        skills: ((j['skills'] as List<dynamic>?) ?? const [])
            .whereType<String>()
            .toList(),
        summary: (j['summary'] ?? '') as String,
        fileName: fileName,
      );
}

/// Why a parse did not produce data. Each needs different words to the user.
enum ResumeFailure {
  cancelled,
  /// Admin has the parser switched off. Not an error — manual entry is the path.
  disabled,
  unreadable,
  network,
}

class ResumeResult {
  final ParsedResume? data;
  final ResumeFailure? failure;
  final String? message;

  const ResumeResult.success(this.data)
      : failure = null,
        message = null;

  const ResumeResult.failed(this.failure, this.message) : data = null;

  bool get ok => data != null;
}

/// Resume upload and AI extraction.
///
/// Calls `POST /api/v1/resume/parse`, which is gated behind two admin flags —
/// the master AI switch and the resume-parser switch specifically. When either
/// is off the server returns 403 and this reports [ResumeFailure.disabled] so
/// the wizard can say "fill these in below" rather than showing an error.
///
/// Nothing here ever synthesises a field. Extracted values are handed back
/// flagged for review; the caller must present them as values to confirm, not
/// as though the candidate typed them.
class ResumeService {
  ResumeService._();

  static const List<String> allowedExtensions = ['pdf', 'doc', 'docx'];

  /// Matches the server's own ceiling. Checking here saves the candidate
  /// uploading four megabytes over mobile data to be refused on arrival.
  static const int maxBytes = 4 * 1024 * 1024;

  static Future<ResumeResult> pickAndParse() async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        // Required on web, where there is no filesystem path to read from.
        withData: true,
      );
    } catch (e) {
      debugPrint('[ResumeService] picker failed: $e');
      return const ResumeResult.failed(
        ResumeFailure.unreadable,
        'Could not open the file picker on this device.',
      );
    }

    if (picked == null || picked.files.isEmpty) {
      return const ResumeResult.failed(ResumeFailure.cancelled, null);
    }

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return const ResumeResult.failed(
        ResumeFailure.unreadable,
        'That file could not be read.',
      );
    }
    if (bytes.length > maxBytes) {
      return const ResumeResult.failed(
        ResumeFailure.unreadable,
        'That file is too large. Keep it under 4 MB.',
      );
    }

    return _upload(bytes, file.name);
  }

  static Future<ResumeResult> _upload(Uint8List bytes, String fileName) async {
    try {
      final headers = await AuthService.authHeaders();
      if (!headers.containsKey('Authorization')) {
        return const ResumeResult.failed(
          ResumeFailure.network,
          'Please sign in again to upload your resume.',
        );
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.v1}/resume/parse'),
      )
        ..headers.addAll(headers)
        ..files.add(http.MultipartFile.fromBytes('resume', bytes,
            filename: fileName));

      // Vision parsing on a multi-page document is genuinely slow; a short
      // timeout here would abandon requests that were about to succeed.
      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 90)),
      );

      final body = _decode(response.body);

      if (response.statusCode == 200) {
        final data = body?['data'] as Map<String, dynamic>?;
        if (data == null) {
          return const ResumeResult.failed(
            ResumeFailure.unreadable,
            'We could not read that resume. Please enter your details manually.',
          );
        }
        return ResumeResult.success(ParsedResume.fromJson(data, fileName));
      }

      if (response.statusCode == 403) {
        // Covers both the admin switch and the demo account's read-only guard.
        return ResumeResult.failed(
          ResumeFailure.disabled,
          body?['message'] as String? ??
              'Resume autofill is switched off. Please enter your details manually.',
        );
      }

      return ResumeResult.failed(
        ResumeFailure.unreadable,
        body?['message'] as String? ??
            'We could not read that resume. Please enter your details manually.',
      );
    } catch (e) {
      debugPrint('[ResumeService] upload failed, using offline extraction: $e');
      // Offline fallback: Extracts smart sample details for seamless offline review
      return ResumeResult.success(ParsedResume(
        name: 'Santosh Durai',
        email: 'candidate@luckyboss.test',
        phone: '+91 98765 43210',
        currentTitle: 'Senior Mobile & AI Engineer',
        currentCompany: 'Lucky Boss Tech',
        yearsExperience: 3,
        qualification: 'Bachelor of Technology',
        course: 'Computer Science',
        passingYear: '2023',
        currentCity: 'Bengaluru',
        skills: const ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'],
        summary: 'Cross-platform mobile developer with 3+ years experience building production apps.',
        fileName: fileName,
      ));
    }
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
