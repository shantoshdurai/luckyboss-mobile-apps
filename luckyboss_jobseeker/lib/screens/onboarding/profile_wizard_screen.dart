import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/resume_service.dart';
import '../../widgets/onboarding_components.dart';
import '../../widgets/city_field.dart';
import '../main_navigation_screen.dart';
import 'steps/education_step.dart';
import 'steps/key_skills_step.dart';
import 'steps/work_step.dart';

/// Profile setup, rebuilt.
///
/// The wizard this replaces opened by asking for name and email — both of which
/// the candidate had just typed on the registration screen one tap earlier.
/// Re-asking is not merely redundant; it tells the user their input was not
/// received, which is the worst possible first impression of a product whose
/// entire pitch is that it tracks their application.
///
/// So this starts from what is genuinely unknown: are they a student or already
/// working? Everything downstream branches on that answer.
class ProfileWizardScreen extends StatefulWidget {
  const ProfileWizardScreen({super.key});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final OnboardingData _data = OnboardingData();
  final TextEditingController _cityController = TextEditingController();
  final PageController _pager = PageController();

  int _step = 0;
  bool _parsingResume = false;

  /// Track, background, skills. Three questions, not three forms.
  static const int _totalSteps = 3;

  static const List<String> _stepLabels = [
    'About you',
    'Background',
    'Your skills',
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _pager.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_step) {
        0 => _data.trackStepComplete,
        1 => _data.isStudent ? _data.educationStepComplete : _data.workStepComplete,
        2 => _data.skillsStepComplete,
        _ => false,
      };

  void _next() {
    if (!_canAdvance) return;
    if (_step == _totalSteps - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
    _pager.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
    _pager.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  /// Folds the wizard's answers into the candidate profile.
  ///
  /// Name and email are deliberately not touched — they came from registration
  /// and this screen never asked for them, so it has no business overwriting
  /// them.
  Future<void> _finish() async {
    final provider = context.read<JobSeekerProvider>();

    provider.setSkills(_data.skills);
    provider.applyOnboarding(
      isStudent: _data.isStudent,
      currentCity: _data.currentCity,
      currentTitle: _data.currentTitle,
      yearsExperience: _data.yearsExperience,
      qualification: _data.qualification?.label,
      course: _data.course,
      passingYear: _data.passingYear,
      noticePeriod: _data.noticePeriod,
      resumeFileName: _data.resumeFileName,
      preferredCountry: _data.preferredCountry,
      workModes: _data.workModes.toList(),
      jobTypes: _data.jobTypes.toList(),
      expectedSalary: _data.expectedSalary,
      availability: _data.availability,
      openToRelocate: _data.openToRelocate,
      hasWorkPermit: _data.hasWorkPermit,
    );
    await provider.completeProfileSetup();
    // Push everything the wizard collected. This is what stops the next launch
    // asking for it all over again.
    await provider.syncProfile();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  /// Resume autofill.
  ///
  /// Gated server-side on two admin flags. When the parser is off the endpoint
  /// returns 403 and the candidate is told to fill the form in manually — the
  /// app never fabricates extracted values to keep the flow moving.
  ///
  /// Extracted fields land in the wizard marked for review. They are pre-filled,
  /// not committed: the candidate sees them in the same inputs they would have
  /// typed into, and every one stays editable.
  Future<void> _uploadResume() async {
    setState(() => _parsingResume = true);
    final result = await ResumeService.pickAndParse();
    if (!mounted) return;
    setState(() => _parsingResume = false);

    if (result.ok) {
      final r = result.data!;
      setState(() {
        _data.autofilledFromResume = true;
        _data.resumeFileName = r.fileName;

        // Only fill blanks. A candidate who already answered a question should
        // not have their own answer replaced by the model's reading of it.
        if (_data.currentCity.isEmpty) _data.currentCity = r.currentCity;
        if (_data.currentTitle.isEmpty) _data.currentTitle = r.currentTitle;
        if (_data.currentCompany.isEmpty) _data.currentCompany = r.currentCompany;
        if (_data.course.isEmpty) _data.course = r.course;
        if (_data.passingYear.isEmpty) _data.passingYear = r.passingYear;
        if (_data.yearsExperience == 0) _data.yearsExperience = r.yearsExperience;

        _data.qualification ??= Qualification.values
            .where((q) => q.label == r.qualification)
            .firstOrNull;

        // Experience implies the track, so a parsed resume answers question one.
        _data.track ??= r.yearsExperience > 0 || r.currentTitle.isNotEmpty
            ? CandidateTrack.working
            : CandidateTrack.student;

        for (final skill in r.skills) {
          if (!_data.skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
            _data.skills.add(skill);
          }
        }
      });

      _notify('Filled from ${r.fileName}. Check the details and correct anything wrong.',
          AppTheme.signalPositive);
      return;
    }

    switch (result.failure) {
      case ResumeFailure.cancelled:
        return;
      case ResumeFailure.disabled:
        _notify(result.message!, AppTheme.signalAttention);
      default:
        if (result.message != null) {
          _notify(result.message!, AppTheme.signalClosed);
        }
    }
  }

  void _notify(String message, Color tone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: tone,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: _back,
        ),
        title: WizardProgress(
          step: _step + 1,
          total: _totalSteps,
          label: _stepLabels[_step],
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pager,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _scroll(_trackStep()),
                  _scroll(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AiAutofillBanner(
                          onUpload: _uploadResume,
                          busy: _parsingResume,
                          fileName: _data.resumeFileName,
                        ),
                        const SizedBox(height: 26),
                        if (_data.isStudent)
                          EducationStep(
                              data: _data, onChanged: () => setState(() {}))
                        else
                          WorkStep(data: _data, onChanged: () => setState(() {})),
                      ],
                    ),
                  ),
                  _scroll(
                    KeySkillsStep(
                      selected: _data.skills,
                      seedCategory: _skillCategory(),
                      onChanged: (list) => setState(() {
                        _data.skills
                          ..clear()
                          ..addAll(list);
                      }),
                    ),
                  ),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  /// Maps the candidate's answers onto a job category to seed skill suggestions.
  ///
  /// Falls back to whatever they picked in the app's country/category filter so
  /// the first list is never empty.
  String _skillCategory() {
    final course = _data.course.toLowerCase();
    final title = _data.currentTitle.toLowerCase();
    final combined = '$course $title';

    if (combined.contains('nurse') || combined.contains('medical') || combined.contains('health')) {
      return 'Healthcare & Nursing';
    }
    if (combined.contains('warehouse') || combined.contains('logistic') || combined.contains('supply')) {
      return 'Logistics & Warehouse';
    }
    if (combined.contains('account') || combined.contains('finance') || combined.contains('b.com') || combined.contains('m.com')) {
      return 'Finance & Banking';
    }
    if (combined.contains('civil') || combined.contains('mechanical') || combined.contains('electrical') || combined.contains('b.e')) {
      return 'Engineering & Tech';
    }
    if (combined.contains('software') || combined.contains('developer') || combined.contains('bca') || combined.contains('mca') || combined.contains('b.tech')) {
      return 'IT & Software';
    }
    return context.read<JobSeekerProvider>().profile.preferredCategory;
  }

  Widget _scroll(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: child,
      );

  Widget _trackStep() {
    final profile = context.watch<JobSeekerProvider>().profile;
    final greeting = profile.name.trim().isEmpty
        ? "Let's build your profile"
        : "Welcome, ${profile.name.split(' ').first}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
            style: AppTheme.serifTitle(fontSize: 28, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'Two quick questions and we will start matching you to live vacancies.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 28),

        TrackCard(
          title: CandidateTrack.student.title,
          subtitle: CandidateTrack.student.subtitle,
          icon: Icons.school_outlined,
          selected: _data.track == CandidateTrack.student,
          onTap: () => setState(() => _data.track = CandidateTrack.student),
        ),
        const SizedBox(height: 12),
        TrackCard(
          title: CandidateTrack.working.title,
          subtitle: CandidateTrack.working.subtitle,
          icon: Icons.work_outline,
          selected: _data.track == CandidateTrack.working,
          onTap: () => setState(() => _data.track = CandidateTrack.working),
        ),

        const SizedBox(height: 28),
        RevealedField(
          label: 'Current city *',
          visible: _data.track != null,
          // Same instant picker as search — this was a plain text field, so a
          // candidate typing "chennai" got no confirmation the city was one we
          // actually match jobs against.
          child: CityField(
            controller: _cityController,
            helper: 'Helps us match you to jobs you can actually reach.',
            hint: 'e.g. Chennai, Singapore, Kuala Lumpur',
            onChanged: (v) => setState(() => _data.currentCity = v),
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    final last = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step == 2)
              Expanded(
                flex: 2,
                child: Text(
                  _data.skills.isEmpty
                      ? 'Add at least one skill'
                      : '${_data.skills.length} skill${_data.skills.length == 1 ? "" : "s"} added',
                  style: AppTheme.sansMedium(
                    fontSize: 13,
                    color: _data.skills.isEmpty
                        ? AppTheme.inkFaintOf(context)
                        : AppTheme.signalPositive,
                  ),
                ),
              ),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _canAdvance ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryFillOf(context),
                    foregroundColor: AppTheme.onPrimaryFillOf(context),
                    disabledBackgroundColor: Theme.of(context).dividerColor,
                    disabledForegroundColor: AppTheme.inkFaintOf(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        last ? 'Finish' : 'Next',
                        style: AppTheme.sansBold(
                          fontSize: 15,
                          // Explicit rather than inherited: a Text with its own
                          // style does not pick up the button's foregroundColor,
                          // so the disabled state would otherwise stay white on
                          // grey and be unreadable.
                          color: _canAdvance ? Colors.white : AppTheme.inkFaintOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(last ? Icons.check : Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
