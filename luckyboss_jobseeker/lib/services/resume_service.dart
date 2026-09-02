import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'auth_service.dart';
import 'document_service.dart';

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

  /// The file name held on the server when the document was saved but not
  /// parsed. The wizard shows this so the candidate can see their CV is
  /// attached while they type the rest in.
  final String? savedFileName;

  const ResumeResult.success(this.data)
      : failure = null,
        message = null,
        savedFileName = null;

  const ResumeResult.failed(this.failure, this.message)
      : data = null,
        savedFileName = null;

  /// Uploaded and kept, but not parsed — autofill is off, unavailable, or the
  /// document could not be read. Not a failure: the candidate has lost nothing
  /// and simply fills the fields in themselves.
  const ResumeResult.savedOnly(this.savedFileName, this.message,
      {bool stored = true})
      : data = null,
        failure = stored ? null : ResumeFailure.unreadable;

  bool get ok => data != null;

  /// True when the document is on the server even though nothing was extracted.
  bool get savedWithoutParsing => data == null && savedFileName != null;
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

  /// Parses a resume, picking one first when the caller has not already.
  ///
  /// [alreadyPicked] lets a caller that has just stored the document hand the
  /// same bytes straight through, rather than making the candidate choose the
  /// file twice. That is the profile screen's path now: the resume is kept
  /// first, and parsing is an optional extra on top of it.
  static Future<ResumeResult> pickAndParse({PickedFile? alreadyPicked}) async {
    if (alreadyPicked != null) {
      return _upload(alreadyPicked.bytes, alreadyPicked.fileName);
    }

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
      final status = body?['status'] as String?;
      final message = body?['message'] as String?;

      // The server keeps the document in every outcome, so a "we could not
      // read it" answer still carries the saved file. Reading `status` rather
      // than the HTTP code is what makes that possible: autofill being switched
      // off is no longer an error, it is a successful upload without parsing.
      final saved = body?['resume'] as Map<String, dynamic>?;
      final savedName = saved?['file_name'] as String? ?? fileName;
      final wasStored = (saved?['stored'] ?? false) == true;

      if (response.statusCode == 200) {
        if (status == 'success') {
          final data = body?['data'] as Map<String, dynamic>?;
          if (data != null) {
            return ResumeResult.success(ParsedResume.fromJson(data, savedName));
          }
        }

        // disabled | unavailable | unreadable — the resume is on file, the
        // candidate just has to type the details in.
        return ResumeResult.savedOnly(
          savedName,
          message ??
              'Your resume has been saved. Please enter your details below.',
          stored: wasStored,
        );
      }

      if (response.statusCode == 401) {
        return const ResumeResult.failed(
          ResumeFailure.network,
          'Please sign in again to upload your resume.',
        );
      }

      if (response.statusCode == 422) {
        return ResumeResult.failed(
          ResumeFailure.unreadable,
          message ?? 'Upload a PDF or Word document under 4 MB.',
        );
      }

      return ResumeResult.failed(
        ResumeFailure.unreadable,
        message ??
            'We could not upload that resume. Please enter your details manually.',
      );
    } catch (e) {
      debugPrint('[ResumeService] upload failed: $e');

      // Deliberately NOT a fabricated profile.
      //
      // This branch used to return a complete invented candidate — "Santosh
      // Durai", a Bengaluru address, three years at "Luckyboss Tech", a Flutter
      // skill set — as though it had been read off the document. Whatever the
      // real person uploaded, a fictional work history went onto their profile
      // and from there to employers. The class docstring three lines up already
      // promised this never happens; now it is true.
      return const ResumeResult.failed(
        ResumeFailure.network,
        'We could not reach the server to upload your resume. Check your '
        'connection and try again, or enter your details below.',
      );
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
