import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
import '../jobs/post_job_wizard_screen.dart';
import '../settings_screen.dart';
import '../employer_notifications_screen.dart';
import '../../widgets/lucky_ai_copilot_modal.dart';
import '../auth/verification_pending_screen.dart';
import '../../models/employer_job.dart';

/// The employer dashboard, spec §78.
///
/// The nine cards the specification asks for, in the order a hiring manager
/// reads them: what is live, who is waiting, what is booked, and what the plan
/// has left. Each card is a way in — a count that cannot be tapped is a fact
/// nobody can act on, which is how dashboards become wallpaper.
class EmployerDashboardTab extends StatelessWidget {
  final VoidCallback? onOpenJobs;
  final VoidCallback? onOpenCandidates;
  final VoidCallback? onMenu;

  const EmployerDashboardTab({
    super.key,
    this.onOpenJobs,
    this.onOpenCandidates,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final expiry = provider.subscriptionExpiry;
    final daysLeft = expiry.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onMenu,
                  tooltip: 'Menu',
                  icon: Icon(Icons.menu, color: AppTheme.inkOf(context)),
                ),
                const LuckyBossBrandLogo(height: 30),
                const Spacer(),
                IconButton(
                  onPressed: () => LuckyAiCopilotModal.show(context),
                  tooltip: 'Lucky AI',
                  icon: Icon(Icons.auto_awesome_outlined,
                      color: AppTheme.inkOf(context)),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployerNotificationsScreen(
                        onOpenCandidates: onOpenCandidates,
                        onOpenJobs: onOpenJobs,
                      ),
                    ),
                  ),
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_none,
                      color: AppTheme.inkOf(context)),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  tooltip: 'Settings',
                  icon: Icon(Icons.settings_outlined,
                      color: AppTheme.inkOf(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              provider.company.name.isEmpty
                  ? 'Your hiring'
                  : provider.company.name,
              style: AppTheme.serifTitle(
                  fontSize: 26, color: AppTheme.inkOf(context)),
            ),
            const SizedBox(height: 4),
            Text(
              provider.jobs.isEmpty
                  ? 'Post your first vacancy to see who we can send you.'
                  : 'Here is where your hiring stands today.',
              style: AppTheme.sansRegular(
                  fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
            ),
            const SizedBox(height: 16),
            if (!provider.canPost) ...[
              _VerificationBanner(status: provider.company.status),
              const SizedBox(height: 18),
            ],

            // --- The pipeline, spec §78 ---
            _Section(title: 'Your pipeline'),
            _CardGrid(
              cards: [
                _Metric(
                  label: 'Active jobs',
                  value: '${provider.activeJobsCount}',
                  icon: Icons.work_outline,
                  tint: AppTheme.signalSource,
                  onTap: onOpenJobs,
                ),
                _Metric(
                  label: 'New applicants',
                  value: '${provider.newApplicantsCount}',
                  icon: Icons.person_add_alt,
                  tint: AppTheme.signalPositive,
                  onTap: onOpenCandidates,
                ),
                _Metric(
                  label: 'Recommended',
                  value: '${provider.recommendedCount}',
                  icon: Icons.auto_awesome_outlined,
                  tint: AppTheme.signalProgress,
                  onTap: onOpenCandidates,
                  // The number that makes this app worth opening on a quiet
                  // day: people we can send you who have not applied.
                  footnote: 'In the Lucky Boss database',
                ),
                _Metric(
                  label: 'Interviews',
                  value: '${provider.interviewsCount}',
                  icon: Icons.event_outlined,
                  tint: AppTheme.signalAttention,
                  onTap: onOpenCandidates,
                ),
                _Metric(
                  label: 'Offers pending',
                  value: '${provider.offersPendingCount}',
                  icon: Icons.drafts_outlined,
                  tint: AppTheme.signalProgress,
                  onTap: onOpenCandidates,
                ),
                _Metric(
                  label: 'Hired',
                  value: '${provider.hiredCount}',
                  icon: Icons.verified_outlined,
                  tint: AppTheme.signalPositive,
                  onTap: onOpenCandidates,
                ),
              ],
            ),

            const SizedBox(height: 22),
            _Section(title: 'Your plan'),
            _PlanRow(
              label: 'Contact credits',
              used: provider.contactCreditsUsed,
              total: provider.contactCreditsTotal,
              hint: 'Each one reveals a candidate\'s phone and email.',
            ),
            const SizedBox(height: 10),
            _PlanRow(
              label: 'AI credits',
              used: provider.aiCreditsUsed,
              total: provider.aiCreditsTotal,
              hint: 'Used for job descriptions and match explanations.',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: daysLeft < 14
                    ? AppTheme.signalAttentionWash
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: daysLeft < 14
                      ? AppTheme.signalAttention.withValues(alpha: 0.4)
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_repeat_outlined,
                      size: 18,
                      color: daysLeft < 14
                          ? AppTheme.signalAttention
                          : AppTheme.inkMutedOf(context)),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subscription',
                            style: AppTheme.sansBold(
                                fontSize: 13.5,
                                color: AppTheme.inkOf(context))),
                        Text('$daysLeft days remaining',
                            style: AppTheme.sansRegular(
                                fontSize: 12,
                                color: AppTheme.inkMutedOf(context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            if (provider.canPost)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PostJobWizardScreen()),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(Icons.add,
                      color: AppTheme.onPrimaryFillOf(context), size: 20),
                  label: Text('Post a vacancy',
                      style: AppTheme.sansBold(
                          fontSize: 15,
                          color: AppTheme.onPrimaryFillOf(context))),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VerificationPendingScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.hourglass_top_rounded,
                      color: AppTheme.signalAttention, size: 20),
                  label: Text('Awaiting Verification — Check Status',
                      style: AppTheme.sansBold(
                          fontSize: 14.5,
                          color: AppTheme.inkOf(context))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: AppTheme.sansBold(
                fontSize: 13.5, color: AppTheme.inkOf(context))),
      );
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
  final String? footnote;

  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.onTap,
    this.footnote,
  });
}

class _CardGrid extends StatelessWidget {
  final List<_Metric> cards;

  const _CardGrid({required this.cards});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (context, i) {
          final card = cards[i];
          return InkWell(
            onTap: card.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(card.icon, size: 19, color: card.tint),
                  const Spacer(),
                  Text(card.value,
                      style: AppTheme.serifTitle(
                          fontSize: 27, color: AppTheme.inkOf(context))),
                  Text(card.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sansMedium(
                          fontSize: 12.5,
                          color: AppTheme.inkMutedOf(context))),
                  if (card.footnote != null)
                    Text(card.footnote!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.sansRegular(
                            fontSize: 10, color: AppTheme.inkFaintOf(context))),
                ],
              ),
            ),
          );
        },
      );
}

class _PlanRow extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final String hint;

  const _PlanRow({
    required this.label,
    required this.used,
    required this.total,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final fraction = total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    final low = remaining <= total * 0.1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppTheme.sansBold(
                        fontSize: 13.5, color: AppTheme.inkOf(context))),
              ),
              Text('$remaining left',
                  style: AppTheme.sansBold(
                      fontSize: 13,
                      color: low
                          ? AppTheme.signalClosed
                          : AppTheme.signalPositive)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceOf(context),
              valueColor: AlwaysStoppedAnimation(
                  low ? AppTheme.signalClosed : AppTheme.signalSource),
            ),
          ),
          const SizedBox(height: 7),
          Text(hint,
              style: AppTheme.sansRegular(
                  fontSize: 11.5, color: AppTheme.inkFaintOf(context))),
        ],
      ),
    );
  }
}


/// Why publishing is unavailable, on the first screen a recruiter sees.
///
/// Without it the Post button simply produces drafts and nobody knows why —
/// which is how a gate that exists for a good reason reads as a broken app.
class _VerificationBanner extends StatelessWidget {
  final CompanyStatus status;

  const _VerificationBanner({required this.status});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerificationPendingScreen()),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.signalAttentionWash,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.signalAttention.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 18, color: AppTheme.signalAttention),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == CompanyStatus.draft
                          ? 'Finish registering to publish'
                          : 'Verification in progress',
                      style: AppTheme.sansBold(
                          fontSize: 13.5, color: AppTheme.inkOf(context)),
                    ),
                    Text(
                      'You can browse candidates and draft vacancies. They go '
                      'live once we have checked your company.',
                      style: AppTheme.sansRegular(
                          fontSize: 12.5,
                          color: AppTheme.inkMutedOf(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: AppTheme.inkMutedOf(context)),
            ],
          ),
        ),
      );
}
