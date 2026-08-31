import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/job_model.dart';
import '../providers/job_seeker_provider.dart';
import '../screens/jobs/job_detail_screen.dart';
import 'home_components.dart';
import 'ledger_components.dart';

/// A job, as a card.
///
/// The previous flat rows made a list of ten jobs read as one undifferentiated
/// block — nothing said where a listing started or ended. A card gives each
/// vacancy an edge, which is what lets the eye count them.
///
/// Apply sits at the bottom, across the full width, after every fact needed to
/// decide: title, employer, location, salary, source. A button placed before the
/// salary asks for a commitment the reader cannot yet make.
class JobCard extends StatelessWidget {
  final JobModel job;

  /// Compact form for horizontal carousels — drops the Apply button and the
  /// skill chips, since a card the user has to scroll sideways to reach should
  /// not also carry the primary action.
  final bool compact;

  const JobCard({super.key, required this.job, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final score = provider.matchScoreFor(job);
    final saved = provider.isSaved(job.id);
    final applied = provider.hasApplied(job.id);

    return Container(
      width: compact ? 268 : null,
      margin: EdgeInsets.symmetric(horizontal: compact ? 6 : 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The promotion mark, above the title so it is the first thing
              // read on the card — spec §61. It names the hiring situation
              // ("Urgent hiring") rather than announcing a payment, which is
              // both true and the part a candidate can use.
              if (job.isBoosted) ...[
                _BoostMark(label: job.boostLabel, type: job.boostType),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompanyMark(companyName: job.companyName, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: AppTheme.sansBold(
                              fontSize: 15, color: AppTheme.inkOf(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.companyName,
                          style: AppTheme.sansMedium(
                              fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!compact)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36),
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color:
                            saved ? AppTheme.signalPositive : AppTheme.inkFaintOf(context),
                      ),
                      tooltip: saved ? 'Saved' : 'Save job',
                      onPressed: () => provider.toggleSaved(job.id),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              _metaRow(context, Icons.location_on_outlined, job.location),
              const SizedBox(height: 6),
              _metaRow(
                context,
                Icons.payments_outlined,
                '${job.currency} ${job.minSalary} – ${job.maxSalary} / month',
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  _tag(context, job.workMode),
                  const SizedBox(width: 7),
                  if (job.source == JobSource.external && job.sourceName != null)
                    Flexible(child: _tag(context, job.sourceName!, muted: true))
                  else
                    _tag(context, 'Luckyboss', accent: true),
                  const Spacer(),
                  // The score is the app's own claim about this job, so it sits
                  // with the job's facts rather than in a separate column.
                  MatchCell(score: score),
                ],
              ),

              if (!compact) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: applied
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 17),
                          label: Text('Applied',
                              style: AppTheme.sansBold(
                                  fontSize: 14, color: AppTheme.signalPositive)),
                          style: OutlinedButton.styleFrom(
                            disabledForegroundColor: AppTheme.signalPositive,
                            side: const BorderSide(color: AppTheme.signalPositive),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => JobDetailScreen(job: job)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryFillOf(context),
                            foregroundColor: AppTheme.onPrimaryFillOf(context),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('View & apply',
                              style: AppTheme.sansBold(
                                  fontSize: 14, color: AppTheme.onInkOf(context))),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.inkFaintOf(context)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.inkMutedOf(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _tag(BuildContext context, String label,
          {bool accent = false, bool muted = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: accent
              ? AppTheme.signalPositiveWash
              : muted
                  ? AppTheme.signalSourceWash
                  : AppTheme.paperOf(context),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.sansMedium(
            fontSize: 10.5,
            color: accent
                ? AppTheme.signalPositive
                : muted
                    ? AppTheme.signalSource
                    : AppTheme.inkMutedOf(context),
          ),
        ),
      );
}

/// The mark on a promoted vacancy.
///
/// Kept quiet on purpose. A boosted job already wins by being first; a loud
/// badge on every third card would make the whole feed feel like advertising,
/// which costs the candidate's trust in all of it — including the boosted ones
/// the employer paid for.
class _BoostMark extends StatelessWidget {
  final String label;
  final String type;

  const _BoostMark({required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final (tint, wash, icon) = switch (type) {
      'urgent' => (
          AppTheme.signalClosed,
          AppTheme.signalClosedWash,
          Icons.bolt
        ),
      'sponsored' => (
          AppTheme.signalSource,
          AppTheme.signalSourceWash,
          Icons.campaign_outlined
        ),
      _ => (
          AppTheme.signalAttention,
          AppTheme.signalAttentionWash,
          Icons.star_rounded
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: wash, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 5),
          Text(label,
              style: AppTheme.sansBold(fontSize: 10.5, color: tint)),
        ],
      ),
    );
  }
}
