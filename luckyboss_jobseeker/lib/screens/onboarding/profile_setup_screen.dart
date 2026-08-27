import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_data.dart';
import '../../models/seeker_profile_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
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

  // Step 1 Form Controllers (Clean & Empty)
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  ExperienceLevel _selectedLevel = ExperienceLevel.mid;
  String _selectedCategory = 'IT & Software';
  final _formKeyStep1 = GlobalKey<FormState>();

  // Step 2 State (0 = Resume Upload view, 1 = Manual Entry view)
  int _step2SubView = 0;
  bool _isExtractingResume = false;
  bool _resumeUploaded = false;
  String? _uploadedFileName;

  // Manual & Extracted Skills & Bio
  final List<String> _selectedSkills = [];
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillSearchController = TextEditingController();
  final TextEditingController _customSkillController = TextEditingController();
  String _skillSearchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _skillSearchController.dispose();
    _customSkillController.dispose();
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
    String name = _nameController.text.trim();
    if (name.isEmpty) name = 'Alex Rivera';
    String email = _emailController.text.trim();
    if (email.isEmpty) email = 'alex.rivera@luckyboss.com';

    _nameController.text = name;
    _emailController.text = email;

    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    provider.updateProfileBasicInfo(
      name: name,
      email: email,
      experienceLevel: _selectedLevel,
      preferredCategory: _selectedCategory,
    );

    _goToStep(1);
  }

  void _promptResumeUpload() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _executeResumeExtraction('Resume_${DateTime.now().year}.pdf');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.bgPaper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderMedium, width: 1.5, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open_rounded, size: 48, color: AppTheme.royalBlue),
                      const SizedBox(height: 12),
                      Text('Tap to browse files', style: AppTheme.sansBold(fontSize: 16, color: AppTheme.primaryNavy)),
                      const SizedBox(height: 4),
                      Text('Select PDF or DOCX from your device', style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeResumeExtraction(String fileName) async {
    setState(() {
      _isExtractingResume = true;
      _uploadedFileName = fileName.isNotEmpty ? fileName : 'Resume_2026.pdf';
    });

    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    await provider.parseResumeWithAI(_uploadedFileName!);

    // Populate skills & bio from provider
    _selectedSkills.clear();
    _selectedSkills.addAll(provider.profile.skills);
    _bioController.text = provider.profile.bio;

    if (mounted) {
      setState(() {
        _isExtractingResume = false;
        _resumeUploaded = true;
      });
    }
  }

  void _handleStep2Next() {
    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    provider.setSkills(_selectedSkills);
    provider.updateBio(_bioController.text.trim());
    provider.updateResume(_uploadedFileName);
    _goToStep(2);
  }

  // --- Push Notification Permission Prompt ---
  void _showNotificationPermissionModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.notifications_active_rounded, size: 32, color: AppTheme.emeraldDark),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Enable Instant Job & Interview Alerts',
                style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Allow Lucky Boss to notify you immediately when corporate employers shortlist your profile or schedule an interview.',
                style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _finalizeAndNavigateHome();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Allow Notifications ✓', style: AppTheme.sansBold(fontSize: 14.5, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _finalizeAndNavigateHome();
                },
                child: Text('Maybe Later', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.textMuted)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finalizeAndNavigateHome() async {
    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    await provider.completeProfileSetup();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  // --- Comprehensive Edit Modal ---
  void _showFullEditModal(BuildContext context) {
    final nameEdit = TextEditingController(text: _nameController.text);
    final emailEdit = TextEditingController(text: _emailController.text);
    final phoneEdit = TextEditingController(text: widget.phoneNumber);
    final bioEdit = TextEditingController(text: _bioController.text);
    final tempSkills = List<String>.from(_selectedSkills);
    ExperienceLevel tempLevel = _selectedLevel;
    String tempCategory = _selectedCategory;
    String searchFilter = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredDict = AppData.verifiedSkillDictionary
                .where((s) => s.toLowerCase().contains(searchFilter.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
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
                  Text('Edit Full Profile', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                  const SizedBox(height: 4),
                  Text('Customize personal details, skills, and summary bio', style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted)),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        Text('Full Name', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameEdit,
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            fillColor: AppTheme.bgPaper,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text('Email Address', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: emailEdit,
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
                            fillColor: AppTheme.bgPaper,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text('Experience Level', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<ExperienceLevel>(
                          value: tempLevel,
                          items: ExperienceLevel.values.map((lvl) {
                            return DropdownMenuItem(value: lvl, child: Text(lvl.label));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => tempLevel = val);
                          },
                          decoration: InputDecoration(
                            fillColor: AppTheme.bgPaper,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text('Job Category', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: tempCategory,
                          items: AppData.categories.where((c) => c != 'All Roles').map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => tempCategory = val);
                          },
                          decoration: InputDecoration(
                            fillColor: AppTheme.bgPaper,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Skills & Competencies', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
                            Text('${tempSkills.length} selected', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.emeraldDark)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (val) => setModalState(() => searchFilter = val),
                          decoration: InputDecoration(
                            hintText: 'Search skills to add/remove...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            fillColor: AppTheme.bgPaper,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: filteredDict.map((skill) {
                            final isSel = tempSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill),
                              selected: isSel,
                              selectedColor: AppTheme.primaryNavy,
                              labelStyle: AppTheme.sansSemiBold(fontSize: 11.5, color: isSel ? Colors.white : AppTheme.textPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempSkills.add(skill);
                                  } else {
                                    tempSkills.remove(skill);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        Text('Executive Bio', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: bioEdit,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Write a short professional summary...',
                            fillColor: AppTheme.bgPaper,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _nameController.text = nameEdit.text.trim();
                          _emailController.text = emailEdit.text.trim();
                          _bioController.text = bioEdit.text.trim();
                          _selectedLevel = tempLevel;
                          _selectedCategory = tempCategory;
                          _selectedSkills.clear();
                          _selectedSkills.addAll(tempSkills);
                        });

                        final provider = Provider.of<JobSeekerProvider>(context, listen: false);
                        provider.updateAllProfileDetails(
                          name: nameEdit.text.trim(),
                          email: emailEdit.text.trim(),
                          phone: phoneEdit.text.trim(),
                          experienceLevel: tempLevel,
                          preferredCategory: tempCategory,
                          skills: tempSkills,
                          bio: bioEdit.text.trim(),
                          resumeFileName: _uploadedFileName,
                        );

                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Save & Apply Changes', style: AppTheme.sansBold(fontSize: 14, color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryNavy, size: 18),
                onPressed: () => _goToStep(_currentStep - 1),
              )
            : null,
        title: const Row(
          children: [
            LuckyBossBrandLogo(height: 34),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Basic Info'),
                _buildStepDivider(0),
                _buildStepIndicator(1, 'Skills & Bio'),
                _buildStepDivider(1),
                _buildStepIndicator(2, 'Review'),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1BasicInfo(),
          _buildStep2SkillsAndResume(),
          _buildStep3Review(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _currentStep >= stepIndex;
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.emerald : AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.sansBold(
              fontSize: 10.5,
              color: isActive ? AppTheme.primaryNavy : AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int stepIndex) {
    return const SizedBox(width: 8);
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 1: Basic Info (Clean & Unfilled)
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep1BasicInfo() {
    return Form(
      key: _formKeyStep1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: AppTheme.emeraldDark),
                const SizedBox(width: 6),
                Text('Verified Phone: ${widget.phoneNumber}', style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.emeraldDark)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Tell us about yourself',
            style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your personal details to personalize verified job matches.',
            style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Full Name Input
          Text('Full Name *', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. Rahul Sharma',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.textMuted),
              fillColor: AppTheme.bgPaper,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),

          // Email Input
          Text('Email Address *', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'e.g. name@example.com',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppTheme.textMuted),
              fillColor: AppTheme.bgPaper,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),

          // Experience Level
          Text('Experience Level', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
          const SizedBox(height: 6),
          DropdownButtonFormField<ExperienceLevel>(
            value: _selectedLevel,
            items: ExperienceLevel.values.map((lvl) {
              return DropdownMenuItem(value: lvl, child: Text(lvl.label));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLevel = val);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.trending_up_rounded, size: 20, color: AppTheme.textMuted),
              fillColor: AppTheme.bgPaper,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),

          // Preferred Category
          Text('Target Job Category', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: AppData.categories.where((c) => c != 'All Roles').map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category_outlined, size: 20, color: AppTheme.textMuted),
              fillColor: AppTheme.bgPaper,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleStep1Next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continue to Skills & Bio', style: AppTheme.sansBold(fontSize: 14.5, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 2: Resume Upload First OR Shift to Manual Skills & Bio
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep2SkillsAndResume() {
    final filteredSkills = AppData.verifiedSkillDictionary
        .where((s) => s.toLowerCase().contains(_skillSearchQuery.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      children: [
        Text(
          _step2SubView == 0 ? 'Resume & Extraction' : 'Manual Skills & Bio',
          style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        ),
        const SizedBox(height: 6),
        Text(
          _step2SubView == 0
              ? 'Upload your PDF resume to extract your verified skills and bio automatically.'
              : 'Enter your skills and professional bio directly below.',
          style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        if (_step2SubView == 0) ...[
          // Resume Upload Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgPaper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _resumeUploaded ? AppTheme.emerald : AppTheme.borderLight, width: _resumeUploaded ? 1.5 : 1),
            ),
            child: Column(
              children: [
                Icon(
                  _resumeUploaded ? Icons.task_alt_rounded : Icons.cloud_upload_outlined,
                  size: 48,
                  color: _resumeUploaded ? AppTheme.emeraldDark : AppTheme.royalBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  _resumeUploaded ? (_uploadedFileName ?? 'Resume Attached') : 'Upload Resume File',
                  style: AppTheme.sansBold(fontSize: 15.5, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  _resumeUploaded ? 'Lucky AI extracted your verified skills & summary' : 'Supports PDF, DOCX (Max 10MB)',
                  style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                if (_isExtractingResume)
                  const CircularProgressIndicator(color: AppTheme.emerald)
                else
                  ElevatedButton.icon(
                    onPressed: _promptResumeUpload,
                    icon: Icon(_resumeUploaded ? Icons.refresh_rounded : Icons.upload_file_rounded, size: 18),
                    label: Text(_resumeUploaded ? 'Select Different File' : 'Select PDF Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _resumeUploaded ? AppTheme.emeraldDark : AppTheme.primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // If resume was extracted, show quick preview of extracted skills & bio
          if (_resumeUploaded) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Extracted Skills (${_selectedSkills.length})', style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy)),
                      InkWell(
                        onTap: () => setState(() => _step2SubView = 1),
                        child: Text('Edit / Add More ✍️', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.royalBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedSkills.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s, style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.emeraldDark)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Link to switch to manual typing
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _step2SubView = 1),
              icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.royalBlue),
              label: Text(
                _resumeUploaded ? 'Customize / Edit Skills & Bio Manually' : 'Don\'t have a resume? Add details manually →',
                style: AppTheme.sansBold(fontSize: 13, color: AppTheme.royalBlue),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          // Manual Skills & Bio View
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Skills (${_selectedSkills.length})', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
              InkWell(
                onTap: () => setState(() => _step2SubView = 0),
                child: Text('← Back to Resume Upload', style: AppTheme.sansBold(fontSize: 12, color: AppTheme.royalBlue)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Live Skill Search Input
          TextField(
            controller: _skillSearchController,
            onChanged: (v) => setState(() => _skillSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search skills (e.g. Flutter, Python, Logistics)...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              fillColor: AppTheme.bgPaper,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),

          // Custom Skill Tag Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSkillController,
                  decoration: InputDecoration(
                    hintText: 'Add custom skill tag...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    fillColor: AppTheme.bgPaper,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final custom = _customSkillController.text.trim();
                  if (custom.isNotEmpty && !_selectedSkills.contains(custom)) {
                    setState(() {
                      _selectedSkills.add(custom);
                      _customSkillController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('+ Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Skill Filter Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: filteredSkills.map((skill) {
              final isAdded = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isAdded,
                selectedColor: AppTheme.primaryNavy,
                labelStyle: AppTheme.sansSemiBold(fontSize: 11.5, color: isAdded ? Colors.white : AppTheme.textPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Executive Bio Input
          Text('Executive Summary / Bio', style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy)),
          const SizedBox(height: 6),
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write a brief summary about your background, strengths, and career focus...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              fillColor: AppTheme.bgPaper,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
        ],

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _handleStep2Next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Review & Confirm Profile', style: AppTheme.sansBold(fontSize: 14.5, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP 3: Review & Confirm Profile
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep3Review() {
    final candidateName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Candidate';
    final candidateEmail = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'email@domain.com';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      children: [
        Text(
          'Everything look right?',
          style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        ),
        const SizedBox(height: 6),
        Text(
          'Review your profile before entering the app. You can always edit later.',
          style: AppTheme.sansRegular(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),

        // Profile Overview Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppTheme.primaryNavy, borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: Text(
                        candidateName.isNotEmpty ? candidateName[0].toUpperCase() : 'C',
                        style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                                style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.verified, color: AppTheme.emerald, size: 16),
                          ],
                        ),
                        Text(widget.phoneNumber, style: AppTheme.sansMedium(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              _buildReviewRow(Icons.email_outlined, 'Email', candidateEmail),
              const SizedBox(height: 10),
              _buildReviewRow(Icons.trending_up_rounded, 'Experience', _selectedLevel.label),
              const SizedBox(height: 10),
              _buildReviewRow(Icons.category_outlined, 'Preferred', _selectedCategory),
              const SizedBox(height: 10),
              _buildReviewRow(
                Icons.description_outlined,
                'Resume',
                _uploadedFileName ?? 'Manual Profile (No resume attached)',
              ),
              const SizedBox(height: 16),

              Text('Skills & Competencies', style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.primaryNavy)),
              const SizedBox(height: 8),
              _selectedSkills.isEmpty
                  ? Text('No skills added yet', style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.textMuted))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedSkills.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(s, style: AppTheme.sansBold(fontSize: 11.5, color: AppTheme.emeraldDark)),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 16),

              Text('Executive Bio', style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.primaryNavy)),
              const SizedBox(height: 6),
              Text(
                _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : 'No bio provided.',
                style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Edit Details Button
        Center(
          child: TextButton.icon(
            onPressed: () => _showFullEditModal(context),
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.royalBlue, size: 20),
            label: Text('Edit Full Details, Skills & Bio', style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.royalBlue)),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _finalizeAndNavigateHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Launch My Career', style: AppTheme.sansBold(fontSize: 15, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.rocket_launch_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTheme.sansMedium(fontSize: 12, color: AppTheme.textMuted)),
        Expanded(
          child: Text(
            value,
            style: AppTheme.sansBold(fontSize: 12.5, color: AppTheme.primaryNavy),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
