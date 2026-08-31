import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/employer_job.dart';
import '../providers/employer_provider.dart';
import '../screens/auth/company_registration_screen.dart';
import '../screens/auth/verification_pending_screen.dart';
import '../screens/employer_notifications_screen.dart';
import '../screens/jobs/post_job_wizard_screen.dart';
import '../screens/settings_screen.dart';
import 'lucky_ai_copilot_modal.dart';
import 'lucky_boss_brand_logo.dart';

/// The side panel, matching the job seeker app's.
///
/// Shantosh: *"also the left side panel like in job seeker for portal app, and
/// settings in profiles."* The employer app had no drawer at all, so anything
/// not on one of the four tabs — registration, verification, the assistant,
/// settings — could only be reached by knowing which screen hid it.
///
/// The header carries the company's verification state rather than just its
/// name, because that is the fact which decides what every other item in the
/// list will let them do.
class EmployerDrawer extends StatelessWidget {
  /// Switches the main navigation to a tab index.
  final ValueChanged<int> onNavigate;

  const EmployerDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final company = provider.company;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LuckyBossBrandLogo(height: 28),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.inkOf(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          company.name.trim().isEmpty
                              ? 'LB'
                              : company.name
                                  .trim()
                                  .split(RegExp(r'\s+'))
                                  .take(2)
                                  .map((w) => w[0].toUpperCase())
                                  .join(),
                          style: AppTheme.sansBold(
                              fontSize: 15,
                              color: AppTheme.onInkOf(context)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name.isEmpty
                                  ? 'Your company'
                                  : company.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.sansBold(
                                  fontSize: 15,
                                  color: AppTheme.inkOf(context)),
                            ),
                            // The state that gates everything else, said here
                            // rather than left for a failed action to reveal.
                            Row(
                              children: [
                                Icon(
                                  company.isVerified
                                      ? Icons.verified
                                      : Icons.hourglass_top_rounded,
                                  size: 12,
                                  color: company.isVerified
                                      ? AppTheme.signalPositive
                                      : AppTheme.signalAttention,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  company.status.label,
                                  style: AppTheme.sansMedium(
                                    fontSize: 11.5,
                                    color: company.isVerified
                                        ? AppTheme.signalPositive
                                        : AppTheme.signalAttention,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(context, Icons.dashboard_outlined, 'Dashboard',
                      () => _go(context, 0)),
                  _item(context, Icons.business_center_outlined, 'Your jobs',
                      () => _go(context, 1)),
                  _item(context, Icons.people_outline, 'Candidates',
                      () => _go(context, 2)),
                  _item(context, Icons.apartment_outlined, 'Company profile',
                      () => _go(context, 3)),

                  const SizedBox(height: 6),
                  Divider(color: Theme.of(context).dividerColor, height: 20),

                  _item(context, Icons.add_circle_outline, 'Post a vacancy', () {
                    Navigator.pop(context);
                    if (provider.canPost) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PostJobWizardScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VerificationPendingScreen()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Your company is awaiting verification. Approve the company to post vacancies.',
                            style: AppTheme.sansMedium(
                                fontSize: 13, color: AppTheme.onInkOf(context)),
                          ),
                          backgroundColor: AppTheme.signalAttention,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }),
                  _item(context, Icons.auto_awesome, 'Speak to Lucky AI', () {
                    Navigator.pop(context);
                    LuckyAiCopilotModal.show(context);
                  }),
                  _item(context, Icons.notifications_none, 'Notifications', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmployerNotificationsScreen()),
                    );
                  }),

                  const SizedBox(height: 6),
                  Divider(color: Theme.of(context).dividerColor, height: 20),

                  // Registration or its status, whichever applies — one row
                  // rather than two that are never both useful.
                  _item(
                    context,
                    company.status == CompanyStatus.draft
                        ? Icons.assignment_outlined
                        : Icons.verified_user_outlined,
                    company.status == CompanyStatus.draft
                        ? 'Register your company'
                        : 'Verification status',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => company.status == CompanyStatus.draft
                              ? const CompanyRegistrationScreen()
                              : const VerificationPendingScreen(),
                        ),
                      );
                    },
                  ),
                  _item(context, Icons.settings_outlined, 'Settings', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }),
                ],
              ),
            ),

            Divider(color: Theme.of(context).dividerColor, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.contact_phone_outlined,
                      size: 14, color: AppTheme.inkFaintOf(context)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${provider.contactCreditsRemaining} contact credits · '
                      '${provider.activeJobsCount} live',
                      style: AppTheme.sansMedium(
                          fontSize: 11.5,
                          color: AppTheme.inkMutedOf(context)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, int index) {
    Navigator.pop(context);
    onNavigate(index);
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) =>
      ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, size: 20, color: AppTheme.inkMutedOf(context)),
        title: Text(label,
            style: AppTheme.sansMedium(
                fontSize: 14.5, color: AppTheme.inkOf(context))),
        onTap: onTap,
      );
}
