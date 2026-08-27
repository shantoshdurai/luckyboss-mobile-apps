import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/ledger_components.dart';
import '../auth/employer_login_screen.dart';

class CompanyProfileTab extends StatefulWidget {
  const CompanyProfileTab({super.key});

  @override
  State<CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<CompanyProfileTab> {
  bool _candidateAlerts = true;

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Corporate Compliance & ATS Data Policy', style: AppTheme.sectionHeader()),
              const SizedBox(height: 4),
              const MetaText('Applicable for Singapore, Malaysia & India'),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.rule),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text('• All candidate resumes are processed in isolated sandboxes with strict RBAC.', style: AppTheme.body()),
                    const SizedBox(height: 8),
                    Text('• SMS OTP & Firebase Phone Auth adheres to regional privacy and security standards.', style: AppTheme.body()),
                    const SizedBox(height: 8),
                    Text('• Candidate contact masking remains active until unlocked via contact credit or mutual review.', style: AppTheme.body()),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.ink,
                    foregroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusControl)),
                  ),
                  child: Text('Close', style: AppTheme.button(color: AppTheme.surface)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: AppTheme.surface,
            width: double.infinity,
            child: Text('Company Profile', style: AppTheme.screenTitle(size: 18)),
          ),
          const BrandRule(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // 1. Company Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                    border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
                  ),
                  child: const Center(
                    child: Icon(Icons.apartment_rounded, color: AppTheme.ink, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider.companyName,
                              style: AppTheme.rowTitle(size: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppTheme.signalPositive, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Headquarters: Singapore & Bengaluru', style: AppTheme.body(size: 12)),
                      const SizedBox(height: 2),
                      Text('talent@luckyboss.global', style: AppTheme.body(color: AppTheme.signalProgress, size: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Plan Tier Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.signalPositiveWash,
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppTheme.signalPositive, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enterprise Plan', style: AppTheme.rowTitle(size: 14)),
                      const SizedBox(height: 2),
                      Text('Full ATS Pipelines • Dual-Engine AI Screening', style: AppTheme.body(size: 11.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.signalPositiveWash,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: const MetaText('Active', color: AppTheme.signalPositive, size: 9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Settings & Preferences
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
                const MetaText('Recruiter Settings'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Applicant Alerts', style: AppTheme.rowTitle(size: 13.5)),
                          const SizedBox(height: 2),
                          Text('Notify instantly on high AI-fit candidates', style: AppTheme.body(size: 11.5)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _candidateAlerts,
                      activeColor: AppTheme.signalPositive,
                      onChanged: (val) => setState(() => _candidateAlerts = val),
                    ),
                  ],
                ),
                const Divider(height: 16, color: AppTheme.rule),
                InkWell(
                  onTap: () => _showPrivacyPolicy(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: AppTheme.ink, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Data Privacy & ATS Compliance', style: AppTheme.rowTitle(size: 13.5)),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Sign Out
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.signalClosed, size: 16),
              label: Text('Sign Out Recruiter Session', style: AppTheme.button(color: AppTheme.signalClosed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.signalClosedWash, width: 1.5),
                backgroundColor: AppTheme.signalClosedWash,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusControl)),
              ),
              onPressed: () {
                context.read<EmployerProvider>().setAuthenticated(false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployerLoginScreen()),
                  (route) => false,
                );
              },
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