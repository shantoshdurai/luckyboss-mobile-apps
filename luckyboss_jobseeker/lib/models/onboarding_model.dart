/// Which branch of onboarding a candidate takes.
///
/// This is the first question asked, because almost everything after it
/// differs: a fresher has a passing year and marks, someone working has a
/// current employer and notice period. Asking one set of questions and hiding
/// half of them is how a form ends up feeling irrelevant to everyone.
enum CandidateTrack {
  student,
  working;

  String get title => switch (this) {
        CandidateTrack.student => 'I am a student / have never worked',
        CandidateTrack.working => 'I am working / have worked before',
      };

  String get subtitle => switch (this) {
        CandidateTrack.student =>
          'Fresh graduates, or graduates with no work experience yet',
        CandidateTrack.working =>
          'Currently working, or previously worked in a company or business',
      };
}

/// Highest qualification, ordered highest-first as candidates scan for their own.
enum Qualification {
  doctorate('Doctorate'),
  postGraduate('Post Graduate'),
  graduate('Graduate'),
  classXII('Class XII'),
  classX('Class X'),
  belowClassX('Below Class X');

  const Qualification(this.label);
  final String label;

  /// School-level qualifications ask for a board and medium; degrees ask for a
  /// course and specialisation instead. Driving that from the enum keeps the
  /// branching in one place rather than scattered through the widget.
  bool get isSchoolLevel =>
      this == Qualification.classXII ||
      this == Qualification.classX ||
      this == Qualification.belowClassX;
}

/// Everything the onboarding wizard collects.
///
/// Deliberately separate from [SeekerProfileModel]: this is the answer sheet,
/// filled progressively and possibly abandoned. It is folded into the profile
/// only when the candidate finishes, so a half-completed wizard never leaves
/// the profile in a partially-overwritten state.
class OnboardingData {
  CandidateTrack? track;
  String currentCity = '';

  // Education
  Qualification? qualification;
  String examinationBoard = '';
  String languageMedium = '';
  String course = '';
  String specialisation = '';
  String passingYear = '';
  String marks = '';

  // Work — collected only on the working track.
  String currentTitle = '';
  String currentCompany = '';
  int yearsExperience = 0;
  String noticePeriod = '';

  // Preferences — the constraints that make a match actionable rather than
  // merely plausible. Fed to the matching engine, not collected for its own sake.
  String preferredCountry = '';
  final Set<String> workModes = {};
  final Set<String> jobTypes = {};
  String expectedSalary = '';
  String availability = '';

  /// Null means unanswered. Storing an unanswered question as "no" would
  /// quietly exclude candidates from jobs they actually qualify for.
  bool? openToRelocate;
  bool? hasWorkPermit;

  // Skills
  final List<String> skills = [];

  /// Set when the AI resume parser filled these fields, so the review step can
  /// tell the candidate what to check rather than presenting extracted values
  /// as though they had typed them.
  bool autofilledFromResume = false;
  String? resumeFileName;

  bool get isStudent => track == CandidateTrack.student;

  /// The category used to seed skill suggestions before any skill is picked.
  ///
  /// A working candidate's job title is a far better signal than their degree,
  /// so it wins when present.
  String get skillSeedContext =>
      currentTitle.isNotEmpty ? currentTitle : (course.isNotEmpty ? course : '');

  bool get trackStepComplete => track != null && currentCity.trim().isNotEmpty;

  bool get educationStepComplete {
    if (qualification == null) return false;
    if (qualification!.isSchoolLevel) {
      return examinationBoard.isNotEmpty &&
          languageMedium.isNotEmpty &&
          passingYear.isNotEmpty;
    }
    return course.isNotEmpty && passingYear.isNotEmpty;
  }

  bool get workStepComplete =>
      currentTitle.trim().isNotEmpty && yearsExperience >= 0;

  bool get skillsStepComplete => skills.isNotEmpty;

  /// Only the market is required. The rest sharpen matching, and a candidate
  /// who wants to get to the job list should not be held at a preferences form.
  bool get preferencesStepComplete => preferredCountry.isNotEmpty;
}
