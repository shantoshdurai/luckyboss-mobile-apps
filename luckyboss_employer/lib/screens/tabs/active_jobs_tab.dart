import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/ledger_components.dart';

class ActiveJobsTab extends StatelessWidget {
  const ActiveJobsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final jobs = provider.jobs;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: AppTheme.surface,
            width: double.infinity,
            child: Text('Active Job Postings', style: AppTheme.screenTitle(size: 18)),
          ),
          const BrandRule(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: jobs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                final isPublished = job.status.toLowerCase() == 'published';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: AppTheme.rowTitle(size: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPublished ? AppTheme.signalPositiveWash : AppTheme.rule,
                              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: MetaText(
                              job.status,
                              color: isPublished ? AppTheme.signalPositive : AppTheme.inkMuted,
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${job.location} · ${job.salaryDisplay}',
                        style: AppTheme.body(size: 12),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.rule),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 16, color: AppTheme.inkMuted),
                              const SizedBox(width: 6),
                              Text('${job.applicantsCount}', style: AppTheme.score(size: 13)),
                              const SizedBox(width: 4),
                              const MetaText('Applicants', size: 10),
                            ],
                          ),
                          Text('Manage Posting →', style: AppTheme.button()),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}