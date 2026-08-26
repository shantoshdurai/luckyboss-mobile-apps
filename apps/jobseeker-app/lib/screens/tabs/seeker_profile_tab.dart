import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_data.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/firebase_auth_service.dart';
import '../onboarding_screen.dart';

class SeekerProfileTab extends StatefulWidget {
  const SeekerProfileTab({super.key});

  @override
  State<SeekerProfileTab> createState() => _SeekerProfileTabState();
}

class _SeekerProfileTabState extends State<SeekerProfileTab> {
  bool _darkMode = false;
  bool _pushNotifications = true;

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'AM';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  void _showAddSkillDialog(BuildContext context, JobSeekerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Verified Skills', style: AppTheme.serifTitle(fontSize: 18, color: AppTheme.primaryNavy)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppData.verifiedSkillDictionary.map((skill) {
                  final isAdded = provider.profile.skills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isAdded,
                    selectedColor: AppTheme.primaryNavy,
                    labelStyle: AppTheme.sansSemiBold(
                      fontSize: 12,
                      color: isAdded ? Colors.white : AppTheme.textPrimary,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.addSkill(skill);
                      } else {
                        provider.removeSkill(skill);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                  decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Privacy & Data Protection', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
              const SizedBox(height: 8),
              Text('Last updated: August 2026', style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted)),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildLegalSection('1. Candidate Data Encryption', 'All resumes, contact information, and verification records are encrypted with Enterprise 256-bit AES encryption and hosted on compliant cloud infrastructure.'),
                    _buildLegalSection('2. Recruiter Visibility', 'Your verified profile is only shared with registered corporate employers whose vacancies match your skills. Contact details are masked until an interview is accepted.'),
                    _buildLegalSection('3. Cross-Border Compliance', 'Lucky Boss adheres to PDPA (Singapore), PDPA (Malaysia), and Digital Personal Data Protection Act (India).'),
                    _buildLegalSection('4. Right to Erasure', 'You can request deletion of all parsed data and resume files anytime through your account settings or by contacting privacy@luckyboss.global.'),
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

  Widget _buildLegalSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.primaryNavy)),
          const SizedBox(height: 4),
          Text(body, style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JobSeekerProvider>(context);
    final profile = provider.profile;
    final candidateName = profile.name.isNotEmpty ? profile.name : 'Arjun Mehta';
    final candidateEmail = profile.email.isNotEmpty ? profile.email : 'arjun.mehta@gmail.com';
    final candidatePhone = profile.phone.isNotEmpty ? profile.phone : '+91 98765-43210';
    final candidateBio = profile.bio.isNotEmpty
        ? profile.bio
        : 'Full-stack mobile engineer with 4+ years of experience building cross-platform applications using Flutter, Dart, and cloud-native backend services.';

    return Scaffold(
      backgroundColor: AppTheme.bgPaper,
      appBar: AppBar(
        title: Text('Candidate Profile', style: AppTheme.sansBold(fontSize: 18, color: AppTheme.primaryNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          // 1. Candidate Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(candidateName),
                          style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
                                  candidateName,
                                  style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppTheme.emerald, size: 18),
                            ],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            candidateEmail,
                            style: AppTheme.sansMedium(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                          Text(
                            candidatePhone,
                            style: AppTheme.sansBold(fontSize: 12, color: AppTheme.emeraldDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Profile Completion Meter
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppTheme.emeraldDark, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Profile Strength', style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.primaryNavy)),
                                Text('95% Verified', style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.emeraldDark)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: const LinearProgressIndicator(
                                value: 0.95,
                                backgroundColor: AppTheme.borderLight,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.emerald),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Uploaded Resume & AI Parsing Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Verified Resume', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('AI Parsed ✓', style: AppTheme.sansBold(fontSize: 11, color: AppTheme.emeraldDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgPaper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.resumeFileName ?? 'Arjun_Mehta_Resume_2026.pdf',
                              style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.primaryNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('Updated Today • 248 KB', style: AppTheme.sansRegular(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Resume preview opened.')),
                          );
                        },
                        child: Text('View', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.royalBlue)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Verified Skills Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Skills & Competencies', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
                    InkWell(
                      onTap: () => _showAddSkillDialog(context, provider),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 15, color: AppTheme.royalBlue),
                          const SizedBox(width: 4),
                          Text('Add Skill', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.royalBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgPaper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(skill, style: AppTheme.sansBold(fontSize: 12, color: AppTheme.primaryNavy)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Executive Bio
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
                Text('Executive Bio', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
                const SizedBox(height: 8),
                Text(
                  candidateBio,
                  style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Settings & App Preferences
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
                Text('App Preferences & Settings', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
                const SizedBox(height: 8),

                // Dark Mode Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dark / Night Mode', style: AppTheme.sansMedium(fontSize: 13.5, color: AppTheme.textPrimary)),
                  subtitle: Text('Switch between light and night theme', style: AppTheme.sansRegular(fontSize: 11.5, color: AppTheme.textMuted)),
                  value: _darkMode,
                  activeColor: AppTheme.emerald,
                  onChanged: (val) => setState(() => _darkMode = val),
                ),
                const Divider(height: 1),

                // Push Notifications
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Interview & Job Alerts', style: AppTheme.sansMedium(fontSize: 13.5, color: AppTheme.textPrimary)),
                  subtitle: Text('Receive real-time ATS shortlist alerts', style: AppTheme.sansRegular(fontSize: 11.5, color: AppTheme.textMuted)),
                  value: _pushNotifications,
                  activeColor: AppTheme.emerald,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
                const Divider(height: 1),

                // Privacy Policy
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryNavy, size: 20),
                  title: Text('Privacy Policy & Compliance', style: AppTheme.sansMedium(fontSize: 13.5, color: AppTheme.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  onTap: () => _showPrivacyPolicy(context),
                ),
                const Divider(height: 1),

                // Region / Country
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_rounded, color: AppTheme.primaryNavy, size: 20),
                  title: Text('Region & Currency', style: AppTheme.sansMedium(fontSize: 13.5, color: AppTheme.textPrimary)),
                  trailing: Text('India, SG, MY', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              label: Text('Sign Out', style: AppTheme.sansBold(fontSize: 14, color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await FirebaseAuthService.logout();
                provider.setAuthenticated(false);
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}