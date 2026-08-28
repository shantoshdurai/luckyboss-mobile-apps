import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/config/api_config.dart';
import 'auth_service.dart';

/// Where a candidate's photo came from.
enum PhotoSource { camera, gallery }

/// Why a pick did not produce a photo. The UI reacts differently to each:
/// a cancel is silent, a denial explains, a permanent denial offers Settings.
enum PhotoFailure { cancelled, permissionDenied, permissionPermanentlyDenied, error }

class PhotoResult {
  final String? url;
  final PhotoFailure? failure;
  final String? message;

  const PhotoResult.success(this.url)
      : failure = null,
        message = null;

  const PhotoResult.failed(this.failure, this.message) : url = null;

  bool get ok => url != null;
}

/// Capture, permission and upload for the candidate profile photo (spec §31).
///
/// The permission model here is the part worth reading. Asking the OS for a
/// permission is not the same as having one, and a user who has denied twice on
/// Android will never see the system dialog again no matter how many times the
/// app requests it. So a denial is not treated as a generic error: the app
/// distinguishes "not now" from "never again", and only the second case sends
/// the user to Settings. Prompting into a void is how permission flows earn
/// their reputation for being broken.
class ProfilePhotoService {
  ProfilePhotoService._();

  static final ImagePicker _picker = ImagePicker();

  /// Longest edge requested from the platform picker.
  ///
  /// The server re-encodes to its own ceiling regardless — this is not a
  /// security control, it is courtesy. Shrinking before upload saves a
  /// candidate on mobile data from posting an 8MB camera original over a
  /// connection they are paying for.
  static const double _maxEdge = 1440;
  static const int _quality = 88;

  /// Picks a photo, asking for the right permission first, and uploads it.
  ///
  /// Returns the absolute URL of the stored photo on success.
  static Future<PhotoResult> capture(PhotoSource source) async {
    final permission = await _ensurePermission(source);
    if (permission != null) return permission;

    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxEdge,
        maxHeight: _maxEdge,
        imageQuality: _quality,
      );
    } catch (e) {
      debugPrint('[ProfilePhotoService] pick failed: $e');
      return const PhotoResult.failed(
        PhotoFailure.error,
        'Could not open the camera on this device.',
      );
    }

    // A null file means the user backed out of the picker. That is a normal
    // outcome, not an error, and must not raise a message at them.
    if (file == null) {
      return const PhotoResult.failed(PhotoFailure.cancelled, null);
    }

    return _upload(file);
  }

  /// Requests the permission [source] needs. Returns null when cleared to
  /// proceed, or a failure describing what to tell the user.
  static Future<PhotoResult?> _ensurePermission(PhotoSource source) async {
    // The browser has no permission_handler concept; getUserMedia prompts on
    // its own when the picker opens. Requesting here would report denied and
    // block a flow that actually works.
    if (kIsWeb) return null;

    // Gallery access on Android 13+ is granted implicitly to the system photo
    // picker image_picker uses, so requesting storage there prompts for
    // something the app does not need. Only the camera requires an explicit ask.
    if (source == PhotoSource.gallery && defaultTargetPlatform == TargetPlatform.android) {
      return null;
    }

    final permission =
        source == PhotoSource.camera ? Permission.camera : Permission.photos;

    var status = await permission.status;
    if (status.isGranted || status.isLimited) return null;

    if (status.isPermanentlyDenied) {
      return PhotoResult.failed(
        PhotoFailure.permissionPermanentlyDenied,
        source == PhotoSource.camera
            ? 'Camera access is turned off for Lucky Boss. Open Settings to allow it.'
            : 'Photo access is turned off for Lucky Boss. Open Settings to allow it.',
      );
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) return null;

    if (status.isPermanentlyDenied) {
      return PhotoResult.failed(
        PhotoFailure.permissionPermanentlyDenied,
        source == PhotoSource.camera
            ? 'Camera access is turned off for Lucky Boss. Open Settings to allow it.'
            : 'Photo access is turned off for Lucky Boss. Open Settings to allow it.',
      );
    }

    return PhotoResult.failed(
      PhotoFailure.permissionDenied,
      source == PhotoSource.camera
          ? 'Lucky Boss needs camera access to take your profile photo.'
          : 'Lucky Boss needs photo access to choose a profile photo.',
    );
  }

  /// Sends the file to `POST /api/v1/job-seeker/photo`.
  static Future<PhotoResult> _upload(XFile file) async {
    try {
      final headers = await AuthService.authHeaders();
      if (!headers.containsKey('Authorization')) {
        return const PhotoResult.failed(
          PhotoFailure.error,
          'Please sign in again to update your photo.',
        );
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.v1}/job-seeker/photo'),
      )..headers.addAll(headers);

      // Read as bytes rather than by path: on web there is no filesystem path,
      // and fromPath would throw.
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        await file.readAsBytes(),
        filename: file.name.isEmpty ? 'photo.jpg' : file.name,
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
        );
      }
      if (response.statusCode == 401) {
        return const PhotoResult.failed(
          PhotoFailure.error,
          'Your session expired. Please sign in again.',
        );
      }
      if (response.statusCode == 422) {
        return PhotoResult.failed(
          PhotoFailure.error,
          _validationMessage(response.body) ?? 'That photo could not be used.',
        );
      }
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
  static Future<bool> remove() async {
    try {
      final headers = await AuthService.authHeaders();
      if (!headers.containsKey('Authorization')) return false;
      final res = await http
          .delete(Uri.parse('${ApiConfig.v1}/job-seeker/photo'), headers: headers)
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ProfilePhotoService] remove failed: $e');
      return false;
    }
  }

  /// Opens the OS settings page for this app, for the permanently-denied case.
  static Future<void> openSettings() => openAppSettings();

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
