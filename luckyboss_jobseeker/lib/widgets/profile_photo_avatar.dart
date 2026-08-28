import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import 'profile_photo_sheet.dart';

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

  /// Opens the shared photo sheet.
  ///
  /// The picking, permission and storage logic used to live in this widget,
  /// which meant the only way to set a photo was to tap the avatar — the
  /// "Add photo" card elsewhere on the profile could do nothing but tell you
  /// to come here. It is in [ProfilePhotoSheet] now so both work.
  Future<void> _open(bool hasPhoto) async {
    setState(() => _busy = true);
    await ProfilePhotoSheet.open(context, hasPhoto: hasPhoto);
    if (mounted) setState(() => _busy = false);
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
        onTap: widget.editable && !_busy ? () => _open(hasPhoto) : null,
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
