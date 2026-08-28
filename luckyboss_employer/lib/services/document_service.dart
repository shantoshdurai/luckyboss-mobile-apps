import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/uploaded_document.dart';
import 'local_store.dart';
import 'platform_file_picker/platform_file_picker.dart';

/// Why a pick produced nothing.
enum PickFailure {
  /// The user backed out. Normal, and must never raise a message.
  cancelled,
  permissionDenied,
  permissionPermanentlyDenied,
  tooLarge,
  unreadable,
}

class PickedFile {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const PickedFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}

class PickResult {
  final PickedFile? file;
  final PickFailure? failure;
  final String? message;

  const PickResult.ok(this.file)
      : failure = null,
        message = null;
  const PickResult.failed(this.failure, this.message) : file = null;

  bool get isOk => file != null;
}

/// Picking files, and keeping them.
///
/// This exists because "upload" was a word the app used without meaning it.
/// Tapping *Choose from device* on the profile photo did nothing at all, and the
/// licences sheet let a candidate tick "Forklift Licence" and press Save —
/// which recorded a claim and looked, to them, exactly like they had submitted
/// the card. Shantosh's words: "we can click on anything and we can click save,
/// it doesn't mean that they're uploading".
///
/// Two decisions worth keeping:
///
/// **Choosing is per platform; the camera is always `image_picker`.**
/// `image_picker`'s gallery path opened nothing at all in a browser, and
/// `file_picker` then threw there — two plugins, two silent failures, on the
/// one platform where the primitive is a few lines of DOM. Web now goes
/// straight to an `<input type="file">`; handsets keep `file_picker`, which is
/// solid there. See `platform_file_picker/`.
///
/// **Bytes are stored, not paths.** A path recorded on one install is not valid
/// after the next update, and on web there is no path in the first place.
class DocumentService {
  DocumentService._();

  /// Ceiling per file. Everything is held on the device, and a candidate who
  /// photographs a licence with a modern phone camera can easily produce 8MB —
  /// enough to make every read of the store noticeably slow.
  static const int maxBytes = 5 * 1024 * 1024;

  static const List<String> _documentExtensions = [
    'pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'doc', 'docx',
  ];

  static const List<String> _imageExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'heic',
  ];

  // ---------------------------------------------------------------------------
  // PICKING
  // ---------------------------------------------------------------------------

  /// Opens the device file browser.
  ///
  /// On web this is a plain `<input type="file">` rather than a plugin, because
  /// both plugins tried before it failed there — see
  /// `platform_file_picker/file_picker_web.dart`. The browser's own dialog also
  /// accepts a file dragged into it, which covers picking a photo off a desktop.
  static Future<PickResult> pickDocument({bool imagesOnly = false}) async {
    RawPickedFile? picked;
    try {
      picked = await pickPlatformFile(
        extensions: imagesOnly ? _imageExtensions : _documentExtensions,
      );
    } catch (e) {
      debugPrint('[DocumentService] picker failed: $e');
      return const PickResult.failed(
        PickFailure.unreadable,
        'Could not open the file picker on this device.',
      );
    }

    if (picked == null) {
      return const PickResult.failed(PickFailure.cancelled, null);
    }

    final bytes = picked.bytes;
    if (bytes.isEmpty) {
      return const PickResult.failed(
        PickFailure.unreadable,
        'That file could not be read. Try another one.',
      );
    }
    if (bytes.length > maxBytes) {
      return PickResult.failed(
        PickFailure.tooLarge,
        'That file is ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)}MB. '
        'Please choose one under 5MB, or take a photo of it instead.',
      );
    }

    return PickResult.ok(PickedFile(
      bytes: bytes,
      fileName: picked.fileName,
      mimeType: mimeFor(picked.fileName),
    ));
  }

  /// Opens the camera. Used for photographing a licence card or taking a
  /// profile picture, which is how most candidates will do both.
  static Future<PickResult> captureWithCamera() async {
    final denial = await _ensureCamera();
    if (denial != null) return denial;

    XFile? shot;
    try {
      shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[DocumentService] camera failed: $e');
      return const PickResult.failed(
        PickFailure.unreadable,
        'Could not open the camera on this device.',
      );
    }

    if (shot == null) {
      return const PickResult.failed(PickFailure.cancelled, null);
    }

    final bytes = await shot.readAsBytes();
    return PickResult.ok(PickedFile(
      bytes: bytes,
      fileName: shot.name.isEmpty ? 'photo.jpg' : shot.name,
      mimeType: mimeFor(shot.name.isEmpty ? 'photo.jpg' : shot.name),
    ));
  }

  /// Asks for camera permission, distinguishing "not now" from "never again".
  ///
  /// The distinction matters: once a user has denied twice, Android will not
  /// show the dialog again no matter how many times the app asks, so the only
  /// useful action left is to offer Settings.
  static Future<PickResult?> _ensureCamera() async {
    // The browser prompts on its own when the camera opens; asking through
    // permission_handler there reports denied and blocks a flow that works.
    if (kIsWeb) return null;

    var status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) return null;

    if (status.isPermanentlyDenied) {
      return const PickResult.failed(
        PickFailure.permissionPermanentlyDenied,
        'Camera access is turned off for Lucky Boss. Open Settings to allow it.',
      );
    }

    status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return null;
    if (status.isPermanentlyDenied) {
      return const PickResult.failed(
        PickFailure.permissionPermanentlyDenied,
        'Camera access is turned off for Lucky Boss. Open Settings to allow it.',
      );
    }

    return const PickResult.failed(
      PickFailure.permissionDenied,
      'Lucky Boss needs camera access to take the photo.',
    );
  }

  static Future<void> openSettings() => openAppSettings();

  // ---------------------------------------------------------------------------
  // STORING
  // ---------------------------------------------------------------------------

  /// Saves [file] and returns its index entry.
  ///
  /// The status is always [DocumentStatus.pending]. Only the server may mark a
  /// document verified — a handset asserting that its own upload has been
  /// checked would be worthless as a signal to an employer.
  static Future<UploadedDocument> save({
    required PickedFile file,
    required DocumentKind kind,
    required String label,
  }) async {
    final id = 'doc-${DateTime.now().microsecondsSinceEpoch}';
    final document = UploadedDocument(
      id: id,
      kind: kind,
      label: label,
      fileName: file.fileName,
      mimeType: file.mimeType,
      sizeBytes: file.bytes.length,
      uploadedAt: DateTime.now(),
    );

    await LocalStore.saveDocumentBytes(id, dataUri(file.bytes, file.mimeType));
    await LocalStore.addDocument(document);
    return document;
  }

  static Future<void> delete(String id) => LocalStore.removeDocument(id);

  static Future<String?> bytesFor(String id) => LocalStore.loadDocumentBytes(id);

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  /// A `data:` URI, which is the one representation that renders unchanged on
  /// Android, iOS and web.
  static String dataUri(Uint8List bytes, String mimeType) =>
      'data:$mimeType;base64,${base64Encode(bytes)}';

  /// Decodes a `data:` URI back to bytes, or null when it is not one.
  static Uint8List? bytesFromDataUri(String? uri) {
    if (uri == null || !uri.startsWith('data:')) return null;
    final comma = uri.indexOf(',');
    if (comma == -1) return null;
    try {
      return base64Decode(uri.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  static String mimeFor(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.doc')) return 'application/msword';
    if (name.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'image/jpeg';
  }
}
