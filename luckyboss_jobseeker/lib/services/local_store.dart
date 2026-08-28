import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/application_model.dart';
import '../models/uploaded_document.dart';
import '../models/seeker_profile_model.dart';

/// Everything the candidate owns, kept on this handset.
///
/// Lucky Boss ships as a standalone APK: a candidate installs it, signs in and
/// fills their profile with no Laravel instance behind them. Until this class
/// existed, `JobSeekerProvider` held all of that in memory only — the profile,
/// the skills, the saved jobs, the applications — so closing the app threw the
/// lot away and the next launch showed an empty account. That is the second
/// half of the bug sir reported; the first half was the session itself, which
/// [AuthService] now persists.
///
/// Design notes worth keeping:
///
/// * **One key per concern, not one blob.** A corrupt applications list must
///   not be able to take the profile down with it, so each read is guarded
///   separately and a failure degrades to that section's default.
/// * **Never throw.** This sits underneath the UI on the startup path. A read
///   that fails returns the empty value and lets the app open; a write that
///   fails is logged and swallowed. Losing a saved-job toggle is bad, refusing
///   to launch is worse.
/// * **Writes are fire-and-forget from the provider's point of view.** They are
///   small and infrequent — a few kilobytes on an explicit user action.
class LocalStore {
  LocalStore._();

  static const String _profileKey = 'luckyboss_profile_v1';
  static const String _savedJobsKey = 'luckyboss_saved_jobs_v1';
  static const String _applicationsKey = 'luckyboss_applications_v1';
  static const String _answeredPromptsKey = 'luckyboss_prompts_answered_v1';
  static const String _dismissedPromptsKey = 'luckyboss_prompts_dismissed_v1';
  static const String _documentIndexKey = 'luckyboss_documents_v1';
  static const String _documentBytesPrefix = 'luckyboss_doc_';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ---------------------------------------------------------------- profile

  static Future<void> saveProfile(SeekerProfileModel profile) =>
      _write(_profileKey, jsonEncode(profile.toJson()));

  static Future<SeekerProfileModel?> loadProfile() async {
    final raw = await _read(_profileKey);
    if (raw == null) return null;
    try {
      return SeekerProfileModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[LocalStore] profile unreadable, discarding: $e');
      await clearKey(_profileKey);
      return null;
    }
  }

  // ------------------------------------------------------------ saved jobs

  static Future<void> saveSavedJobs(Set<String> ids) =>
      _writeList(_savedJobsKey, ids.toList());

  static Future<Set<String>> loadSavedJobs() async =>
      (await _readList(_savedJobsKey)).toSet();

  // ---------------------------------------------------------- applications

  static Future<void> saveApplications(List<ApplicationModel> apps) => _write(
        _applicationsKey,
        jsonEncode(apps.map((a) => a.toJson()).toList()),
      );

  static Future<List<ApplicationModel>> loadApplications() async {
    final raw = await _read(_applicationsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LocalStore] applications unreadable, discarding: $e');
      await clearKey(_applicationsKey);
      return [];
    }
  }

  // ------------------------------------------------- feed prompt answers

  /// Which of the preference questions interleaved in the job feed have already
  /// been answered or waved away.
  ///
  /// The answers themselves live on the profile — this only records that the
  /// question is done with, so a candidate is not asked it again on every
  /// launch. Being re-asked something you already answered is the clearest
  /// possible signal that an app is not listening.
  static Future<void> savePromptState({
    required Set<String> answered,
    required Set<String> dismissed,
  }) async {
    await _writeList(_answeredPromptsKey, answered.toList());
    await _writeList(_dismissedPromptsKey, dismissed.toList());
  }

  static Future<Set<String>> loadAnsweredPrompts() async =>
      (await _readList(_answeredPromptsKey)).toSet();

  static Future<Set<String>> loadDismissedPrompts() async =>
      (await _readList(_dismissedPromptsKey)).toSet();

  // -------------------------------------------------------------- documents
  //
  // Split in two on purpose. The index is metadata — a few hundred bytes — and
  // is read with the profile on every launch. The payload of each document can
  // be megabytes of base64 and is read only when something actually renders it.
  // Holding both in one blob would mean decoding every licence photo a
  // candidate owns each time the profile screen rebuilt.

  static Future<List<UploadedDocument>> loadDocuments() async {
    final raw = await _read(_documentIndexKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => UploadedDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LocalStore] document index unreadable, discarding: $e');
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
    // The payload goes with it. Orphaned bytes would sit in preferences
    // forever, invisible and unreachable.
    await clearKey('$_documentBytesPrefix$id');
  }

  static Future<void> saveDocumentBytes(String id, String dataUri) =>
      _write('$_documentBytesPrefix$id', dataUri);

  static Future<String?> loadDocumentBytes(String id) =>
      _read('$_documentBytesPrefix$id');

  // ------------------------------------------------------------- lifecycle

  /// Wipes the candidate's data. Called on sign-out, alongside
  /// `AuthService.logout()` — leaving this behind would show the next person to
  /// sign in on the same handset the previous one's profile.
  static Future<void> clearAll() async {
    // Every document payload first, while the index still names them —
    // clearing the index first would strand the bytes on the device.
    for (final document in await loadDocuments()) {
      await clearKey('$_documentBytesPrefix${document.id}');
    }
    for (final key in [
      _profileKey,
      _savedJobsKey,
      _applicationsKey,
      _answeredPromptsKey,
      _dismissedPromptsKey,
      _documentIndexKey,
    ]) {
      await clearKey(key);
    }
  }

  static Future<void> clearKey(String key) async {
    try {
      (await _prefs).remove(key);
    } catch (e) {
      debugPrint('[LocalStore] clear $key failed: $e');
    }
  }

  // --------------------------------------------------------------- private

  static Future<void> _write(String key, String value) async {
    try {
      await (await _prefs).setString(key, value);
    } catch (e) {
      debugPrint('[LocalStore] write $key failed: $e');
    }
  }

  static Future<String?> _read(String key) async {
    try {
      return (await _prefs).getString(key);
    } catch (e) {
      debugPrint('[LocalStore] read $key failed: $e');
      return null;
    }
  }

  static Future<void> _writeList(String key, List<String> value) async {
    try {
      await (await _prefs).setStringList(key, value);
    } catch (e) {
      debugPrint('[LocalStore] write $key failed: $e');
    }
  }

  static Future<List<String>> _readList(String key) async {
    try {
      return (await _prefs).getStringList(key) ?? [];
    } catch (e) {
      debugPrint('[LocalStore] read $key failed: $e');
      return [];
    }
  }
}
