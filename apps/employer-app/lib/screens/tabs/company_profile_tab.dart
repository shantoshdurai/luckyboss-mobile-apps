import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';
import '../auth/employer_login_screen.dart';

class CompanyProfileTab extends StatefulWidget {
  const CompanyProfileTab({super.key});

  @override
  State<CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<CompanyProfileTab> {
  bool _darkMode = false;
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Corporate Compliance & ATS Data Policy', style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy)),
              const SizedBox(height: 8),
              Text('Applicable for Singapore, Malaysia & India', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    Text('• All candidate resumes are processed in isolated sandboxes with strict RBAC.', style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    Text('• SMS OTP & Firebase Phone Auth adheres to Google Play Store and Blaze Billing SLAs.', style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    Text('• Candidate contact masking remains active until mutual interview acceptance.', style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
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
    final provider = Provider.of<EmployerProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgPaper,
      appBar: AppBar(
        title: Text('Company Profile', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          // 1. Company Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                provider.companyName,
                                style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppTheme.emerald, size: 18),
                            ],
                          ),
                          Text('Headquarters: Singapore & Bengaluru', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                          Text('talent@luckyboss.global', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emerald)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Plan Tier Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.navy,
                  const Color(0xFF1E293B),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.flash_on_rounded, color: AppTheme.emeraldLight, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enterprise Plan', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Firebase Blaze • Unlimited ATS Pipelines', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.emerald, borderRadius: BorderRadius.circular(8)),
                  child: Text('Active', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Settings & Preferences
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recruiter Settings', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dark / Night Mode', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text('Toggle recruiter workspace theme', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted)),
                  value: provider.isDarkMode,
                  activeTrackColor: AppTheme.emerald,
                  onChanged: (val) => provider.toggleDarkMode(val),
                ),
                const Divider(height: 1),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('New Applicant Alerts', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text('Notify instantly on high AI-fit candidates', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted)),
                  value: _candidateAlerts,
                  activeColor: AppTheme.emerald,
                  onChanged: (val) => setState(() => _candidateAlerts = val),
                ),
                const Divider(height: 1),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.security_rounded, color: AppTheme.navy, size: 20),
                  title: Text('Data Privacy & ATS Compliance', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Sign Out
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              label: Text('Sign Out Recruiter Session', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
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
    );
  }
}