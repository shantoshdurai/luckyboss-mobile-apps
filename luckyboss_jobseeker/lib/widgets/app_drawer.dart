import 'package:flutter/material.dart';

import '../screens/edit_profile_screen.dart';
import 'lucky_ai_copilot_modal.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import '../services/app_settings_service.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/sign_in_screen.dart';
import 'lucky_boss_brand_logo.dart';
import 'profile_photo_avatar.dart';

/// The left navigation drawer.
///
/// The bottom bar holds the four places a candidate moves between constantly.
/// Everything they need occasionally — saved jobs, how matching works, help,
/// settings — was previously buried in the profile tab or nowhere at all. A
/// drawer is where those belong: reachable in one gesture, out of the way the
/// rest of the time.
///
/// Deliberately absent: the paid tiers and promoted content that fill the
/// equivalent panel on other job apps. Monetisation here is admin-controlled
/// (spec §3), so nothing is advertised until the admin actually switches it on.
class AppDrawer extends StatelessWidget {
  /// Jumps the shell to a bottom-bar tab by index.
  final ValueChanged<int> onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final profile = provider.profile;
    final strength = provider.profileCompletion;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _header(context, profile.name, profile.email, strength),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(context, Icons.search, 'Search jobs',
                      () => _go(context, 1)),
                  _item(context, Icons.auto_awesome_outlined, 'Recommended for you',
                      () => _go(context, 0)),
                  _item(context, Icons.bookmark_border, 'Saved jobs',
                      () => _go(context, 1),
                      trailing: provider.savedJobs.isEmpty
                          ? null
                          : '${provider.savedJobs.length}'),
                  _item(context, Icons.description_outlined, 'My applications',
                      () => _go(context, 2),
                      trailing: provider.myApplications.isEmpty
                          ? null
                          : '${provider.myApplications.length}'),
                  const Divider(height: 24, indent: 20, endIndent: 20),
                  // The assistant, reachable from the menu as well as the
                  // header icon. Shantosh asked for it here because the drawer
                  // is where people look for "things the app can do".
                  if (AppSettingsService.current.aiAssistant)
                  _item(context, Icons.auto_awesome, 'Speak to Lucky AI',
                      () {
                    Navigator.pop(context);
                    LuckyAiCopilotModal.show(context);
                  }),
                  _item(context, Icons.edit_outlined, 'Edit my profile', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    );
                  }),
                  _item(context, Icons.person_outline, 'Profile & resume',
                      () => _go(context, 3)),
                  _item(context, Icons.insights_outlined, 'How matching works',
                      () => _explainMatching(context)),
                  const Divider(height: 24, indent: 20, endIndent: 20),
                  _item(
                    context,
                    Icons.brightness_6_outlined,
                    'Display',
                    () => _displayPreference(context),
                    trailing: context.watch<ThemeProvider>().label,
                  ),
                  _item(context, Icons.help_outline, 'Help & support',
                      () => _comingSoon(context, 'Help & support')),
                  _item(context, Icons.info_outline, 'About Luckyboss',
                      () => _about(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _item(
                context,
                Icons.logout,
                'Sign out',
                () => _signOut(context),
                danger: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String name, String email, int strength) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LuckyBossBrandLogo(height: 30),
          const SizedBox(height: 20),
          Row(
            children: [
              const ProfilePhotoAvatar(size: 46, editable: false),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.trim().isEmpty ? 'Your profile' : name,
                      style: AppTheme.sansBold(
                          fontSize: 15.5, color: AppTheme.inkOf(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.trim().isNotEmpty)
                      Text(
                        email,
                        style: AppTheme.sansRegular(
                            fontSize: 12, color: AppTheme.inkFaintOf(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Completion belongs here as well as on home: the drawer is where a
          // returning candidate goes looking for their profile, so the nudge
          // meets them on the way.
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: strength / 100,
                    minHeight: 5,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation(
                      strength >= 80
                          ? AppTheme.signalPositive
                          : strength >= 50
                              ? AppTheme.signalProgress
                              : AppTheme.signalAttention,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$strength%',
                  style: AppTheme.sansBold(
                      fontSize: 12.5, color: AppTheme.inkOf(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    String? trailing,
    bool danger = false,
  }) {
    final color = danger ? AppTheme.signalClosed : AppTheme.inkOf(context);
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(icon, size: 21, color: danger ? color : AppTheme.inkMutedOf(context)),
      title: Text(label,
          style: AppTheme.sansMedium(fontSize: 14.5, color: color)),
      trailing: trailing == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.paperOf(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(trailing,
                  style: AppTheme.sansBold(
                      fontSize: 11.5, color: AppTheme.inkMutedOf(context))),
            ),
      onTap: onTap,
    );
  }

  void _go(BuildContext context, int index) {
    Navigator.pop(context);
    onNavigate(index);
  }

  /// Light / dark / system.
  ///
  /// Three options rather than a switch: "follow system" is what most people
  /// want and a toggle cannot express it.
  void _displayPreference(BuildContext context) {
    final provider = context.read<ThemeProvider>();
    Navigator.pop(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 20),
            Text('Display',
                style: AppTheme.sansBold(fontSize: 17, color: AppTheme.inkOf(context))),
            const SizedBox(height: 4),
            Text('Applies straight away and is remembered on this device.',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkMutedOf(context))),
            const SizedBox(height: 14),
            ...[
              (ThemeMode.light, 'Light', Icons.light_mode_outlined),
              (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              (ThemeMode.system, 'Follow system', Icons.brightness_auto_outlined),
            ].map((option) {
              final selected = provider.mode == option.$1;
              return InkWell(
                onTap: () {
                  provider.setMode(option.$1);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(option.$3,
                          size: 20,
                          color: selected
                              ? AppTheme.signalPositive
                              : AppTheme.inkMutedOf(context)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(option.$2,
                            style: selected
                                ? AppTheme.sansBold(
                                    fontSize: 15, color: AppTheme.signalPositive)
                                : AppTheme.sansMedium(
                                    fontSize: 15, color: AppTheme.inkOf(context))),
                      ),
                      if (selected)
                        const Icon(Icons.check,
                            size: 19, color: AppTheme.signalPositive),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String what) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$what is not available yet.',
            style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: AppTheme.signalAttention,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Explains the match percentage.
  ///
  /// A number attached to someone's job prospects should never be unexplainable
  /// — spec §26 asks for match explanation, and a candidate who cannot see why
  /// they scored 40% cannot act on it.
  void _explainMatching(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 20),
            Text('How matching works',
                style: AppTheme.serifTitle(
                    fontSize: 22, color: AppTheme.inkOf(context))),
            const SizedBox(height: 12),
            _bullet(ctx, 'Your skills against the ones the vacancy asks for. '
                'This carries the most weight.'),
            _bullet(ctx, 'Your job category and experience level against the role.'),
            _bullet(ctx, 'Location and work mode, so you are not matched to '
                'a job you cannot reach.'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppTheme.signalAttentionWash,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Scores stay low until you add skills. With none listed there is '
                'nothing to match a vacancy against — it is not a judgement of you.',
                style: AppTheme.sansMedium(
                    fontSize: 13, color: AppTheme.signalAttention),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7, right: 10),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.inkFaintOf(context), shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(text,
                  style: AppTheme.sansRegular(
                      fontSize: 13.5, color: AppTheme.inkMutedOf(context))),
            ),
          ],
        ),
      );

  void _about(BuildContext context) {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'Luckyboss',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'Growth partner in your hiring journey.\nSingapore · Malaysia · India',
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final provider = context.read<JobSeekerProvider>();
    Navigator.pop(context);
    await provider.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }
}
