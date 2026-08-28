import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/application_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/ledger_components.dart';
import '../../widgets/pipeline_stats.dart';

/// MY APPLICATIONS — what I sent, and what happened to it.
///
/// The thing a job seeker actually wants from this screen is not a list. It is
/// an answer to "did anything move?" So every row carries its position in the
/// pipeline as a timeline the seeker can read at a glance, and the sections are
/// ordered active-first: a live interview matters more than a rejection from
/// three weeks ago.
///
/// Uses the same status vocabulary and the same six stage colours as the
/// employer app, because they are describing the same pipeline. A candidate
/// reading "Shortlisted" and a recruiter setting "Shortlisted" should be
/// looking at the same word in the same ink.
class MyApplicationsTab extends StatelessWidget {
  const MyApplicationsTab({super.key});

  static const _pipeline = ['Applied', 'Shortlisted', 'Interview', 'Offer'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final all = provider.myApplications;

    final active = all.where((a) => a.stage != ApplicationStage.rejected).toList();
    final closed = all.where((a) => a.stage == ApplicationStage.rejected).toList();

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title only. The old header stacked an eyebrow, a title, a
            // summary strip and five stat tiles before a single application —
            // four bands of furniture above the content the screen is for.
            Container(
              color: AppTheme.paperOf(context),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('My applications',
                        style: AppTheme.screenTitle()),
                  ),
                  if (all.isNotEmpty)
                    Text(
                      '${all.length} total',
                      style: AppTheme.sansMedium(
                          fontSize: 13, color: AppTheme.inkFaintOf(context)),
                    ),
                ],
              ),
            ),
            // Stats only once there is a pipeline to describe. Five zeroes
            // above an empty-state that already says "no applications yet" is
            // the same message twice.
            if (all.isNotEmpty) const PipelineStats(),
            const BrandRule(),
            Expanded(
              child: all.isEmpty
                  ? const LedgerEmptyState(
                      headline: 'No applications yet',
                      explanation:
                          'Everything you apply to appears here, and you can follow each one '
                          'from applied through to an offer.',
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final a in active) ...[
                          _ApplicationCard(application: a),
                          const Divider(height: 1),
                        ],
                        if (closed.isNotEmpty) ...[
                          Container(
                            color: AppTheme.paperOf(context),
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                            child: MetaText('Closed — ${closed.length}'),
                          ),
                          for (final a in closed) ...[
                            _ApplicationCard(application: a, dimmed: true),
                            const Divider(height: 1),
                          ],
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================


class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final bool dimmed;

  const _ApplicationCard({required this.application, this.dimmed = false});

  /// Same status strings the employer app sets, so both sides of the pipeline
  /// use one vocabulary.
  String get _status {
    switch (application.stage) {
      case ApplicationStage.applied:
        return 'New';
      case ApplicationStage.shortlisted:
        return 'Shortlisted';
      case ApplicationStage.interview:
        return 'Interview Scheduled';
      case ApplicationStage.offer:
        return 'Offer Sent';
      case ApplicationStage.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = application.stage == ApplicationStage.rejected;
    final titleColor = dimmed ? AppTheme.inkMutedOf(context) : AppTheme.ink;

    return Container(
      color: dimmed ? AppTheme.paperOf(context) : AppTheme.surfaceOf(context),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
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
                    Text(application.jobTitle,
                        style: AppTheme.sectionTitle(color: titleColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('${application.companyName} · ${application.location}',
                        style: AppTheme.small(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              MatchCell(score: application.matchScore),
            ],
          ),
          const SizedBox(height: 13),

          // The timeline. Rejected applications do not get one — showing a
          // half-filled progress bar for something that ended is a small cruelty
          // and tells the seeker nothing useful.
          if (!rejected) _Timeline(stepIndex: application.stageStepIndex),
          if (!rejected) const SizedBox(height: 13),

          Row(
            children: [
              StagePill(_status),
              const SizedBox(width: 10),
              Flexible(
                child: MetaText('Applied ${_ago(application.appliedDate)}', size: 9),
              ),
            ],
          ),

          if (application.interviewSchedule != null) ...[
            const SizedBox(height: 10),
            _Callout(
              icon: Icons.event_outlined,
              color: AppTheme.signalProgress,
              wash: AppTheme.signalProgressWash,
              text: application.interviewSchedule!,
            ),
          ],
          if (application.recruiterRemarks != null && !rejected) ...[
            const SizedBox(height: 8),
            Text(application.recruiterRemarks!, style: AppTheme.small()),
          ],
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 30) return '$days days ago';
    return '${(days / 30).floor()} months ago';
  }
}

/// Applied → Shortlisted → Interview → Offer, as four segments.
///
/// Segments rather than dots: a seeker reads "how far along am I", and a filled
/// bar answers that faster than counting circles.
class _Timeline extends StatelessWidget {
  final int stepIndex;
  const _Timeline({required this.stepIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < MyApplicationsTab._pipeline.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= stepIndex ? AppTheme.signalProgress : AppTheme.ruleOf(context),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < MyApplicationsTab._pipeline.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: MetaText(
                  MyApplicationsTab._pipeline[i],
                  size: 8,
                  color: i <= stepIndex ? AppTheme.signalProgress : AppTheme.inkFaintOf(context),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color wash;
  final String text;

  const _Callout({
    required this.icon,
    required this.color,
    required this.wash,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration:
            BoxDecoration(color: wash, borderRadius: BorderRadius.circular(AppTheme.radiusRow)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTheme.small(color: color))),
          ],
        ),
      );
}
