import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/employer_job.dart';
import '../providers/employer_provider.dart';

/// One thing worth a recruiter's attention.
class _Alert {
  final IconData icon;
  final Color tint;
  final String title;
  final String detail;
  final DateTime when;
  final VoidCallback? onTap;

  const _Alert({
    required this.icon,
    required this.tint,
    required this.title,
    required this.detail,
    required this.when,
    this.onTap,
  });
}

/// Notifications, spec §55.
///
/// Derived from state rather than stored, which is the honest thing to build
/// before FCM exists. Every row here is a fact the app can already see — a new
/// applicant nobody has opened, an interview arranged, a subscription running
/// out, a vacancy stuck as a draft because the company is not verified.
///
/// The alternative was the seeker app's placeholder: a screen that says
/// "nothing here yet" whatever is happening. That is fine when the app truly
/// knows nothing, and misleading here, where it knows plenty.
///
/// When FCM lands (spec §47–53), pushed alerts merge into this list rather than
/// replacing it — a recruiter should not have to remember whether something
/// arrived as a push to find it again.
class EmployerNotificationsScreen extends StatelessWidget {
  final VoidCallback? onOpenCandidates;
  final VoidCallback? onOpenJobs;

  const EmployerNotificationsScreen({
    super.key,
    this.onOpenCandidates,
    this.onOpenJobs,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final alerts = _build(context, provider);

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: AppTheme.sansBold(
                fontSize: 17, color: AppTheme.inkOf(context))),
      ),
      body: alerts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 40, color: AppTheme.inkFaintOf(context)),
                    const SizedBox(height: 14),
                    Text('Nothing needs you right now',
                        style: AppTheme.serifTitle(
                            fontSize: 19, color: AppTheme.inkOf(context))),
                    const SizedBox(height: 6),
                    Text(
                      'New applicants, interviews and anything expiring will '
                      'show up here.',
                      textAlign: TextAlign.center,
                      style: AppTheme.sansRegular(
                          fontSize: 13.5,
                          color: AppTheme.inkMutedOf(context)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              itemCount: alerts.length,
              itemBuilder: (context, i) => _AlertRow(alert: alerts[i]),
            ),
    );
  }

  /// Everything worth surfacing, most urgent first.
  List<_Alert> _build(BuildContext context, EmployerProvider provider) {
    final alerts = <_Alert>[];
    final now = DateTime.now();

    // Verification first — it is the thing blocking everything else.
    if (!provider.canPost) {
      alerts.add(_Alert(
        icon: Icons.hourglass_top_rounded,
        tint: AppTheme.signalAttention,
        title: provider.company.status == CompanyStatus.draft
            ? 'Finish registering your company'
            : 'Verification in progress',
        detail: 'Your vacancies stay as drafts until Lucky Boss has checked '
            'your company.',
        when: now,
        onTap: onOpenJobs,
      ));
    }

    final drafts =
        provider.jobs.where((j) => j.status == JobStatus.draft).toList();
    if (drafts.isNotEmpty) {
      alerts.add(_Alert(
        icon: Icons.edit_note,
        tint: AppTheme.inkMutedOf(context),
        title: '${drafts.length} vacancy'
            '${drafts.length == 1 ? '' : ' drafts'} not yet live',
        detail: drafts.map((j) => j.title).take(3).join(', '),
        when: drafts.first.postedDate,
        onTap: onOpenJobs,
      ));
    }

    // New applicants, per job, so a recruiter knows which site to look at.
    for (final job in provider.publishedJobs) {
      final fresh = provider
          .candidatesFor(job.id, source: CandidateSource.applied)
          .where((c) => c.status == 'New')
          .toList();
      if (fresh.isEmpty) continue;
      alerts.add(_Alert(
        icon: Icons.person_add_alt,
        tint: AppTheme.signalPositive,
        title: '${fresh.length} new applicant'
            '${fresh.length == 1 ? '' : 's'} for ${job.title}',
        detail: fresh.take(3).map((c) => c.name).join(', '),
        when: fresh
            .map((c) => c.appliedDate)
            .reduce((a, b) => a.isAfter(b) ? a : b),
        onTap: onOpenCandidates,
      ));
    }

    // Strong matches nobody has looked at. This is the alert that earns the
    // subscription — somebody good is sitting in the database unopened.
    for (final job in provider.publishedJobs) {
      final strong = provider
          .candidatesFor(job.id, source: CandidateSource.recommended)
          .where((c) => c.status == 'New' && c.matchFor(job) >= 75)
          .toList();
      if (strong.isEmpty) continue;
      alerts.add(_Alert(
        icon: Icons.auto_awesome_outlined,
        tint: AppTheme.signalProgress,
        title: '${strong.length} strong match'
            '${strong.length == 1 ? '' : 'es'} for ${job.title}',
        detail: 'In the Lucky Boss database and not yet contacted.',
        when: now,
        onTap: onOpenCandidates,
      ));
    }

    if (provider.interviewsCount > 0) {
      alerts.add(_Alert(
        icon: Icons.event_outlined,
        tint: AppTheme.signalSource,
        title: '${provider.interviewsCount} candidate'
            '${provider.interviewsCount == 1 ? '' : 's'} at interview stage',
        detail: 'Move them on or record the outcome.',
        when: now,
        onTap: onOpenCandidates,
      ));
    }

    if (provider.offersPendingCount > 0) {
      alerts.add(_Alert(
        icon: Icons.drafts_outlined,
        tint: AppTheme.signalProgress,
        title: '${provider.offersPendingCount} offer'
            '${provider.offersPendingCount == 1 ? '' : 's'} pending',
        detail: 'Waiting on a reply.',
        when: now,
        onTap: onOpenCandidates,
      ));
    }

    final daysLeft =
        provider.subscriptionExpiry.difference(now).inDays;
    if (daysLeft <= 30) {
      alerts.add(_Alert(
        icon: Icons.event_repeat_outlined,
        tint: daysLeft <= 7 ? AppTheme.signalClosed : AppTheme.signalAttention,
        title: 'Subscription ends in $daysLeft days',
        detail: 'Your jobs stop showing to candidates when it lapses.',
        when: now,
      ));
    }

    if (provider.contactCreditsRemaining <= provider.contactCreditsTotal * 0.1) {
      alerts.add(_Alert(
        icon: Icons.contact_phone_outlined,
        tint: AppTheme.signalClosed,
        title: '${provider.contactCreditsRemaining} contact credits left',
        detail: 'You will not be able to reveal candidate details without them.',
        when: now,
      ));
    }

    return alerts;
  }
}

class _AlertRow extends StatelessWidget {
  final _Alert alert;

  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alert.onTap == null
            ? null
            : () {
                Navigator.pop(context);
                alert.onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: alert.tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(alert.icon, size: 17, color: alert.tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title,
                        style: AppTheme.sansBold(
                            fontSize: 14, color: AppTheme.inkOf(context))),
                    const SizedBox(height: 2),
                    Text(alert.detail,
                        style: AppTheme.sansRegular(
                            fontSize: 12.5,
                            color: AppTheme.inkMutedOf(context))),
                  ],
                ),
              ),
              if (alert.onTap != null)
                Icon(Icons.chevron_right,
                    size: 18, color: AppTheme.inkFaintOf(context)),
            ],
          ),
        ),
      ),
    );
  }
}
