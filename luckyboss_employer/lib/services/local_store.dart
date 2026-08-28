import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/employer_models.dart';
import '../models/job_boost.dart';
import '../models/uploaded_document.dart';

/// Everything the company owns, kept on this handset.
///
/// The same arrangement as the job seeker app, and for the same reason: the
/// agreed deliverable is a standalone APK, so a hiring manager must be able to
/// install it, post a vacancy and still have that vacancy after closing the
/// app. The employer provider held its jobs, its candidates and its plan
/// counters in memory and nowhere else, which meant a posted job survived
/// exactly as long as the process did.
///
/// Rules worth keeping:
///
/// * **One key per concern.** A corrupt candidate list must not be able to take
///   the company's posted jobs down with it.
/// * **Never throw.** This sits on the startup path; a bad read degrades to an
///   empty section rather than a crash on first launch.
class EmployerStore {
  EmployerStore._();

  static const String _companyKey = 'luckyboss_company_v1';
  static const String _jobsKey = 'luckyboss_employer_jobs_v1';
  static const String _candidateStateKey = 'luckyboss_candidate_state_v1';
  static const String _notesKey = 'luckyboss_employer_notes_v1';
  static const String _documentIndexKey = 'luckyboss_employer_documents_v1';
  static const String _chargesKey = 'luckyboss_employer_charges_v1';
  static const String _documentBytesPrefix = 'luckyboss_employer_doc_';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ------------------------------------------------------------------ company

  static Future<void> saveCompany(CompanyProfile company) =>
      _write(_companyKey, jsonEncode(company.toJson()));

  static Future<CompanyProfile?> loadCompany() async {
    final raw = await _read(_companyKey);
    if (raw == null) return null;
    try {
      return CompanyProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[EmployerStore] company unreadable, discarding: $e');
      await clearKey(_companyKey);
      return null;
    }
  }

  // --------------------------------------------------------------------- jobs

  static Future<void> saveJobs(List<EmployerJobModel> jobs) => _write(
        _jobsKey,
        jsonEncode(jobs.map((j) => j.toJson()).toList()),
      );

  static Future<List<EmployerJobModel>> loadJobs() async {
    final raw = await _read(_jobsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EmployerJobModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EmployerStore] jobs unreadable, discarding: $e');
      await clearKey(_jobsKey);
      return [];
    }
  }

  // -------------------------------------------------------- candidate state
  //
  // The candidates themselves come from the seeded pool; what belongs to this
  // company is what it has *done* with them — the stage they were moved to,
  // whether a contact credit was spent, whether they were archived. Storing
  // only that keeps the write small and means a refreshed candidate pool does
  // not wipe a recruiter's pipeline.

  static Future<void> saveCandidateState(Map<String, dynamic> state) =>
      _write(_candidateStateKey, jsonEncode(state));

  static Future<Map<String, dynamic>> loadCandidateState() async {
    final raw = await _read(_candidateStateKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[EmployerStore] candidate state unreadable: $e');
      await clearKey(_candidateStateKey);
      return {};
    }
  }

  // -------------------------------------------------------------------- notes

  /// Private recruiter notes, spec §75. Keyed by candidate id.
  static Future<void> saveNotes(Map<String, List<String>> notes) =>
      _write(_notesKey, jsonEncode(notes));

  static Future<Map<String, List<String>>> loadNotes() async {
    final raw = await _read(_notesKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(
            k,
            (v as List<dynamic>).map((e) => e.toString()).toList(),
          ));
    } catch (_) {
      return {};
    }
  }

  // ---------------------------------------------------- charges, spec §66

  static Future<void> saveCharges(List<EmployerCharge> charges) => _write(
        _chargesKey,
        jsonEncode(charges.map((c) => c.toJson()).toList()),
      );

  static Future<List<EmployerCharge>> loadCharges() async {
    final raw = await _read(_chargesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EmployerCharge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EmployerStore] charges unreadable, discarding: $e');
      await clearKey(_chargesKey);
      return [];
    }
  }

  // ---------------------------------------------------------------- documents

  static Future<List<UploadedDocument>> loadDocuments() async {
    final raw = await _read(_documentIndexKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => UploadedDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EmployerStore] document index unreadable: $e');
      await clearKey(_documentIndexKey);
      return [];
    }
  }

  static Future<void> saveDocuments(List<UploadedDocument> documents) => _write(
        _documentIndexKey,
        jsonEncode(documents.map((d) => d.toJson()).toList()),
      );

  static Future<void> addDocument(UploadedDocument document) async {
    final documents = await loadDocuments()
      ..removeWhere((d) => d.id == document.id)
      ..add(document);
    await saveDocuments(documents);
  }

  static Future<void> removeDocument(String id) async {
    final documents = await loadDocuments()..removeWhere((d) => d.id == id);
    await saveDocuments(documents);
    await clearKey('$_documentBytesPrefix$id');
  }

  static Future<void> saveDocumentBytes(String id, String dataUri) =>
      _write('$_documentBytesPrefix$id', dataUri);

  static Future<String?> loadDocumentBytes(String id) =>
      _read('$_documentBytesPrefix$id');

  // ---------------------------------------------------------------- lifecycle

  static Future<void> clearAll() async {
    for (final document in await loadDocuments()) {
      await clearKey('$_documentBytesPrefix${document.id}');
    }
    for (final key in [
      _companyKey,
      _jobsKey,
      _candidateStateKey,
      _notesKey,
      _documentIndexKey,
      _chargesKey,
    ]) {
      await clearKey(key);
    }
  }

  static Future<void> clearKey(String key) async {
    try {
      (await _prefs).remove(key);
    } catch (e) {
      debugPrint('[EmployerStore] clear $key failed: $e');
    }
  }

  // ------------------------------------------------------------------ private

  static Future<void> _write(String key, String value) async {
    try {
      await (await _prefs).setString(key, value);
    } catch (e) {
      debugPrint('[EmployerStore] write $key failed: $e');
    }
  }

  static Future<String?> _read(String key) async {
    try {
      return (await _prefs).getString(key);
    } catch (e) {
      debugPrint('[EmployerStore] read $key failed: $e');
      return null;
    }
  }
}

/// Alias so the shared [DocumentService] copied from the job seeker app needs no
/// edits. Both apps call `LocalStore`; only the keys differ, which is what keeps
/// a company's documents out of a candidate's store on a shared device.
typedef LocalStore = EmployerStore;
