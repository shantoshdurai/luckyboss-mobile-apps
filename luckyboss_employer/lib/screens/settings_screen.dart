import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/employer_job.dart';
import '../providers/employer_provider.dart';
import '../services/employer_insights_service.dart';
import 'auth/employer_login_screen.dart';
import '../widgets/reviewer_tools.dart';
import 'auth/verification_pending_screen.dart';

/// Settings.
///
/// Shantosh: *"we don't even have a dashboard for settings and stuff... we are
/// not having anything which we had in the job seeker app."* He was right —
/// the provider had a dark-mode toggle that no screen exposed, and there was no
/// way to sign out at all.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Null while loading, and still null if the server could not be reached —
  /// in which case the plan section falls back to what the device knows and
  /// says so, rather than presenting stale local counters as fact.
  EmployerInsights? _insights;
  bool _loadingInsights = true;

  @override
  void initState() {
    super.initState();
    EmployerInsightsService.overview().then((value) {
      if (mounted) {
        setState(() {
          _insights = value;
          _loadingInsights = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final company = provider.company;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text('Settings',
            style: AppTheme.sansBold(
                fontSize: 17, color: AppTheme.inkOf(context))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _VerificationCard(company: company),
          const SizedBox(height: 12),
          const ReviewerTools(),
          const SizedBox(height: 18),

          _section(context, 'Appearance'),
          _card(
            context,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: provider.isDarkMode,
              onChanged: provider.toggleDarkMode,
              title: Text('Dark mode',
                  style: AppTheme.sansSemiBold(
                      fontSize: 14.5, color: AppTheme.inkOf(context))),
              subtitle: Text('Easier on the eyes on a night shift.',
                  style: AppTheme.sansRegular(
                      fontSize: 12.5, color: AppTheme.inkMutedOf(context))),
            ),
          ),

          const SizedBox(height: 18),
          _section(context, 'Your plan'),
          _planCard(context, provider),

          const SizedBox(height: 18),
          _section(context, 'Your numbers'),
          _insightsCard(context),

          const SizedBox(height: 18),
          _section(context, 'Billing'),
          _BillingCard(provider: provider),

          const SizedBox(height: 18),
          _section(context, 'Account'),
          _card(
            context,
            child: Column(
              children: [
                _row(context, 'Company', company.name.isEmpty ? '—' : company.name),
                const Divider(height: 20),
                _row(context, 'Contact', company.email.isEmpty ? '—' : company.email),
                const Divider(height: 20),
                _row(context, 'Phone', company.phone.isEmpty ? '—' : company.phone),
                const Divider(height: 20),
                _row(context, 'Documents on file',
                    '${provider.documents.length}'),
              ],
            ),
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, provider),
              icon: const Icon(Icons.logout, size: 18,
                  color: AppTheme.signalClosed),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              label: Text('Sign out',
                  style: AppTheme.sansBold(
                      fontSize: 14.5, color: AppTheme.signalClosed)),
            ),
          ),
        ],
      ),
    );
  }

  /// The plan, read from the server.
  ///
  /// This used to render counters held on the handset, so an employer whose
  /// admin had changed their package still saw the old numbers, and a fresh
  /// install showed defaults that belonged to nobody. The server is the only
  /// thing that knows what a company is actually entitled to.
  Widget _planCard(BuildContext context, EmployerProvider provider) {
    if (_loadingInsights) {
      return _card(context,
          child: const SizedBox(
              height: 54,
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)))));
    }

    final i = _insights;

    if (i == null) {
      return _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan details unavailable offline',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.inkOf(context))),
            const SizedBox(height: 6),
            Text(
              'Connect to the internet to see what your subscription includes. '
              'Nothing is shown here rather than figures that may be out of date.',
              style: AppTheme.sansRegular(
                  fontSize: 13, color: AppTheme.inkMutedOf(context)),
            ),
          ],
        ),
      );
    }

    return _card(
      context,
      child: Column(
        children: [
          _row(context, 'Plan', i.planName),
          const Divider(height: 20),
          _row(
            context,
            'Renews in',
            i.planActive && i.daysRemaining != null
                ? '${i.daysRemaining} days'
                : 'No active subscription',
          ),
          const Divider(height: 20),
          _row(context, 'Job posts', i.jobPosts.label),
          const Divider(height: 20),
          _row(
            context,
            'AI tools',
            i.aiAvailable
                ? 'Included'
                : (i.aiUpgradeRequired ? 'Upgrade to unlock' : 'Switched off'),
          ),
        ],
      ),
    );
  }

  /// What the account has actually produced.
  ///
  /// Every figure is measured server-side. A zero means nothing has happened
  /// yet, and the note underneath says when counting began, so a new account
  /// does not read its empty numbers as a failure.
  Widget _insightsCard(BuildContext context) {
    if (_loadingInsights) {
      return _card(context, child: const SizedBox(height: 40));
    }

    final i = _insights;
    if (i == null) {
      return _card(
        context,
        child: Text(
          'Your numbers will appear when you are back online.',
          style: AppTheme.sansRegular(
              fontSize: 13, color: AppTheme.inkMutedOf(context)),
        ),
      );
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, 'Active jobs', '${i.activeJobs}'),
          const Divider(height: 20),
          _row(context, 'Applications received', '${i.applications}'),
          const Divider(height: 20),
          _row(context, 'Times your jobs were viewed', '${i.views}'),
          const Divider(height: 20),
          _row(context, 'Boosts running', '${i.activeBoosts}'),
          if (i.boostSpend > 0) ...[
            const Divider(height: 20),
            _row(context, 'Spent on boosts',
                '${i.currency} ${(i.boostSpend / 100).toStringAsFixed(2)}'),
          ],
          if (i.views == 0) ...[
            const SizedBox(height: 12),
            Text(
              i.trackingSince == null
                  ? 'View counting has just been switched on, so this starts from today.'
                  : 'No views recorded yet.',
              style: AppTheme.sansRegular(
                  fontSize: 12, color: AppTheme.inkMutedOf(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 9, left: 2),
        child: Text(title.toUpperCase(),
            style: AppTheme.sansBold(
                    fontSize: 10, color: AppTheme.inkFaintOf(context))
                .copyWith(letterSpacing: 0.6)),
      );

  Widget _card(BuildContext context, {required Widget child}) => Container(
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: child,
      );

  Widget _row(BuildContext context, String label, String value) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkOf(context))),
          ),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sansSemiBold(
                    fontSize: 13.5, color: AppTheme.inkMutedOf(context))),
          ),
        ],
      );

  Future<void> _confirmSignOut(
      BuildContext context, EmployerProvider provider) async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out?',
            style: AppTheme.sansBold(
                fontSize: 16, color: AppTheme.inkOf(context))),
        // Said plainly. On a standalone build this is not a session ending —
        // it is the company's data leaving the handset, and somebody expecting
        // to sign back in to their jobs would be badly surprised.
        content: Text(
          'Your jobs, pipeline and documents are stored on this phone and will '
          'be removed. You would need to register again.',
          style: AppTheme.sansRegular(
              fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Stay',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalClosed)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await provider.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmployerLoginScreen()),
      (route) => false,
    );
  }
}

/// Verification state, at the top of settings because it decides what the rest
/// of the app will let this company do.
class _VerificationCard extends StatelessWidget {
  final CompanyProfile company;

  const _VerificationCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final (tint, wash, icon) = switch (company.status) {
      CompanyStatus.verified => (
          AppTheme.signalPositive,
          AppTheme.signalPositiveWash,
          Icons.verified
        ),
      CompanyStatus.rejected => (
          AppTheme.signalClosed,
          AppTheme.signalClosedWash,
          Icons.error_outline
        ),
      CompanyStatus.draft => (
          AppTheme.inkMutedOf(context),
          AppTheme.surfaceOf(context),
          Icons.edit_outlined
        ),
      _ => (
          AppTheme.signalAttention,
          AppTheme.signalAttentionWash,
          Icons.hourglass_top_rounded
        ),
    };

    return InkWell(
      onTap: company.status == CompanyStatus.verified
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const VerificationPendingScreen()),
              ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: wash,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.status.label,
                      style: AppTheme.sansBold(
                          fontSize: 14, color: AppTheme.inkOf(context))),
                  const SizedBox(height: 2),
                  Text(
                    switch (company.status) {
                      CompanyStatus.verified =>
                        'Your jobs are visible to candidates.',
                      CompanyStatus.rejected => company.reviewNote ??
                          'Tap to see what we need from you.',
                      CompanyStatus.draft =>
                        'Finish registering to publish your jobs.',
                      _ => 'Your jobs stay as drafts until we finish checking.',
                    },
                    style: AppTheme.sansRegular(
                        fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the company has been charged, spec §66.
///
/// Shown in full rather than as a total. A boost is the first thing in this app
/// that takes money, and an employer who cannot see the individual charges will
/// not trust the next one.
class _BillingCard extends StatelessWidget {
  final EmployerProvider provider;

  const _BillingCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final charges = provider.charges;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (charges.isEmpty)
            Text(
              'Nothing charged yet. Boosting a job is the only paid action '
              'right now, and the price is shown before you buy.',
              style: AppTheme.sansRegular(
                  fontSize: 13, color: AppTheme.inkMutedOf(context)),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text('Total spent',
                      style: AppTheme.sansBold(
                          fontSize: 14, color: AppTheme.inkOf(context))),
                ),
                Text('${charges.first.currency} ${provider.totalSpent}',
                    style: AppTheme.sansBold(
                        fontSize: 15, color: AppTheme.inkOf(context))),
              ],
            ),
            const Divider(height: 22),
            for (final charge in charges.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(charge.description,
                              style: AppTheme.sansMedium(
                                  fontSize: 13,
                                  color: AppTheme.inkOf(context))),
                          Text(
                            '${charge.chargedAt.day}/${charge.chargedAt.month}/'
                            '${charge.chargedAt.year}',
                            style: AppTheme.sansRegular(
                                fontSize: 11.5,
                                color: AppTheme.inkFaintOf(context)),
                          ),
                        ],
                      ),
                    ),
                    Text('${charge.currency} ${charge.amount}',
                        style: AppTheme.sansSemiBold(
                            fontSize: 13,
                            color: AppTheme.inkMutedOf(context))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
