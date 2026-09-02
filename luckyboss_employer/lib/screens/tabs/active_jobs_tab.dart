import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_data.dart';
import '../../core/theme/app_theme.dart';
import '../jobs/job_insights_screen.dart';
import '../../models/employer_job.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/boost_sheet.dart';
import '../auth/verification_pending_screen.dart';
import '../jobs/post_job_wizard_screen.dart';

/// The company's vacancies.
class ActiveJobsTab extends StatelessWidget {
  final ValueChanged<String>? onOpenCandidates;
  final VoidCallback? onMenu;

  const ActiveJobsTab({super.key, this.onOpenCandidates, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final jobs = provider.jobs;
    final canPost = provider.canPost;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostJobWizardScreen()),
              ),
              backgroundColor: AppTheme.primaryFillOf(context),
              icon: Icon(Icons.add, color: AppTheme.onPrimaryFillOf(context)),
              label: Text('Post a job',
                  style: AppTheme.sansBold(
                      fontSize: 14, color: AppTheme.onPrimaryFillOf(context))),
            )
          : null,
      body: SafeArea(
        child: jobs.isEmpty
            ? _NoJobsYet(canPost: canPost)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
                children: [
                  Row(
                    children: [
                      if (onMenu != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40),
                          onPressed: onMenu,
                          tooltip: 'Menu',
                          icon: Icon(Icons.menu,
                              color: AppTheme.inkOf(context)),
                        ),
                      Text('Your jobs',
                          style: AppTheme.serifTitle(
                              fontSize: 24, color: AppTheme.inkOf(context))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${jobs.length} posted  ·  '
                    '${provider.activeJobsCount} live',
                    style: AppTheme.sansRegular(
                        fontSize: 13, color: AppTheme.inkMutedOf(context)),
                  ),
                  const SizedBox(height: 16),
                  if (!canPost) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.signalAttentionWash,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.signalAttention.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded,
                              size: 18, color: AppTheme.signalAttention),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your company is awaiting verification. Job posting unlocks once approved.',
                              style: AppTheme.sansMedium(
                                  fontSize: 12.5, color: AppTheme.inkOf(context)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VerificationPendingScreen()),
                            ),
                            child: Text('Review',
                                style: AppTheme.sansBold(
                                    fontSize: 12.5, color: AppTheme.signalAttention)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Boosted first, exactly as candidates see them — an
                  // employer who has paid for the top slot should be able to
                  // see that it worked without leaving the app.
                  for (final job in provider.rankedJobs)
                    _JobCard(
                      job: job,
                      candidateCount: provider.countFor(job.id),
                      onTap: () => onOpenCandidates?.call(job.id),
                    ),
                  for (final job in jobs)
                    if (job.status != JobStatus.published)
                      _JobCard(
                        job: job,
                        candidateCount: provider.countFor(job.id),
                        onTap: () => onOpenCandidates?.call(job.id),
                      ),
                ],
              ),
      ),
    );
  }
}

class _NoJobsYet extends StatelessWidget {
  final bool canPost;
  const _NoJobsYet({this.canPost = false});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: canPost
                      ? AppTheme.signalSourceWash
                      : AppTheme.signalAttentionWash,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  canPost ? Icons.work_outline : Icons.hourglass_top_rounded,
                  size: 32,
                  color: canPost
                      ? AppTheme.signalSource
                      : AppTheme.signalAttention,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                canPost ? 'No jobs posted yet' : 'Verification in progress',
                textAlign: TextAlign.center,
                style: AppTheme.serifTitle(
                    fontSize: 20, color: AppTheme.inkOf(context)),
              ),
              const SizedBox(height: 8),
              Text(
                canPost
                    ? 'Post your first vacancy to start receiving verified matching candidates.'
                    : 'Your company registration is awaiting verification by Luckyboss. Job posting unlocks the moment your company is approved.',
                textAlign: TextAlign.center,
                style: AppTheme.sansRegular(
                    fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
              ),
              const SizedBox(height: 22),
              if (!canPost)
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VerificationPendingScreen()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.signalAttention,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text('Check Verification Status',
                      style: AppTheme.sansBold(fontSize: 13.5, color: Colors.white)),
                )
              else
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PostJobWizardScreen()),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Post a vacancy',
                      style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.onPrimaryFillOf(context))),
                ),
            ],
          ),
        ),
      );
}

class _JobCard extends StatelessWidget {
  final EmployerJobModel job;
  final int candidateCount;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.candidateCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = AppData.categoryByName(job.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.signalSource.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(category?.icon ?? Icons.work_outline,
                        size: 20, color: AppTheme.signalSource),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.sansBold(
                                fontSize: 15.5,
                                color: AppTheme.inkOf(context))),
                        // Who posted it. The field existed on the model and
                        // was rendered nowhere, so a job card named no
                        // employer at all — which is also what a candidate
                        // would have seen.
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.companyName.isEmpty
                                    ? 'No company name set'
                                    : job.companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.sansSemiBold(
                                  fontSize: 12.5,
                                  color: job.companyName.isEmpty
                                      ? AppTheme.signalClosed
                                      : AppTheme.inkMutedOf(context),
                                ),
                              ),
                            ),
                            if (job.companyVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  size: 13, color: AppTheme.signalPositive),
                            ],
                          ],
                        ),
                        Text(
                          job.vacancies > 1
                              ? '${job.category}  ·  ${job.vacancies} positions'
                              : job.category,
                          style: AppTheme.sansRegular(
                              fontSize: 11.5,
                              color: AppTheme.inkFaintOf(context)),
                        ),
                      ],
                    ),
                  ),
                  if (job.isBoosted)
                    BoostBadge(type: job.boost!.type)
                  else
                    _StatusPill(status: job.status),
                ],
              ),
              const SizedBox(height: 12),
              _line(context, Icons.place_outlined, job.location),
              const SizedBox(height: 5),
              _line(context, Icons.payments_outlined, job.salaryDisplay),
              if (job.requiredCertificates.isNotEmpty) ...[
                const SizedBox(height: 5),
                _line(context, Icons.badge_outlined,
                    'Requires ${job.requiredCertificates.join(', ')}'),
              ],
              if (job.benefits.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final benefit in job.benefits)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.signalPositiveWash,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(benefit,
                            style: AppTheme.sansBold(
                                fontSize: 10.5,
                                color: AppTheme.signalPositive)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Performance sits directly above the boost control on purpose:
              // the employer deciding whether to pay for a boost, and the one
              // asking what the last boost did, are the same person at the same
              // moment. Selling a boost and never reporting on it is the gap
              // this closes.
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobInsightsScreen(
                        jobId: int.tryParse(job.id) ?? 0,
                        jobTitle: job.title,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.insights_outlined, size: 16),
                  label: Text('See how this job is doing',
                      style: AppTheme.sansBold(
                          fontSize: 13, color: AppTheme.royalBlue)),
                ),
              ),
              // The boost control sits on the card because that is where an
              // employer decides one job matters more than the others.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => BoostSheet.open(context, job),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                  icon: Icon(
                      job.isBoosted ? Icons.bolt : Icons.trending_up,
                      size: 16,
                      color: job.isBoosted
                          ? AppTheme.signalPositive
                          : AppTheme.royalBlue),
                  label: Text(
                    job.isBoosted
                        ? '${job.boost!.daysRemaining} days of boost left'
                        : 'Boost to the top',
                    style: AppTheme.sansBold(
                        fontSize: 12.5,
                        color: job.isBoosted
                            ? AppTheme.signalPositive
                            : AppTheme.royalBlue),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 17, color: AppTheme.inkOf(context)),
                    const SizedBox(width: 8),
                    Text(
                      candidateCount == 0
                          ? 'No matching candidates yet'
                          : '$candidateCount matching '
                              '${candidateCount == 1 ? 'candidate' : 'candidates'}',
                      style: AppTheme.sansBold(
                          fontSize: 13.5, color: AppTheme.inkOf(context)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward,
                        size: 15, color: AppTheme.inkMutedOf(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.inkFaintOf(context)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sansMedium(
                    fontSize: 12.5, color: AppTheme.inkMutedOf(context))),
          ),
        ],
      );
}

class _StatusPill extends StatelessWidget {
  final JobStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, wash) = switch (status) {
      JobStatus.published => (AppTheme.signalPositive, AppTheme.signalPositiveWash),
      JobStatus.draft => (AppTheme.inkMutedOf(context), AppTheme.surfaceOf(context)),
      JobStatus.paused => (AppTheme.signalAttention, AppTheme.signalAttentionWash),
      JobStatus.closed => (AppTheme.signalClosed, AppTheme.signalClosedWash),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: wash, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: AppTheme.sansBold(fontSize: 10.5, color: color)),
    );
  }
}
