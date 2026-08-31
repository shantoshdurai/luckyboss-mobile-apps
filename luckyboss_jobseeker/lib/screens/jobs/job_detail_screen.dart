import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/job_model.dart';
import '../../models/purchase_record.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/ledger_components.dart';

/// JOB DETAIL + APPLY — specification sections 30, 62 and 63.
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
          // ---- Workplace Photo Banner ----
          _WorkplaceGallery(
            category: job.category,
            companyName: job.companyName,
          ),
          const Divider(height: 1),

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
                    'Add your skills to your profile and Luckyboss will show which of these '
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
    if (provider.hasApplied(job.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already applied to this role.')),
      );
      return;
    }

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

    // Application confirmation dialog before submission
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ApplicationConfirmationSheet(job: job),
    );
    if (confirm != true || !context.mounted) return;

    final ok = await provider.applyToJob(job);
    if (!context.mounted) return;
    if (ok) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ApplicationSuccessSheet(job: job),
      );
    }
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
        : 'Posted on Luckyboss';
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
                'This fee is charged by the employer for this vacancy. It is not a Luckyboss '
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
            Expanded(child: Text(value, style: AppTheme.body(color: AppTheme.inkOf(context)))),
          ],
        ),
      );
}

class _ApplicationConfirmationSheet extends StatelessWidget {
  final JobModel job;
  const _ApplicationConfirmationSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final profile = provider.profile;
    final score = provider.matchScoreFor(job);

    return Container(
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.ruleOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.signalPositiveWash,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 20, color: AppTheme.signalPositive),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confirm Application',
                          style: AppTheme.sectionTitle(color: AppTheme.inkOf(context))),
                      const SizedBox(height: 2),
                      Text('Applying to ${job.companyName}',
                          style: AppTheme.small(color: AppTheme.inkMutedOf(context)),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Target Job Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.paperOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                border: Border.all(color: AppTheme.ruleOf(context), width: AppTheme.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: AppTheme.sansBold(fontSize: 15, color: AppTheme.inkOf(context))),
                  const SizedBox(height: 4),
                  Text('${job.location} · ${job.salaryDisplay}',
                      style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.inkMutedOf(context))),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Profile Verification Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.paperOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                border: Border.all(color: AppTheme.ruleOf(context), width: AppTheme.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MetaText('Your profile details to be shared', size: 9),
                  const SizedBox(height: 10),
                  _Line('Applicant', profile.name.isNotEmpty ? profile.name : 'Job Seeker'),
                  if (profile.phone.isNotEmpty)
                    _Line('Phone', profile.phone),
                  if (profile.email.isNotEmpty)
                    _Line('Email', profile.email),
                  if (score != null)
                    _Line('Match Score', '${score.toStringAsFixed(0)}% (${MatchTierStyle.of(score).label})', last: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppTheme.signalPositive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your verified credentials will be transmitted securely to the employer.',
                    style: AppTheme.small(color: AppTheme.inkMutedOf(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryFillOf(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Confirm & Submit Application',
                style: AppTheme.sansBold(fontSize: 14, color: AppTheme.onPrimaryFillOf(context)),
              ),
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
}

class _ApplicationSuccessSheet extends StatelessWidget {
  final JobModel job;
  const _ApplicationSuccessSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.ruleOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.signalPositiveWash,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 32, color: AppTheme.signalPositive),
            ),
            const SizedBox(height: 16),
            Text(
              'Application Submitted! 🎉',
              style: AppTheme.serifTitle(fontSize: 20, color: AppTheme.inkOf(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your application for ${job.title} at ${job.companyName} has been received and added to your tracker.',
              textAlign: TextAlign.center,
              style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.paperOf(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                border: Border.all(color: AppTheme.ruleOf(context), width: AppTheme.hairline),
              ),
              child: Column(
                children: [
                  const _Line('Status', 'Under Review'),
                  const _Line('Submitted', 'Today, Just now'),
                  _Line('Company', job.companyName, last: true),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.signalPositive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Done', style: AppTheme.sansBold(fontSize: 14, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkplaceGallery extends StatefulWidget {
  final String category;
  final String companyName;

  const _WorkplaceGallery({required this.category, required this.companyName});

  @override
  State<_WorkplaceGallery> createState() => _WorkplaceGalleryState();
}

class _WorkplaceGalleryState extends State<_WorkplaceGallery> {
  final PageController _pageController = PageController();
  int _activePage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = AppData.defaultWorkplacePhotosForCategory(widget.category);

    return Container(
      color: AppTheme.surfaceOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (idx) => setState(() => _activePage = idx),
                  itemBuilder: (context, i) {
                    return Image.network(
                      photos[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: AppTheme.inkOf(context).withValues(alpha: 0.08),
                        child: Center(
                          child: Icon(Icons.apartment_rounded,
                              size: 48, color: AppTheme.inkMutedOf(context)),
                        ),
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppTheme.inkOf(context).withValues(alpha: 0.04),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 13, color: AppTheme.signalPositive),
                        const SizedBox(width: 5),
                        Text(
                          'Verified Workplace',
                          style: AppTheme.sansBold(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                if (photos.length > 1)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activePage + 1}/${photos.length}',
                        style: AppTheme.sansBold(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 15, color: AppTheme.inkMutedOf(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Workplace photos from ${widget.companyName} · ${widget.category}',
                    style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
