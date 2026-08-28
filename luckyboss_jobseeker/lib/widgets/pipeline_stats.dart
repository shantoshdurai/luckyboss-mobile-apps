import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import '../screens/jobs/all_jobs_screen.dart';

/// Applied / Matches / Saved / Interviews / Offers.
///
/// Lives on the applications tab, not on home: every number here describes the
/// candidate's pipeline, which is what that tab is for.
///
/// All five are tappable. A tile reading "5 Matches" that does nothing when
/// pressed is worse than not showing the number — it advertises five jobs and
/// then refuses to name them. Each one now routes somewhere that answers the
/// question the number raises.
class PipelineStats extends StatelessWidget {
  /// Scrolls the applications list to a stage, for the counts that live on this
  /// same screen.
  final ValueChanged<String>? onFilterStage;

  const PipelineStats({super.key, this.onFilterStage});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();

    final tiles = <_StatTile>[
      _StatTile(
        label: 'Applied',
        value: provider.myApplications.length,
        icon: Icons.send_outlined,
        onTap: () => onFilterStage?.call('all'),
      ),
      _StatTile(
        label: 'Matches',
        value: provider.recommendedJobs.length,
        icon: Icons.auto_awesome_outlined,
        tone: AppTheme.signalSource,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AllJobsScreen(
              title: 'Your matches',
              source: JobListSource.recommended,
            ),
          ),
        ),
      ),
      _StatTile(
        label: 'Saved',
        value: provider.savedJobs.length,
        icon: Icons.bookmark_border,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AllJobsScreen(
              title: 'Saved jobs',
              source: JobListSource.saved,
            ),
          ),
        ),
      ),
      _StatTile(
        label: 'Interviews',
        value: provider.interviewCount,
        icon: Icons.event_available_outlined,
        tone: AppTheme.signalProgress,
        onTap: () => onFilterStage?.call('interview'),
      ),
      _StatTile(
        label: 'Offers',
        value: provider.offerCount,
        icon: Icons.workspace_premium_outlined,
        tone: AppTheme.signalPositive,
        onTap: () => onFilterStage?.call('offer'),
      ),
    ];

    return SizedBox(
      // 92 clipped the label by 6px once the chevron row was added.
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
        itemCount: tiles.length,
        itemBuilder: (context, i) => tiles[i].build(context),
      ),
    );
  }
}

/// One stat, as a card rather than a column in a divided row.
///
/// The old row put five numbers behind hairlines with no affordance at all.
/// Cards with an icon and a chevron read as things you can press, which is the
/// point — and a zero renders muted so an empty pipeline does not shout.
class _StatTile {
  final String label;
  final int value;
  final IconData icon;
  final Color? tone;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.tone,
  });

  Widget build(BuildContext context) {
    final active = value > 0;
    final colour = active ? (tone ?? AppTheme.inkOf(context)) : AppTheme.inkFaintOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 104,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
        decoration: BoxDecoration(
          color: active
              ? (tone ?? AppTheme.inkOf(context)).withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? (tone ?? AppTheme.inkOf(context)).withValues(alpha: 0.2)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: colour),
                const Spacer(),
                Icon(Icons.chevron_right, size: 15, color: AppTheme.inkFaintOf(context)),
              ],
            ),
            const Spacer(),
            Text('$value', style: AppTheme.score(size: 21, color: colour)),
            const SizedBox(height: 1),
            Text(
              label.toUpperCase(),
              style: AppTheme.sansBold(fontSize: 9, color: AppTheme.inkFaintOf(context))
                  .copyWith(letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
