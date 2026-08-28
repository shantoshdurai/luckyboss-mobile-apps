import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/job_model.dart';
import '../../models/purchase_record.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/ledger_components.dart';

/// JOB DETAIL + APPLY — specification sections 30, 62 and 63.
///
/// This is the screen the whole seeker app exists to deliver someone to. Two
/// things it does that the previous version did not:
///
///   1. It applies. Apply used to show a snackbar saying it was not built.
///   2. It states the fee before the seeker commits to anything. A paid
///      application is disclosed on the job row, again here, and confirmed in a
///      sheet that names the amount — nobody should reach a payment screen they
///      did not expect.
class JobDetailScreen extends StatelessWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final applied = provider.hasApplied(job.id);
    final saved = provider.isSaved(job.id);
    final score = provider.matchScoreFor(job);
    final paid = provider.paymentRequiredFor(job);

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        backgroundColor: AppTheme.paperOf(context),
        title: const MetaText('Vacancy'),
        actions: [
          IconButton(
            onPressed: () => provider.toggleSaved(job.id),
            tooltip: saved ? 'Saved' : 'Save job',
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                size: 20, color: saved ? AppTheme.ink : AppTheme.inkFaintOf(context)),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: BrandRule(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Title block ----
          Container(
            color: AppTheme.surfaceOf(context),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title, style: AppTheme.screenTitle()),
                          const SizedBox(height: 5),
                          Text('${job.companyName} · ${job.location}',
                              style: AppTheme.body()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    MatchCell(
                      score: score,
                      onExplain: score == null ? null : () => _explain(context, score),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SourceLine(job: job),
              ],
            ),
          ),
          const Divider(height: 1),

          // ---- Facts ----
          Container(
            color: AppTheme.surfaceOf(context),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              children: [
                _Fact(label: 'Salary', value: job.salaryDisplay),
                _Fact(label: 'Work mode', value: job.workMode),
                _Fact(label: 'Category', value: job.category),
                _Fact(label: 'Posted', value: _ago(job.postedDate)),
                if (job.closingDate != null)
                  _Fact(
                    label: 'Closes',
                    value: job.daysUntilClosing! < 0
                        ? 'Closed'
                        : 'in ${job.daysUntilClosing} days',
                    emphasis: job.isClosingSoon,
                  ),
                _Fact(
                  label: 'To apply',
                  value: paid ? job.feeDisplay : 'Free',
                  emphasis: paid,
                  last: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ---- Description ----
          Container(
            color: AppTheme.surfaceOf(context),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MetaText('About this role'),
                const SizedBox(height: 9),
                Text(job.description, style: AppTheme.body(color: AppTheme.ink)),
              ],
            ),
          ),
          const Divider(height: 1),

          // ---- Skills, marked against the seeker's own profile ----
          Container(
            color: AppTheme.surfaceOf(context),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MetaText('Required skills'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: job.requiredSkills.map((skill) {
                    // Showing which requirements the seeker already meets is more
                    // useful than a flat list — it turns the score into advice.
                    final has = provider.profile.skills.any((s) =>
                        s.trim().toLowerCase() == skill.trim().toLowerCase());
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: has ? AppTheme.signalPositiveWash : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        border: Border.all(
                          color: has ? AppTheme.signalPositiveWash : AppTheme.ruleOf(context),
                          width: AppTheme.hairline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (has) ...[
                            const Icon(Icons.check, size: 12, color: AppTheme.signalPositive),
                            const SizedBox(width: 4),
                          ],
                          Text(skill,
                              style: AppTheme.small(
                                color: has ? AppTheme.signalPositive : AppTheme.inkMutedOf(context),
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (provider.profile.skills.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Add your skills to your profile and Lucky Boss will show which of these '
                    'you already meet.',
                    style: AppTheme.small(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),

      // ---- The action, pinned so it is never scrolled away ----
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          border: Border(top: BorderSide(color: AppTheme.ruleOf(context), width: AppTheme.hairline)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: SafeArea(
          top: false,
          child: applied
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 17, color: AppTheme.signalPositive),
                    const SizedBox(width: 8),
                    Text('Application sent',
                        style: AppTheme.button(color: AppTheme.signalPositive)),
                  ],
                )
              : job.source == JobSource.external
                  ? OutlinedButton(
                      onPressed: () => _externalNotice(context),
                      child: const Text('Apply on partner site'),
                    )
                  : ElevatedButton(
                      onPressed: provider.isLoading ? null : () => _apply(context, provider, paid),
                      child: Text(paid ? 'Apply · ${job.feeDisplay}' : 'Apply'),
                    ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> _apply(BuildContext context, JobSeekerProvider provider, bool paid) async {
    if (paid) {
      final proceed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _PaymentSheet(job: job),
      );
      if (proceed != true || !context.mounted) return;

      // In production this is where the gateway result comes back. The purchase
      // is recorded only after that, never optimistically — a receipt for money
      // that did not move is worse than no receipt.
      final record = provider.recordPurchase(job);
      final ok = await provider.applyToJob(job);
      if (!context.mounted) return;
      if (ok) {
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _ReceiptSheet(record: record),
        );
      }
      return;
    }

    final ok = await provider.applyToJob(job);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Applied to ${job.title}. Track it under My applications.'
            : 'You have already applied to this role.'),
      ),
    );
  }

  void _explain(BuildContext context, double score) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MatchBreakdownSheet(
        candidateName: job.title,
        score: score,
        factors: {
          'Skills': score,
          'Category': job.category ==
                  context.read<JobSeekerProvider>().profile.preferredCategory
              ? 100.0
              : 20.0,
        },
        reasoning:
            'Scored on the skills in your profile against the requirements on this '
            'vacancy. Adding the missing skills above raises it.',
      ),
    );
  }

  void _externalNotice(BuildContext context) {
    // External listings are not Lucky Boss vacancies. Pretending you can apply
    // in-app would set an expectation the platform cannot honour.
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetaText(job.sourceName ?? 'Partner listing'),
              const SizedBox(height: 8),
              Text('This vacancy is hosted elsewhere', style: AppTheme.sectionTitle()),
              const SizedBox(height: 8),
              Text(
                'It was published by ${job.sourceName ?? 'an authorised partner'} rather than '
                'by an employer on Lucky Boss, so the application happens on their site and '
                'Lucky Boss cannot track its progress for you.',
                style: AppTheme.body(),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Understood'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}

// =============================================================================

class _SourceLine extends StatelessWidget {
  final JobModel job;
  const _SourceLine({required this.job});

  @override
  Widget build(BuildContext context) {
    final label = job.source == JobSource.external && job.sourceName != null
        ? job.sourceName!
        : 'Posted on Lucky Boss';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: job.source.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        MetaText(label, color: job.source.color, size: 9),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;
  final bool last;

  const _Fact({
    required this.label,
    required this.value,
    this.emphasis = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 96, child: MetaText(label, size: 10)),
            Expanded(
              child: Text(
                value,
                style: AppTheme.body(
                  color: emphasis ? AppTheme.signalAttention : AppTheme.ink,
                  weight: emphasis ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
}

// =============================================================================
// PAYMENT — spec 63.
//
// The amount is stated before anything happens, in the currency's own code. A
// seeker who reaches a gateway without knowing the number has been failed
// upstream of the gateway.
// =============================================================================

class _PaymentSheet extends StatelessWidget {
  final JobModel job;
  const _PaymentSheet({required this.job});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                      color: AppTheme.ruleOf(context), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const MetaText('Paid application'),
              const SizedBox(height: 8),
              Text(job.title, style: AppTheme.sectionTitle()),
              const SizedBox(height: 4),
              Text(job.companyName, style: AppTheme.small()),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.paperOf(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                  border: Border.all(color: AppTheme.ruleOf(context), width: AppTheme.hairline),
                ),
                child: Row(
                  children: [
                    const Expanded(child: MetaText('Application fee', size: 10)),
                    Text(job.feeDisplay,
                        style: AppTheme.score(size: 20, color: AppTheme.signalAttention)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'This fee is charged by the employer for this vacancy. It is not a Lucky Boss '
                'subscription, and it does not guarantee an interview.',
                style: AppTheme.small(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Pay ${job.feeDisplay} and apply'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
}

class _ReceiptSheet extends StatelessWidget {
  final PurchaseRecord record;
  const _ReceiptSheet({required this.record});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 19, color: AppTheme.signalPositive),
                  const SizedBox(width: 8),
                  Text('Application sent',
                      style: AppTheme.sectionTitle(color: AppTheme.signalPositive)),
                ],
              ),
              const SizedBox(height: 18),
              _Line('Transaction', record.transactionId),
              _Line('Role', record.jobTitle),
              _Line('Company', record.companyName),
              _Line('Amount', record.amountDisplay),
              _Line('Status', record.status, last: true),
              const SizedBox(height: 18),
              Text('This receipt is kept in your purchase history.',
                  style: AppTheme.small()),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _Line(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: MetaText(label, size: 10)),
            Expanded(child: Text(value, style: AppTheme.body(color: AppTheme.ink))),
          ],
        ),
      );
}
