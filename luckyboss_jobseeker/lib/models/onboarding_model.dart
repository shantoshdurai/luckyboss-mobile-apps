import '../core/constants/app_data.dart';
import 'uploaded_document.dart';

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
  // ---------------------------------------------------------------------------
  // THE FIRST QUESTION — what kind of work?
  //
  // Everything else branches off this. Lucky Boss places construction workers,
  // factory labour, warehouse manpower, drivers, domestic helpers and service
  // staff alongside engineers and office roles, and the two groups need almost
  // no questions in common. Asking a scaffolder for their highest qualification
  // and a list of key skills produces an empty profile; asking a software
  // engineer for their forklift licence is equally useless.
  //
  // So the category is chosen first, and [WorkPath] on it decides which
  // questions follow.
  // ---------------------------------------------------------------------------
  // --- Account, asked first ---
  //
  // The app never asked for a name anywhere, so the completion nudge said "Add
  // your name" forever with nowhere to type one.
  String name = '';
  String email = '';
  String password = '';
  String bio = '';

  bool get accountStepComplete => name.trim().isNotEmpty;

  /// The kind of work being looked for. One, not several.
  ///
  /// Briefly allowed three, and reverted: every screen after this one is built
  /// from the chosen category's own vocabulary — its trades, its tasks, its
  /// certificates — so a second choice had nowhere to be asked about. A
  /// candidate open to more than one kind of work adds the others from their
  /// profile afterwards, where there is room to ask properly.
  String category = '';

  /// Kept as a one-item view for the code that folds this into the profile.
  List<String> get categories => category.isEmpty ? const [] : [category];

  WorkCategory? get workCategory => AppData.categoryByName(category);

  /// True when this candidate should be asked about trades, licences and wages
  /// rather than qualifications and key skills.
  bool get isFieldWork => workCategory?.isField ?? false;

  /// The trade or job title, picked from the category's own list. On the field
  /// path this stands in for the whole "key skills" idea: a candidate taps
  /// "Plumber" and the app knows more about them than a chip field would ever
  /// have got out of them.
  String roleTitle = '';

  /// Years doing this trade. Plain count rather than a banded seniority label —
  /// "Lead / Principal (10+ yrs)" means nothing on a building site.
  int yearsInTrade = 0;

  /// Licences, cards and certificates the candidate says they hold.
  final Set<String> certificates = {};

  /// Documents uploaded during onboarding as proof of work.
  ///
  /// Held here so they can be folded into the profile when the wizard
  /// finishes, rather than written to the profile by a half-completed form
  /// somebody then abandons.
  final List<UploadedDocument> uploadedProof = [];

  /// Languages spoken — spec section 31, and often the deciding factor for
  /// domestic, care and service placements.
  final Set<String> languages = {};

  /// Work authorisation as a stated status rather than a yes/no. "Need employer
  /// to sponsor a permit" is a completely different proposition to an employer
  /// than "have a valid work permit", and a boolean cannot tell them apart.
  /// Work authorisation, as a set.
  ///
  /// Multiple because the countries are multiple: an Indian citizen who also
  /// holds a Singapore work permit is one person with two true answers, and
  /// forcing one threw away the fact that decides whether they can be placed.
  final Set<String> workPermitStatuses = {};

  /// First answer, for the fields that still take one string.
  String get workPermitStatus =>
      workPermitStatuses.isEmpty ? '' : workPermitStatuses.first;

  /// Whether [expectedSalary] is a daily, monthly or yearly figure. A site
  /// worker quotes a day rate; showing them a monthly field invites either a
  /// blank or a number nobody can interpret.
  String payPeriod = 'Per month';

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
  /// Markets the candidate will work in. A set because more than one is the
  /// normal answer for a cross-border agency.
  final Set<String> preferredCountries = {};

  /// First choice, for the profile fields that still take one market.
  String get preferredCountry =>
      preferredCountries.isEmpty ? '' : preferredCountries.first;
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

  bool get categoryStepComplete => categories.isNotEmpty;

  /// The trade step needs a role and nothing more. Years, abilities and cards
  /// all sharpen the profile, but holding somebody at the second screen of an
  /// app because they have not ticked a certificate is how onboarding gets
  /// abandoned.
  bool get tradeStepComplete => roleTitle.trim().isNotEmpty;

  bool get fieldDetailsStepComplete => currentCity.trim().isNotEmpty;

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
  bool get preferencesStepComplete => preferredCountries.isNotEmpty;

  /// What is still missing on [step], in the candidate's own words.
  ///
  /// The wizard used to grey the button out and say nothing, so somebody who
  /// had answered four of five questions was left tapping a dead control with
  /// no idea which one was left. Shantosh: *"in finsh beutton when they press
  /// say them and direct them what to fill and left so they know its not
  /// compelted"*. Empty means the step is done.
  List<String> missingFor(int step) => switch (step) {
        0 => [
            if (name.trim().isEmpty) 'your name',
          ],
        1 => [
            if (categories.isEmpty) 'the kind of work you want',
          ],
        2 => isFieldWork
            ? [
                if (roleTitle.trim().isEmpty) 'the job you do',
              ]
            : [
                if (track == null) 'whether you are studying or working',
                if (currentCity.trim().isEmpty) 'the city you live in',
                if (isStudent && qualification == null) 'your qualification',
                if (isStudent &&
                    qualification != null &&
                    !educationStepComplete)
                  'the rest of your education details',
                if (!isStudent && currentTitle.trim().isEmpty)
                  'your current job title',
              ],
        3 => isFieldWork
            ? [
                if (currentCity.trim().isEmpty) 'the city you live in',
              ]
            : [
                if (skills.isEmpty) 'at least one skill',
              ],
        _ => const [],
      };
}
