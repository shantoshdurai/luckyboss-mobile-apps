import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'auth_service.dart';
import 'document_service.dart';

/// Where a candidate's photo came from.
enum PhotoSource { camera, gallery }

/// Why a pick did not produce a photo. The UI reacts differently to each:
/// a cancel is silent, a denial explains, a permanent denial offers Settings.
enum PhotoFailure { cancelled, permissionDenied, permissionPermanentlyDenied, error }

class PhotoResult {
  final String? url;
  final PhotoFailure? failure;
  final String? message;

  /// True when [message] describes something the candidate can do something
  /// about — a photo the server rejected, a demo account that may not change
  /// its picture, a file too large. False for infrastructure failures, which
  /// are shown to nobody because the photo was saved on the device anyway.
  final bool actionable;

  const PhotoResult.success(this.url)
      : failure = null,
        message = null,
        actionable = false;

  const PhotoResult.failed(this.failure, this.message, {this.actionable = false})
      : url = null;

  bool get ok => url != null;
}

/// Capture, permission and storage for the candidate profile photo (spec §31).
///
/// Picking is delegated to [DocumentService] and that is the fix, not a tidy-up.
/// This class used to call `image_picker` directly for both camera and gallery,
/// and its gallery path opened nothing at all in the browser — the candidate
/// tapped "Choose from device" and the sheet simply closed. `file_picker` opens
/// a real file dialog on web (which also accepts a dragged file) and the system
/// picker on a handset, and returns bytes rather than a path, so there is no
/// filesystem to be missing on web.
class ProfilePhotoService {
  ProfilePhotoService._();

  /// Picks a photo and stores it.
  ///
  /// Returns a `data:` URI on success — the photo as it will be rendered.
  static Future<PhotoResult> capture(PhotoSource source) async {
    final picked = source == PhotoSource.camera
        ? await DocumentService.captureWithCamera()
        : await DocumentService.pickDocument(imagesOnly: true);

    if (!picked.isOk) {
      return switch (picked.failure) {
        PickFailure.cancelled =>
          const PhotoResult.failed(PhotoFailure.cancelled, null),
        PickFailure.permissionPermanentlyDenied => PhotoResult.failed(
            PhotoFailure.permissionPermanentlyDenied, picked.message,
            actionable: true),
        PickFailure.permissionDenied => PhotoResult.failed(
            PhotoFailure.permissionDenied, picked.message,
            actionable: true),
        _ => PhotoResult.failed(PhotoFailure.error, picked.message,
            actionable: true),
      };
    }

    return _store(picked.file!);
  }

  /// Opens the OS settings page for this app, for the permanently-denied case.
  static Future<void> openSettings() => DocumentService.openSettings();

  /// Stores the photo, on the server when there is one and on the device
  /// otherwise.
  ///
  /// The order matters and is deliberate. A candidate who has just framed a
  /// photo of themselves has done their part; whether a Laravel instance is
  /// reachable is not their problem and must not be reported to them as a
  /// failure. So the bytes are kept locally first, and the upload is an
  /// attempt layered on top: if it succeeds the server URL wins, and if it
  /// does not the local copy still shows and still survives a restart.
  ///
  /// The old behaviour was the opposite, and it is what sir hit — an account
  /// created offline had no Sanctum token, so this method stopped at the header
  /// check and answered "Please sign in again to update your photo" to somebody
  /// who was, as far as the app was concerned, signed in.
  static Future<PhotoResult> _store(PickedFile file) async {
    final local = DocumentService.dataUri(file.bytes, file.mimeType);

    final headers = await AuthService.authHeaders();
    // No Sanctum token means either a signed-out app or an on-device account.
    // Either way there is nothing to upload to, and the local copy is the
    // answer rather than an error.
    if (!headers.containsKey('Authorization')) {
      return PhotoResult.success(local);
    }

    final uploaded = await _upload(file, headers);
    // A refusal the candidate can act on (demo account, file too large) is
    // worth surfacing. A transport failure is not — keep the local photo.
    if (uploaded.ok) return uploaded;
    if (uploaded.message != null && uploaded.actionable) return uploaded;
    return PhotoResult.success(local);
  }

  /// True when [url] is a photo held on this device rather than on a server.
  static bool isLocal(String? url) => url != null && url.startsWith('data:');

  /// Sends the file to `POST /api/v1/job-seeker/photo`.
  static Future<PhotoResult> _upload(
    PickedFile file,
    Map<String, String> headers,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.v1}/job-seeker/photo'),
      )..headers.addAll(headers);

      // Read as bytes rather than by path: on web there is no filesystem path,
      // and fromPath would throw.
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        file.bytes,
        filename: file.fileName.isEmpty ? 'photo.jpg' : file.fileName,
      ));

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 45)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Prefer the storage path over the server's absolute `url`: APP_URL is
        // frequently left at its default in deployment, which would hand back a
        // localhost link no handset can load.
        final path = data['path'] as String?;
        final url = data['url'] as String?;
        return PhotoResult.success(
          path != null && path.isNotEmpty
              ? ApiConfig.storageUrl(path)
              : (url ?? ''),
        );
      }

      if (response.statusCode == 403) {
        return const PhotoResult.failed(
          PhotoFailure.error,
          'The demo account cannot change its photo. Create a free account to set yours.',
          actionable: true,
        );
      }
      if (response.statusCode == 422) {
        return PhotoResult.failed(
          PhotoFailure.error,
          _validationMessage(response.body) ?? 'That photo could not be used.',
          actionable: true,
        );
      }
      // 401 and every 5xx fall through: the photo is already safe on the
      // device, so telling the candidate about the server helps nobody.
      return PhotoResult.failed(
        PhotoFailure.error,
        'Upload failed (${response.statusCode}).',
      );
    } catch (e) {
      debugPrint('[ProfilePhotoService] upload failed: $e');
      return const PhotoResult.failed(
        PhotoFailure.error,
        'Could not reach the server. Your photo was not saved.',
      );
    }
  }

  /// Removes the stored photo.
  ///
  /// Always succeeds from the candidate's side: the local copy is what the app
  /// renders, so clearing it is the removal. The server call is best-effort
  /// housekeeping for accounts that have one.
  static Future<bool> remove() async {
    final headers = await AuthService.authHeaders();
    if (!headers.containsKey('Authorization')) return true;
    try {
      await http
          .delete(Uri.parse('${ApiConfig.v1}/job-seeker/photo'), headers: headers)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('[ProfilePhotoService] remove failed: $e');
    }
    return true;
  }

  static String? _validationMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      return data['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
