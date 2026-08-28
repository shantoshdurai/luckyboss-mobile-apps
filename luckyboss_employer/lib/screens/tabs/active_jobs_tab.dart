import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/employer_job.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/boost_sheet.dart';
import '../jobs/post_job_wizard_screen.dart';

/// The company's vacancies.
///
/// A card per job rather than a row, for the reason Shantosh gave about the
/// seeker app: a flat list reads as an archive, and these are live things a
/// recruiter acts on. The card carries what an employer checks at a glance —
/// how many candidates are waiting, what the job pays, and whether the posting
/// is actually visible to anybody.
class ActiveJobsTab extends StatelessWidget {
  final ValueChanged<String>? onOpenCandidates;

  const ActiveJobsTab({super.key, this.onOpenCandidates});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final jobs = provider.jobs;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostJobWizardScreen()),
        ),
        backgroundColor: AppTheme.primaryFillOf(context),
        icon: Icon(Icons.add, color: AppTheme.onPrimaryFillOf(context)),
        label: Text('Post a job',
            style: AppTheme.sansBold(
                fontSize: 14, color: AppTheme.onPrimaryFillOf(context))),
      ),
      body: SafeArea(
        child: jobs.isEmpty
            ? const _NoJobsYet()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
                children: [
                  Text('Your jobs',
                      style: AppTheme.serifTitle(
                          fontSize: 24, color: AppTheme.inkOf(context))),
                  const SizedBox(height: 4),
                  Text(
                    '${jobs.length} posted  ·  '
                    '${provider.activeJobsCount} live',
                    style: AppTheme.sansRegular(
                        fontSize: 13, color: AppTheme.inkMutedOf(context)),
                  ),
                  const SizedBox(height: 16),
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
  const _NoJobsYet();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_outline,
                  size: 42, color: AppTheme.inkFaintOf(context)),
              const SizedBox(height: 14),
              Text('No jobs posted yet',
                  textAlign: TextAlign.center,
                  style: AppTheme.serifTitle(
                      fontSize: 20, color: AppTheme.inkOf(context))),
              const SizedBox(height: 6),
              Text(
                'Post one and matching candidates appear straight away — there '
                'are already people in the Lucky Boss database for most trades.',
                textAlign: TextAlign.center,
                style: AppTheme.sansRegular(
                    fontSize: 13.5, color: AppTheme.inkMutedOf(context)),
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
