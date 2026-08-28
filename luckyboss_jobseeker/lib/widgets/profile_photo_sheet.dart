import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import '../services/profile_photo_service.dart';

/// Choosing and saving a profile photo, from anywhere.
///
/// Extracted because the avatar owned this flow privately, so the only way to
/// set a photo was to tap the avatar itself. The "Add photo" card in the
/// profile-completion list called a method that showed a snackbar reading *"Tap
/// your photo above to take or choose one"* — a button whose entire function
/// was to tell you to press a different button. Shantosh found it immediately.
///
/// Now both entry points call [ProfilePhotoSheet.open] and behave identically.
class ProfilePhotoSheet {
  ProfilePhotoSheet._();

  /// Opens the camera/device sheet and stores whatever comes back.
  ///
  /// Returns true when a photo was saved. Safe to call from any screen that has
  /// a [JobSeekerProvider] above it.
  static Future<bool> open(BuildContext context, {bool hasPhoto = false}) async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Profile photo',
                style: AppTheme.sansBold(
                    fontSize: 17, color: AppTheme.inkOf(context))),
            const SizedBox(height: 4),
            Text(
              'Employers see this next to your name on every application.',
              style: AppTheme.sansRegular(
                  fontSize: 13, color: AppTheme.inkMutedOf(context)),
            ),
            const SizedBox(height: 16),
            _action(context, ctx, Icons.photo_camera_outlined, 'Take a photo',
                PhotoSource.camera),
            _action(context, ctx, Icons.photo_library_outlined,
                'Choose from device', PhotoSource.gallery),
            if (hasPhoto)
              _action(context, ctx, Icons.delete_outline,
                  'Remove current photo', null,
                  danger: true),
          ],
        ),
      ),
    );

    if (!context.mounted) return false;

    // A null source with hasPhoto means "remove" was tapped; a plain dismiss
    // also lands here, which is why removal is signalled separately below.
    if (source == null) return false;
    return _capture(context, source);
  }

  /// Clears the photo. Separate from [open] so a caller can offer removal
  /// without going through the sheet.
  static Future<void> remove(BuildContext context) async {
    final provider = context.read<JobSeekerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ProfilePhotoService.remove();
    if (!context.mounted) return;
    if (ok) {
      provider.setProfilePhoto(null);
      _notify(messenger, context, 'Profile photo removed.',
          AppTheme.primaryFillOf(context));
    }
  }

  static Future<bool> _capture(BuildContext context, PhotoSource source) async {
    final provider = context.read<JobSeekerProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await ProfilePhotoService.capture(source);
    if (!context.mounted) return false;

    if (result.ok) {
      provider.setProfilePhoto(result.url);
      _notify(messenger, context, 'Profile photo updated.',
          AppTheme.signalPositive);
      return true;
    }

    switch (result.failure) {
      // Backing out of the picker is a normal action, not a failure to report.
      case PhotoFailure.cancelled:
        return false;
      case PhotoFailure.permissionPermanentlyDenied:
        await _offerSettings(context, result.message!);
        return false;
      default:
        if (result.message != null) {
          _notify(messenger, context, result.message!, AppTheme.signalClosed);
        }
        return false;
    }
  }

  static Widget _action(
    BuildContext outer,
    BuildContext sheet,
    IconData icon,
    String label,
    PhotoSource? source, {
    bool danger = false,
  }) {
    final color = danger ? AppTheme.signalClosed : AppTheme.inkOf(outer);
    return InkWell(
      onTap: () async {
        Navigator.pop(sheet, source);
        if (source == null && outer.mounted) await remove(outer);
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 14),
            Text(label,
                style: AppTheme.sansMedium(fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }

  /// The permanently-denied case. Re-requesting would do nothing at all —
  /// Android will not show the dialog again — so the only useful action is to
  /// take the user to Settings.
  static Future<void> _offerSettings(
      BuildContext context, String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Permission needed',
            style: AppTheme.sansBold(
                fontSize: 17, color: AppTheme.inkOf(context))),
        content: Text(message,
            style: AppTheme.sansRegular(
                fontSize: 14, color: AppTheme.inkMutedOf(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not now',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ProfilePhotoService.openSettings();
            },
            child: Text('Open Settings',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );
  }

  static void _notify(ScaffoldMessengerState messenger, BuildContext context,
      String message, Color tone) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message,
            style: AppTheme.sansMedium(
                fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: tone,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
