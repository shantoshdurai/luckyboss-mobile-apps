import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import '../services/profile_photo_service.dart';

/// The candidate's profile photo, and the whole flow for setting one.
///
/// Tapping opens a sheet offering camera or device gallery — spec §31 lists
/// Profile Photo as part of the complete resume profile, and the two sources
/// are what a candidate on a phone actually has.
///
/// Falls back to initials rather than a generic silhouette. A grey person icon
/// reads as "broken"; initials read as "not set yet", which is what is true.
class ProfilePhotoAvatar extends StatefulWidget {
  final double size;

  /// When false the avatar renders but cannot be changed — used for the demo
  /// account, where the server would refuse the upload anyway.
  final bool editable;

  const ProfilePhotoAvatar({
    super.key,
    this.size = 58,
    this.editable = true,
  });

  @override
  State<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends State<ProfilePhotoAvatar> {
  bool _busy = false;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'LB';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _pick(PhotoSource source) async {
    setState(() => _busy = true);
    final result = await ProfilePhotoService.capture(source);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.ok) {
      context.read<JobSeekerProvider>().setProfilePhoto(result.url);
      _notify('Profile photo updated.');
      return;
    }

    switch (result.failure) {
      // Backing out of the picker is a normal action, not a failure to report.
      case PhotoFailure.cancelled:
        return;
      case PhotoFailure.permissionPermanentlyDenied:
        _offerSettings(result.message!);
        return;
      default:
        if (result.message != null) _notify(result.message!);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    final ok = await ProfilePhotoService.remove();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      context.read<JobSeekerProvider>().setProfilePhoto(null);
      _notify('Profile photo removed.');
    } else {
      _notify('Could not remove the photo. Please try again.');
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: AppTheme.primaryFillOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// The permanently-denied case. Re-requesting here would do nothing at all —
  /// Android will not show the dialog again — so the only useful action is to
  /// take the user to Settings.
  void _offerSettings(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Permission needed',
            style: AppTheme.sansBold(fontSize: 17, color: AppTheme.inkOf(context))),
        content: Text(message,
            style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not now',
                style: AppTheme.sansMedium(fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ProfilePhotoService.openSettings();
            },
            child: Text('Open Settings',
                style: AppTheme.sansBold(fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );
  }

  void _openSheet(bool hasPhoto) {
    showModalBottomSheet<void>(
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
                style: AppTheme.sansBold(fontSize: 17, color: AppTheme.inkOf(context))),
            const SizedBox(height: 4),
            Text(
              'Employers see this next to your name on every application.',
              style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.inkMutedOf(context)),
            ),
            const SizedBox(height: 16),
            _sheetAction(
              ctx,
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () {
                Navigator.pop(ctx);
                _pick(PhotoSource.camera);
              },
            ),
            _sheetAction(
              ctx,
              icon: Icons.photo_library_outlined,
              label: 'Choose from device',
              onTap: () {
                Navigator.pop(ctx);
                _pick(PhotoSource.gallery);
              },
            ),
            if (hasPhoto)
              _sheetAction(
                ctx,
                icon: Icons.delete_outline,
                label: 'Remove current photo',
                danger: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _remove();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheetAction(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppTheme.signalClosed : AppTheme.inkOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 14),
            Text(label, style: AppTheme.sansMedium(fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<JobSeekerProvider>().profile;
    final photoUrl = profile.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final radius = BorderRadius.circular(widget.size * 0.31);

    return Semantics(
      label: hasPhoto ? 'Profile photo' : 'Add a profile photo',
      button: widget.editable,
      child: GestureDetector(
        onTap: widget.editable && !_busy ? () => _openSheet(hasPhoto) : null,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: AppTheme.inkOf(context),
                  borderRadius: radius,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? _photo(photoUrl, profile.name)
                    : _initialsBlock(profile.name),
              ),
              if (_busy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: radius,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppTheme.onInkOf(context)),
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.editable && !_busy)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Icon(
                      hasPhoto ? Icons.edit_outlined : Icons.add_a_photo_outlined,
                      size: widget.size * 0.19,
                      color: AppTheme.inkOf(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the photo from wherever it is held.
  ///
  /// A photo saved on this device is a `data:` URI, and `Image.network` cannot
  /// read one on Android or iOS — it treats it as a URL and fails. So the two
  /// cases are split explicitly rather than hoping one widget covers both.
  Widget _photo(String url, String name) {
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma == -1) return _initialsBlock(name);
      try {
        final Uint8List bytes = base64Decode(url.substring(comma + 1));
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => _initialsBlock(name),
        );
      } catch (_) {
        return _initialsBlock(name);
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      // A photo that fails to load must not leave a blank square — fall back
      // to the initials that would have been there anyway.
      errorBuilder: (context, error, stack) => _initialsBlock(name),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _initialsBlock(name),
    );
  }

  Widget _initialsBlock(String name) => Center(
        child: Text(
          _initials(name),
          style: AppTheme.sansBold(
            fontSize: widget.size * 0.41,
            color: AppTheme.onInkOf(context),
          ),
        ),
      );
}
