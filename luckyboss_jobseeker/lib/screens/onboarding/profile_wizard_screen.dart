import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/auth_service.dart';
import '../../services/resume_service.dart';
import '../../widgets/onboarding_components.dart';
import '../../widgets/city_field.dart';
import '../main_navigation_screen.dart';
import 'steps/account_step.dart';
import 'steps/education_step.dart';
import 'steps/field_details_step.dart';
import 'steps/key_skills_step.dart';
import 'steps/trade_step.dart';
import 'steps/work_category_step.dart';
import 'steps/work_step.dart';

/// Profile setup, rebuilt.
///
/// The wizard this replaces opened by asking for name and email — both of which
/// the candidate had just typed on the registration screen one tap earlier.
/// Re-asking is not merely redundant; it tells the user their input was not
/// received, which is the worst possible first impression of a product whose
/// entire pitch is that it tracks their application.
///
/// So this starts from what is genuinely unknown. The first question is now the
/// category — what kind of work — because that determines whether the rest of
/// the wizard should be asking about qualifications and key skills, or about a
/// trade, licences, languages and a day rate.
///
/// Both branches are three screens. The professional branch is the wizard that
/// was already here. The field branch exists because that one was unusable for
/// most of the people this agency actually places: it opened by asking a mason
/// whether he was a student, then for his highest qualification, then for a
/// list of key skills typed into a chip field. Every one of those questions is
/// either irrelevant or unanswerable on a building site, and the result was a
/// profile with nothing in it that any employer could search.
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Four now: who you are, then what work, then the trade, then the details.
  static const int _totalSteps = 4;

  /// The category is always first. What follows depends on the path it sits on,
  /// and the labels have to follow too — a scaffolder shown a step called
  /// "Background" is being asked, in the app's own words, for a CV.
  List<String> get _stepLabels => _data.isFieldWork
      ? const ['Your account', 'Your work', 'Your trade', 'Last details']
      : const ['Your account', 'Your work', 'Background', 'Your skills'];

  @override
  void dispose() {
    _cityController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pager.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_step) {
        0 => _data.accountStepComplete,
        1 => _data.categoryStepComplete,
        2 => _data.isFieldWork
            ? _data.tradeStepComplete
            : (_data.track != null &&
                _data.currentCity.trim().isNotEmpty &&
                (_data.isStudent
                    ? _data.educationStepComplete
                    : _data.workStepComplete)),
        3 => _data.isFieldWork
            ? _data.fieldDetailsStepComplete
            : _data.skillsStepComplete,
        _ => false,
      };

  void _next() {
    if (!_canAdvance) return;
    // Put the keyboard away before moving. A new step is a new question, and
    // one asked from behind a keyboard reads as a form that will not end.
    _dismissKeyboard();
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
    _dismissKeyboard();
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

    // Written before anything else: the identity is what the rest of the
    // profile hangs off, and it is the field the completion nudge was asking
    // for on every launch.
    if (_data.name.trim().isNotEmpty) {
      await provider.setProfileField('name', _data.name.trim());
    }
    if (_data.email.trim().isNotEmpty) {
      await provider.setProfileField('email', _data.email.trim());
    }
    await AuthService.updateIdentity(
      name: _data.name.trim().isEmpty ? null : _data.name.trim(),
      email: _data.email.trim().isEmpty ? null : _data.email.trim(),
    );

    provider.setSkills(_data.skills);
    provider.applyOnboarding(
      categories: _data.categories,
      roleTitle: _data.roleTitle,
      certificates: _data.certificates.toList(),
      languages: _data.languages.toList(),
      workPermitStatuses: _data.workPermitStatuses.toList(),
      payPeriod: _data.payPeriod,
      isStudent: _data.isStudent,
      currentCity: _data.currentCity,
      // On the field path the trade is the job title, and the years in trade
      // are the years of experience. Mapping them here rather than adding a
      // parallel set of profile fields keeps matching, search and the profile
      // screen working off one set of values.
      currentTitle: _data.isFieldWork ? _data.roleTitle : _data.currentTitle,
      yearsExperience:
          _data.isFieldWork ? _data.yearsInTrade : _data.yearsExperience,
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
    // Documents picked during the wizard are attached now, not while the
    // candidate was still filling it in — an abandoned form should leave
    // nothing behind on the profile.
    for (final document in _data.uploadedProof) {
      await provider.addDocument(document);
    }

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
                  _scroll(
                    AccountStep(
                      data: _data,
                      phone: context.watch<JobSeekerProvider>().profile.phone,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  _scroll(
                    WorkCategoryStep(
                      selected: _data.category,
                      onChanged: (name) => setState(() {
                        // A different category means a different vocabulary,
                        // so the trade and everything picked from it goes.
                        // Keeping a welding certificate on a nursing profile
                        // would be worse than asking again.
                        if (_data.category != name) {
                          _data.roleTitle = '';
                          _data.certificates.clear();
                          _data.skills.clear();
                        }
                        _data.category = name;
                      }),
                    ),
                  ),
                  _scroll(_secondStep()),
                  _scroll(_thirdStep()),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  /// Step two: the job itself, for every category.
  ///
  /// Both paths pick a role here now. Healthcare & Nursing used to fall
  /// straight through to the professional branch — the same screens IT gets —
  /// so a nurse was asked for her highest qualification and a list of key
  /// skills, and never offered "Staff Nurse" at all. Shantosh: *"healthcare and
  /// nursing brings me the IT & Software page, fix it, have their own thing to
  /// select like others."*
  ///
  /// What still differs is what comes *after* the trade: a professional
  /// candidate is asked about education and a CV, a field candidate is not.
  Widget _secondStep() {
    if (_data.isFieldWork) {
      return TradeStep(data: _data, onChanged: () => setState(() {}));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The same trade picker the field path opens with, so every category
        // offers its own jobs.
        TradeStep(data: _data, onChanged: () => setState(() {})),
        const SizedBox(height: 30),
        Divider(color: Theme.of(context).dividerColor),
        const SizedBox(height: 22),
        // Resume autofill is offered on the professional path only. A candidate
        // who has never had a CV written for them is not helped by being asked
        // to upload one — it reads as a requirement they cannot meet.
        AiAutofillBanner(
          onUpload: _uploadResume,
          busy: _parsingResume,
          fileName: _data.resumeFileName,
        ),
        const SizedBox(height: 26),
        _trackStep(),
        if (_data.track != null) ...[
          const SizedBox(height: 28),
          if (_data.isStudent)
            EducationStep(data: _data, onChanged: () => setState(() {}))
          else
            WorkStep(data: _data, onChanged: () => setState(() {})),
        ],
      ],
    );
  }

  /// Step three: the practical details for field work, key skills otherwise.
  Widget _thirdStep() {
    if (_data.isFieldWork) {
      return FieldDetailsStep(
        data: _data,
        cityController: _cityController,
        onChanged: () => setState(() {}),
      );
    }
    return KeySkillsStep(
      selected: _data.skills,
      seedCategory: _skillCategory(),
      onChanged: (list) => setState(() {
        _data.skills
          ..clear()
          ..addAll(list);
      }),
    );
  }

  /// Maps the candidate's answers onto a job category to seed skill suggestions.
  ///
  /// The chosen category wins outright now — it was asked first and explicitly,
  /// so guessing from a course name would be second-guessing an answer we
  /// already have. The keyword reading below is only a fallback for a profile
  /// that predates the category step.
  String _skillCategory() {
    if (_data.category.isNotEmpty) return _data.category;
    return _inferCategory();
  }

  String _inferCategory() {
    final course = _data.course.toLowerCase();
    final title = _data.currentTitle.toLowerCase();
    final combined = '$course $title';

    if (combined.contains('nurse') || combined.contains('medical') || combined.contains('health')) {
      return 'Healthcare & Nursing';
    }
    if (combined.contains('warehouse') || combined.contains('logistic') || combined.contains('supply')) {
      return 'Warehouse & Logistics';
    }
    if (combined.contains('account') || combined.contains('finance') || combined.contains('b.com') || combined.contains('m.com')) {
      return 'Finance & Banking';
    }
    if (combined.contains('civil') || combined.contains('mechanical') || combined.contains('electrical') || combined.contains('b.e')) {
      return 'Engineering';
    }
    if (combined.contains('software') || combined.contains('developer') || combined.contains('bca') || combined.contains('mca') || combined.contains('b.tech')) {
      return 'IT & Software';
    }
    return context.read<JobSeekerProvider>().profile.preferredCategory;
  }

  /// Drops focus, and with it the keyboard.
  ///
  /// `unfocus` rather than `FocusScope.of(context).unfocus()` on a primary
  /// focus that may not exist — calling it unconditionally on a step with no
  /// text field at all is a no-op, which is what we want.
  void _dismissKeyboard() => dismissKeyboard(context);

  /// One page of the wizard.
  ///
  /// The `FocusScope` is what stops a text field on a page the user has left
  /// from reclaiming focus and pulling the keyboard back up — a PageView keeps
  /// all its pages mounted, so without this they compete.
  Widget _scroll(Widget child) => FocusScope(
        child: _scrollBody(child),
      );

  Widget _scrollBody(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        // Dragging the page down puts the keyboard away, the behaviour every
        // native form has. Without it the only way to dismiss it is the system
        // back gesture, which on Android also leaves the step.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: child,
      );

  /// The student / working fork, plus the current city.
  ///
  /// This used to be a screen of its own, opening the wizard. It is a section
  /// of step two now because the category question took its place — and because
  /// it never applied to field work in the first place. "Are you a student?" is
  /// not a question you put to somebody looking for work as a cleaner.
  Widget _trackStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your background',
            style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'So we ask you the right questions.',
          style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 22),

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
            if (_step == 3 && !_data.isFieldWork)
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
