import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_data.dart';
import '../../models/job_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/lucky_boss_brand_logo.dart';

class ExploreJobsTab extends StatefulWidget {
  const ExploreJobsTab({super.key});

  @override
  State<ExploreJobsTab> createState() => _ExploreJobsTabState();
}

class _ExploreJobsTabState extends State<ExploreJobsTab> {
  String _selectedWorkMode = 'All'; // All, Remote, Hybrid, On-site

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryNavy, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Notifications',
                          style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Mark All Read', style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.emeraldDark)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNotificationCard(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppTheme.emerald,
                      title: 'Interview Scheduled — Lucky Boss Tech',
                      body: 'Technical interview for Lead AI & Mobile Flutter Engineer scheduled for Friday, 28 Aug 2026 at 02:30 PM (Google Meet).',
                      time: '10 mins ago',
                      isUnread: true,
                    ),
                    const SizedBox(height: 10),
                    _buildNotificationCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppTheme.royalBlue,
                      title: 'Profile Shortlisted — Tuas Port Logistics',
                      body: 'Your profile has been reviewed by the Senior Hiring Team for Senior Warehouse Operations Lead.',
                      time: '2 hours ago',
                      isUnread: true,
                    ),
                    const SizedBox(height: 10),
                    _buildNotificationCard(
                      icon: Icons.auto_awesome,
                      iconColor: AppTheme.amber,
                      title: 'Lucky AI Matched 4 New Jobs',
                      body: '4 new high-paying Flutter & Full Stack openings in Bengaluru & Singapore match your verified skills.',
                      time: '1 day ago',
                      isUnread: false,
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

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? AppTheme.bgPaper : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnread ? AppTheme.emerald.withValues(alpha: 0.3) : AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.primaryNavy),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppTheme.emerald, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(time, style: AppTheme.sansMedium(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<JobSeekerProvider>(
          builder: (context, provider, _) {
            final isApplied = provider.hasApplied(job.id);

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Company Pill & Verified Employer Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.bgPaper,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.business_rounded, size: 14, color: AppTheme.primaryNavy),
                                  const SizedBox(width: 6),
                                  Text(job.companyName, style: AppTheme.sansBold(fontSize: 12, color: AppTheme.primaryNavy)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified, size: 13, color: AppTheme.emeraldDark),
                                  const SizedBox(width: 4),
                                  Builder(
                                    builder: (context) {
                                      final matchPct = job.calculateAiMatchPercent(provider.profile.skills, provider.profile.preferredCategory);
                                      return Text(
                                        provider.profile.skills.isNotEmpty ? '${matchPct.round()}% AI Fit' : '0% AI Fit',
                                        style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.emeraldDark),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Text(
                          job.title,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Specs Grid (Salary, Work Mode, Location, Type)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgPaper,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSpecItem(
                                      icon: Icons.payments_outlined,
                                      label: 'Compensation',
                                      value: job.salaryDisplay,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSpecItem(
                                      icon: Icons.location_on_outlined,
                                      label: 'Location',
                                      value: job.location,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSpecItem(
                                      icon: Icons.laptop_chromebook_rounded,
                                      label: 'Work Mode',
                                      value: job.workMode,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSpecItem(
                                      icon: Icons.schedule_rounded,
                                      label: 'Job Type',
                                      value: 'Full-Time Direct',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // AI Fit Breakdown Card (Dynamically computed from candidate skills)
                        Builder(
                          builder: (context) {
                            final skillMatch = job.getTechnicalSkillsMatch(provider.profile.skills);
                            final categoryMatch = (provider.profile.preferredCategory == job.category) ? 95.0 : 25.0;
                            final countryMatch = (provider.selectedCountry == job.countryCode) ? 100.0 : 80.0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.emerald.withValues(alpha: 0.08),
                                    AppTheme.primaryNavy.withValues(alpha: 0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, color: AppTheme.emeraldDark, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Lucky AI Compatibility Breakdown',
                                        style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildFitMeter('Technical Skills Alignment', skillMatch / 100.0, '${skillMatch.round()}%'),
                                  const SizedBox(height: 6),
                                  _buildFitMeter('Experience & Seniority Fit', categoryMatch / 100.0, '${categoryMatch.round()}%'),
                                  const SizedBox(height: 6),
                                  _buildFitMeter('Cross-Border Compliance & Location', countryMatch / 100.0, '${countryMatch.round()}%'),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Role Overview
                        Text('Role Overview & Scope', style: AppTheme.serifTitle(fontSize: 18, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 8),
                        Text(
                          job.description,
                          style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 20),

                        // Day to Day Responsibilities
                        Text('Key Responsibilities', style: AppTheme.serifTitle(fontSize: 18, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 8),
                        _buildBulletPoint('Architect scalable, clean mobile user interfaces using Flutter & Dart.'),
                        _buildBulletPoint('Integrate real-time cloud services, Firebase authentication, and REST APIs.'),
                        _buildBulletPoint('Collaborate with cross-functional product and design teams in high-speed sprints.'),
                        _buildBulletPoint('Ensure cross-platform performance, crash-free rates, and Play Store standards.'),
                        const SizedBox(height: 20),

                        // Required Competencies
                        Text('Required Competencies', style: AppTheme.serifTitle(fontSize: 18, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.requiredSkills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.bgPaper,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Text(skill, style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.primaryNavy)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),

                        // About Employer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgPaper,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About ${job.companyName}', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
                              const SizedBox(height: 4),
                              Text(
                                'Verified Employer on the Lucky Boss Global Recruitment Network. Backed by corporate hiring compliance across Singapore, Malaysia, and India.',
                                style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Bottom Sticky CTA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppTheme.borderLight)),
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isApplied
                              ? null
                              : () {
                                  provider.applyToJob(job);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppTheme.emeraldDark,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Application submitted to ${job.companyName}!',
                                              style: AppTheme.sansBold(fontSize: 13, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isApplied ? AppTheme.borderMedium : AppTheme.primaryNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            isApplied ? 'Application Submitted ✓' : '1-Click Quick Apply →',
                            style: AppTheme.sansBold(fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpecItem({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.sansRegular(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value, style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFitMeter(String title, double progress, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTheme.sansRegular(fontSize: 11.5, color: AppTheme.textPrimary)),
            Text(percent, style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.emeraldDark)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emerald),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppTheme.emerald),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JobSeekerProvider>(context);
    final jobs = provider.filteredJobs.where((j) {
      if (_selectedWorkMode == 'All') return true;
      if (_selectedWorkMode == 'Remote') return j.workMode.toLowerCase().contains('remote');
      if (_selectedWorkMode == 'Hybrid') return j.workMode.toLowerCase().contains('hybrid');
      if (_selectedWorkMode == 'On-site') return j.workMode.toLowerCase().contains('on-site');
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Lucky Boss Brand Logo + Notification Bell + Country Pill
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo
                  const LuckyBossBrandLogo(height: 28),

                  // Actions: Notifications & Country Pill
                  Row(
                    children: [
                      // Notification Bell with Badge
                      IconButton(
                        onPressed: () => _showNotifications(context),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryNavy, size: 24),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                child: Text('3', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Country / Currency Dropdown Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgPaper,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedCountry,
                            items: AppData.countries.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['code'],
                                child: Row(
                                  children: [
                                    Text(c['flag']!, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Text('${c['code']} (${c['currency']})', style: AppTheme.sansBold(fontSize: 11, color: AppTheme.primaryNavy)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) provider.setCountry(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Greeting Row with Candidate Name & Verified Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Text('Good Morning 👋 ', style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textMuted)),
                  Text(
                    provider.profile.name.isNotEmpty ? provider.profile.name : 'Arjun Mehta',
                    style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.verified, color: AppTheme.emerald, size: 16),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: provider.setSearchQuery,
                style: AppTheme.sansMedium(fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search roles, skills, or companies...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: AppTheme.bgPaper,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryNavy)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Work Mode Filter Pills (All, Remote, Hybrid, On-site)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildModeChip('All', 'All Modes'),
                  _buildModeChip('Remote', '🌐 Remote'),
                  _buildModeChip('Hybrid', '🏢 Hybrid'),
                  _buildModeChip('On-site', '📍 On-site'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Role Categories Filter Pills
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: AppData.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = AppData.categories[index];
                  final isSelected = provider.selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryNavy,
                    backgroundColor: AppTheme.bgPaper,
                    labelStyle: AppTheme.sansBold(
                      fontSize: 11.5,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: isSelected ? AppTheme.primaryNavy : AppTheme.borderLight),
                    onSelected: (_) => provider.setCategory(cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Job Listings Feed
            Expanded(
              child: jobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off_outlined, size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text('No vacancies match your filter', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
                          const SizedBox(height: 4),
                          Text('Try selecting "All Modes" or "All Roles"', style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final isApplied = provider.hasApplied(job.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _showJobDetails(context, job),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
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
                                              job.title,
                                              style: GoogleFonts.cormorantGaramond(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryNavy,
                                                height: 1.15,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              job.companyName,
                                              style: AppTheme.sansSemiBold(fontSize: 12.5, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          final matchPct = job.calculateAiMatchPercent(provider.profile.skills, provider.profile.preferredCategory);
                                          final hasSkills = provider.profile.skills.isNotEmpty;
                                          final isHighMatch = matchPct >= 50;

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isHighMatch
                                                  ? AppTheme.emerald.withValues(alpha: 0.12)
                                                  : AppTheme.primaryNavy.withValues(alpha: 0.06),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              hasSkills ? '${matchPct.round()}% Fit' : '0% Fit',
                                              style: AppTheme.sansBold(
                                                fontSize: 11.5,
                                                color: isHighMatch ? AppTheme.emeraldDark : AppTheme.textSecondary,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Text(
                                    job.salaryDisplay,
                                    style: AppTheme.sansBold(fontSize: 15, color: AppTheme.primaryNavy),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      Text(
                                        '${job.location} • ${job.workMode}',
                                        style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                      const Spacer(),
                                      Text(
                                        isApplied ? 'Applied ✓' : 'Apply Now →',
                                        style: AppTheme.sansBold(
                                          fontSize: 12.5,
                                          color: isApplied ? AppTheme.emeraldDark : AppTheme.primaryNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String modeKey, String label) {
    final isSelected = _selectedWorkMode == modeKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primaryNavy,
        backgroundColor: AppTheme.bgPaper,
        labelStyle: AppTheme.sansBold(
          fontSize: 11,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: isSelected ? AppTheme.primaryNavy : AppTheme.borderLight),
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedWorkMode = modeKey),
      ),
    );
  }
}