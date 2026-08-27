import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/job_seeker_provider.dart';

class MyApplicationsTab extends StatelessWidget {
  const MyApplicationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JobSeekerProvider>(context);
    final applications = provider.myApplications;

    return Scaffold(
      backgroundColor: AppTheme.bgPaper,
      appBar: AppBar(
        title: Text('Application Pipeline', style: AppTheme.sansBold(fontSize: 18, color: AppTheme.primaryNavy)),
      ),
      body: applications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 54, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No active applications yet.', style: AppTheme.serifTitle(fontSize: 18, color: AppTheme.primaryNavy)),
                  const SizedBox(height: 6),
                  Text('Apply to cross-border roles to track your hiring status.', style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              itemCount: applications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final app = applications[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                                Text(
                                  app.jobTitle,
                                  style: AppTheme.serifTitle(fontSize: 18, color: AppTheme.primaryNavy),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  app.companyName,
                                  style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              app.stageTitle,
                              style: AppTheme.sansBold(fontSize: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 4-Stage Stepper
                      Row(
                        children: [
                          _buildStepNode('Applied', 0, app.stageStepIndex),
                          _buildStepLine(0, app.stageStepIndex),
                          _buildStepNode('Shortlist', 1, app.stageStepIndex),
                          _buildStepLine(1, app.stageStepIndex),
                          _buildStepNode('Interview', 2, app.stageStepIndex),
                          _buildStepLine(2, app.stageStepIndex),
                          _buildStepNode('Offer', 3, app.stageStepIndex),
                        ],
                      ),

                      if (app.interviewSchedule != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, color: AppTheme.emeraldDark, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  app.interviewSchedule!,
                                  style: AppTheme.sansBold(fontSize: 12, color: AppTheme.emeraldDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (app.recruiterRemarks != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          app.recruiterRemarks!,
                          style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStepNode(String label, int stepIndex, int currentStageIndex) {
    final isDone = currentStageIndex >= stepIndex;
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppTheme.primaryNavy : Colors.white,
            border: Border.all(color: isDone ? AppTheme.primaryNavy : AppTheme.borderMedium, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: AppTheme.sansBold(fontSize: 11, color: AppTheme.textMuted),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTheme.sansBold(
            fontSize: 10.5,
            color: isDone ? AppTheme.primaryNavy : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int leftIndex, int currentStageIndex) {
    final isDone = currentStageIndex > leftIndex;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 2,
        color: isDone ? AppTheme.primaryNavy : AppTheme.borderLight,
      ),
    );
  }
}