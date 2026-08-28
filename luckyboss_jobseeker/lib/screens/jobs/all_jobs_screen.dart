import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/job_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/home_components.dart';
import '../../widgets/job_card.dart';
import '../../widgets/ledger_components.dart';

/// Which list a full-screen job view is showing.
enum JobListSource { recommended, external, saved }

/// The full list behind a "View all".
///
/// This exists because "View all" previously jumped to the search screen, which
/// is a different thing entirely: the candidate asked to see the rest of a list
/// they were already reading and was handed an empty search box. Following a
/// link should show more of what you were looking at.
class AllJobsScreen extends StatelessWidget {
  final String title;
  final JobListSource source;

  const AllJobsScreen({
    super.key,
    required this.title,
    required this.source,
  });

  List<JobModel> _jobs(JobSeekerProvider provider) => switch (source) {
        JobListSource.recommended => provider.recommendedJobs,
        JobListSource.external => provider.externalJobs,
        JobListSource.saved => provider.savedJobs,
      };

  String get _emptyHeadline => switch (source) {
        JobListSource.recommended => 'No matches right now',
        JobListSource.external => 'No partner listings today',
        JobListSource.saved => 'You have not saved anything yet',
      };

  String get _emptyExplanation => switch (source) {
        JobListSource.recommended =>
          'Add more skills and preferences and matches start appearing immediately.',
        JobListSource.external =>
          'External vacancies come from authorised recruitment partners.',
        JobListSource.saved =>
          'Tap the bookmark on any job to keep it here for later.',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobSeekerProvider>();
    final jobs = _jobs(provider);

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: AppTheme.sansBold(fontSize: 16, color: AppTheme.inkOf(context))),
            Text(
              '${jobs.length} ${jobs.length == 1 ? "job" : "jobs"}',
              style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.inkFaintOf(context)),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: jobs.isEmpty
          ? LedgerEmptyState(
              headline: _emptyHeadline,
              explanation: _emptyExplanation,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: jobs.length + 1,
              itemBuilder: (context, i) {
                if (i == jobs.length) {
                  return const ListEndCap(
                    message: "That's the full list.",
                  );
                }
                return FadeInUp(index: i, child: JobCard(job: jobs[i]));
              },
            ),
    );
  }
}
