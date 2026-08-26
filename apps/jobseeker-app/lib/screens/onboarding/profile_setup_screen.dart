import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_data.dart';
import '../../models/seeker_profile_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../main_navigation_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;

  const ProfileSetupScreen({super.key, required this.phoneNumber});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 controllers
  final _nameController = TextEditingController(text: 'Arjun Mehta');
  final _emailController = TextEditingController(text: 'arjun.mehta@gmail.com');
  ExperienceLevel _selectedLevel = ExperienceLevel.mid;
  String _selectedCategory = 'IT & Software';

  // Step 2 state
  bool _isExtractingResume = false;
  bool _resumeExtracted = false;
  String? _resumeFileName;

  // Step 3 — uses provider profile directly

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _handleStep1Next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    provider.updateProfileBasicInfo(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      experienceLevel: _selectedLevel,
      preferredCategory: _selectedCategory,
    );

    _goToStep(1);
  }

  Future<void> _handleResumeUpload() async {
    setState(() {
      _isExtractingResume = true;
      _resumeFileName = 'Arjun_Mehta_Resume_2026.pdf';
    });

    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    await provider.parseResumeWithAI(_resumeFileName!);

    if (mounted) {
      setState(() {
        _isExtractingResume = false;
        _resumeExtracted = true;
      });
    }
  }

  void _handleSkipResume() {
    _goToStep(2);
  }

  void _handleResumeConfirmed() {
    _goToStep(2);
  }

  Future<void> _handleLaunchCareer() async {
    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    await provider.completeProfileSetup();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Stepper
            _buildStepper(),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2Resume(),
                  _buildStep3Review(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEPPER BAR ───────────────────────────────────────────────
  Widget _buildStepper() {
    final labels = ['Basic Info', 'Resume & AI', 'Review'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        children: [
          // Step indicator pills
          Row(
            children: List.generate(3, (i) {
              final isActive = i <= _currentStep;
              final isCurrent = i == _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.emerald : AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i],
                        style: AppTheme.sansSemiBold(
                          fontSize: 11.5,
                          color: isCurrent ? AppTheme.primaryNavy : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── STEP 1: BASIC INFO ────────────────────────────────────────
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verified phone pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.emeraldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldDark, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Verified: ${widget.phoneNumber}',
                    style: AppTheme.sansBold(fontSize: 12, color: AppTheme.emeraldDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Tell us about\nyourself',
              style: AppTheme.serifTitle(fontSize: 30, color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 6),
            Text(
              'This helps employers find you and Lucky AI to personalize your job matches.',
              style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),

            // Full Name
            _label('Full Name *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('e.g. Arjun Mehta', Icons.person_outline_rounded),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name' : null,
            ),
            const SizedBox(height: 18),

            // Email
            _label('Email Address *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('arjun.mehta@gmail.com', Icons.mail_outline_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Experience Level
            _label('Experience Level'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgPaper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: DropdownButtonFormField<ExperienceLevel>(
                initialValue: _selectedLevel,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.trending_up_rounded, color: AppTheme.textMuted, size: 20),
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
                items: ExperienceLevel.values.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level.displayLabel));
                }).toList(),
                onChanged: (v) => setState(() => _selectedLevel = v!),
              ),
            ),
            const SizedBox(height: 18),

            // Preferred Category
            _label('Preferred Job Category'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgPaper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textMuted, size: 20),
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
                items: AppData.categories.where((c) => c != 'All Roles').map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),

            const SizedBox(height: 36),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleStep1Next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue to Resume', style: AppTheme.sansBold(fontSize: 15, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2: RESUME UPLOAD & AI EXTRACTION ────────────────────
  Widget _buildStep2Resume() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload your resume',
            style: AppTheme.serifTitle(fontSize: 28, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 6),
          Text(
            'Lucky AI will instantly extract your skills, experience, and bio so you don\'t have to type it all.',
            style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),

          // Upload area
          if (!_resumeExtracted) ...[
            GestureDetector(
              onTap: _isExtractingResume ? null : _handleResumeUpload,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: _isExtractingResume
                      ? AppTheme.primaryNavy.withValues(alpha: 0.04)
                      : AppTheme.bgPaper,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isExtractingResume ? AppTheme.emerald : AppTheme.borderMedium,
                    width: _isExtractingResume ? 2 : 1.5,
                  ),
                ),
                child: _isExtractingResume
                    ? _buildExtractionLoading()
                    : Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.emerald.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.emerald, size: 30),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to upload PDF or DOC',
                            style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max 5 MB • Your data stays private',
                            style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Skip link
            Center(
              child: TextButton(
                onPressed: _handleSkipResume,
                child: Text(
                  'Skip — I\'ll add details manually',
                  style: AppTheme.sansSemiBold(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],

          // Extracted results
          if (_resumeExtracted) ...[
            _buildExtractionResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractionLoading() {
    return Column(
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.emerald),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Lucky AI is reading your resume…',
          style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy),
        ),
        const SizedBox(height: 4),
        Text(
          'Extracting skills, experience & bio',
          style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: const Duration(milliseconds: 1500),
      color: AppTheme.emerald.withValues(alpha: 0.15),
    );
  }

  Widget _buildExtractionResults() {
    final provider = Provider.of<JobSeekerProvider>(context);
    final profile = provider.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.emeraldLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldDark, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume parsed successfully',
                      style: AppTheme.sansBold(fontSize: 13, color: AppTheme.emeraldDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resumeFileName ?? 'resume.pdf',
                      style: AppTheme.sansRegular(fontSize: 11.5, color: AppTheme.emeraldDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 20),

        // AI Extraction heading
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.amber, size: 18),
            const SizedBox(width: 8),
            Text(
              'Lucky AI extracted the following',
              style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Please review and edit if anything looks off.',
          style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),

        // Extracted fields
        _extractedField('Name', profile.name, Icons.person_outline_rounded),
        _extractedField('Email', profile.email, Icons.mail_outline_rounded),
        _extractedField('Experience', profile.experienceLevel.displayLabel, Icons.trending_up_rounded),
        _extractedField('Category', profile.preferredCategory, Icons.category_outlined),

        const SizedBox(height: 16),

        // Skills
        Text('Skills', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profile.skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.royalBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.royalBlue.withValues(alpha: 0.2)),
              ),
              child: Text(skill, style: AppTheme.sansSemiBold(fontSize: 12, color: AppTheme.royalBlue)),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Bio
        Text('Bio', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Text(
            profile.bio.isNotEmpty ? profile.bio : 'No bio extracted',
            style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textPrimary, height: 1.5),
          ),
        ),

        const SizedBox(height: 32),

        // Confirm & continue
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleResumeConfirmed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text('Looks Good — Continue', style: AppTheme.sansBold(fontSize: 15, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _extractedField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.sansRegular(fontSize: 11, color: AppTheme.textMuted)),
                Text(value, style: AppTheme.sansSemiBold(fontSize: 13.5, color: AppTheme.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: REVIEW & CONFIRM ─────────────────────────────────
  Widget _buildStep3Review() {
    final provider = Provider.of<JobSeekerProvider>(context);
    final profile = provider.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything look right?',
            style: AppTheme.serifTitle(fontSize: 28, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 6),
          Text(
            'Review your profile before entering the app. You can always edit later.',
            style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),

          // Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar + Name
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(profile.name),
                          style: AppTheme.sansBold(fontSize: 20, color: Colors.white),
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
                                  profile.name.isNotEmpty ? profile.name : 'Your Name',
                                  style: AppTheme.sansBold(fontSize: 17, color: AppTheme.primaryNavy),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppTheme.emerald, size: 18),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.phone,
                            style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppTheme.borderLight, height: 1),
                const SizedBox(height: 16),

                // Detail rows
                _reviewRow(Icons.mail_outline_rounded, 'Email', profile.email),
                _reviewRow(Icons.trending_up_rounded, 'Experience', profile.experienceLevel.displayLabel),
                _reviewRow(Icons.category_outlined, 'Preferred', profile.preferredCategory),
                if (profile.resumeFileName != null)
                  _reviewRow(Icons.description_outlined, 'Resume', profile.resumeFileName!),

                const SizedBox(height: 16),

                // Skills
                if (profile.skills.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Skills', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.textMuted)),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: profile.skills.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s, style: AppTheme.sansSemiBold(fontSize: 11, color: AppTheme.emeraldDark)),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Bio', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.textMuted)),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      profile.bio,
                      style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textPrimary, height: 1.5),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Edit link
          Center(
            child: TextButton.icon(
              onPressed: () => _goToStep(0),
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.royalBlue),
              label: Text('Edit Details', style: AppTheme.sansSemiBold(fontSize: 13, color: AppTheme.royalBlue)),
            ),
          ),

          const SizedBox(height: 24),

          // Launch CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleLaunchCareer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Launch My Career', style: AppTheme.sansBold(fontSize: 16, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.rocket_launch_rounded, size: 20, color: AppTheme.emerald),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.sansSemiBold(fontSize: 13.5, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.sansRegular(fontSize: 14, color: AppTheme.textMuted),
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      fillColor: AppTheme.bgPaper,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
