import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/ledger_components.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
import '../jobs/post_job_wizard_screen.dart';

class EmployerDashboardTab extends StatefulWidget {
  const EmployerDashboardTab({super.key});

  @override
  State<EmployerDashboardTab> createState() => _EmployerDashboardTabState();
}

class _EmployerDashboardTabState extends State<EmployerDashboardTab> {
  int _notificationCount = 2;

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recruiter Alerts', style: AppTheme.sectionHeader()),
                    TextButton(
                      onPressed: () {
                        setState(() => _notificationCount = 0);
                        Navigator.pop(ctx);
                      },
                      child: Text('Mark all read', style: AppTheme.meta(color: AppTheme.signalProgress, size: 11)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.rule),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildAlertCard(
                      icon: Icons.person_add_alt_1_rounded,
                      iconColor: AppTheme.signalPositive,
                      washColor: AppTheme.signalPositiveWash,
                      title: 'New Candidate Applied',
                      body: 'Priya Raghunathan (91% AI Fit) applied for Senior Backend Engineer.',
                      time: '15 mins ago',
                    ),
                    const SizedBox(height: 10),
                    _buildAlertCard(
                      icon: Icons.event_available_rounded,
                      iconColor: AppTheme.signalProgress,
                      washColor: AppTheme.signalProgressWash,
                      title: 'Interview Confirmed',
                      body: 'Technical Interview confirmed for Friday with Wei Ling Tan.',
                      time: '1 hour ago',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAlertCard({
    required IconData icon,
    required Color iconColor,
    required Color washColor,
    required String title,
    required String body,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusRow),
        border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: washColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.rowTitle()),
                const SizedBox(height: 3),
                Text(body, style: AppTheme.body(size: 12)),
                const SizedBox(height: 6),
                MetaText(time),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // Top App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    LuckyBossBrandLogo(height: 32),
                    SizedBox(width: 8),
                    MetaText('Portal', color: AppTheme.ink),
                  ],
                ),
                IconButton(
                  onPressed: () => _showNotifications(context),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppTheme.ink, size: 22),
                      if (_notificationCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: AppTheme.signalClosed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_notificationCount',
                              style: AppTheme.meta(color: Colors.white, size: 8, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const BrandRule(),
            const SizedBox(height: 16),

            // Company Document Header Card
            Container(
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
                      const MetaText('Corporate ATS Workspace'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.signalPositiveWash,
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        ),
                        child: const MetaText('Verified', color: AppTheme.signalPositive, size: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(provider.companyName, style: AppTheme.screenTitle(size: 19)),
                  const SizedBox(height: 4),
                  Text(
                    'Regional recruitment pipeline across Singapore, Malaysia & India.',
                    style: AppTheme.body(size: 12),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppTheme.rule),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCreditStat(
                          'Contact Credits',
                          '${provider.contactCreditsRemaining}/${provider.contactCreditsTotal}',
                          provider.contactCreditsRemaining > 20 ? AppTheme.signalProgress : AppTheme.signalAttention,
                        ),
                      ),
                      Container(width: 1, height: 28, color: AppTheme.rule),
                      Expanded(
                        child: _buildCreditStat(
                          'AI Screenings',
                          '${provider.aiCreditsRemaining}/${provider.aiCreditsTotal}',
                          provider.aiCreditsRemaining > 10 ? AppTheme.signalPositive : AppTheme.signalAttention,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Ledger
            Row(
              children: [
                Expanded(child: _buildMetricTile('Active Jobs', '${provider.jobs.length}', AppTheme.ink)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile('Candidates', '${provider.applicants.length}', AppTheme.signalProgress)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile('Interviewing', '${provider.applicants.where((a) => a.status.contains('Interview')).length}', AppTheme.signalPositive)),
              ],
            ),
            const SizedBox(height: 20),

            // Action Card: Post Vacancy
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.paper,
                      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                      border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
                    ),
                    child: const Icon(Icons.add_business_rounded, color: AppTheme.ink, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Post a New Vacancy', style: AppTheme.rowTitle()),
                        const SizedBox(height: 2),
                        Text('Publish job with skill criteria', style: AppTheme.body(size: 11.5)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PostJobWizardScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ink,
                      foregroundColor: AppTheme.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusControl)),
                    ),
                    child: Text('Create', style: AppTheme.button(color: AppTheme.surface)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetaText(label, size: 9),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.score(size: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color inkColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusRow),
        border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetaText(label, size: 9.5),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.score(size: 20, color: inkColor)),
        ],
      ),
    );
  }
}