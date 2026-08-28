/// How a prompt collects its answer.
enum PromptKind { choice, yesNo, number, multiChoice }

/// A single question asked inside the home feed.
///
/// The preferences these collect used to be a fourth onboarding step — a wall
/// of six questions between a new candidate and the job list. Asking them one
/// at a time, between job cards, gets the same data without making anyone earn
/// their way to the product. A candidate who answers none of them still has a
/// working app; each one they do answer sharpens matching.
class FeedPrompt {
  /// Stable key. Used to record an answer and to remember a dismissal, so it
  /// must not change once shipped.
  final String id;

  final String question;
  final String? detail;
  final PromptKind kind;
  final List<String> options;

  /// Shown on the card as the profile-completion gain, matching the profile
  /// suggestion tiles. Honest: it is the actual weight this field carries.
  final int completionGain;

  /// Unit shown before a number input, e.g. a currency symbol.
  final String? prefix;

  const FeedPrompt({
    required this.id,
    required this.question,
    required this.kind,
    this.detail,
    this.options = const [],
    this.completionGain = 5,
    this.prefix,
  });
}

/// The prompts the feed can ask, in the order they matter for matching.
///
/// Ordered by how much each one changes which jobs are shown: market first,
/// because it filters everything; the work-permit question last, because it
/// only affects a subset of employers.
class FeedPrompts {
  FeedPrompts._();

  static const String preferredCountry = 'preferred_country';
  static const String expectedSalary = 'expected_salary';
  static const String workMode = 'work_mode';
  static const String availability = 'availability';
  static const String relocate = 'open_to_relocate';
  static const String jobType = 'job_type';
  static const String workPermit = 'work_permit';

  static const List<FeedPrompt> all = [
    FeedPrompt(
      id: preferredCountry,
      question: 'Where do you want to work?',
      // Multi-choice, not single. Lucky Boss places across three markets and a
      // candidate open to two of them was being made to discard one, which
      // narrowed their own feed for no reason.
      detail: 'Pick every market you would work in.',
      kind: PromptKind.multiChoice,
      options: ['India', 'Singapore', 'Malaysia'],
      completionGain: 8,
    ),
    FeedPrompt(
      id: expectedSalary,
      question: 'What monthly salary are you aiming for?',
      detail: 'Only used for matching. Employers never see this figure.',
      kind: PromptKind.number,
      completionGain: 8,
    ),
    FeedPrompt(
      id: workMode,
      question: 'How do you want to work?',
      kind: PromptKind.multiChoice,
      options: ['On-site', 'Hybrid', 'Remote'],
      completionGain: 6,
    ),
    FeedPrompt(
      id: availability,
      question: 'When can you start?',
      detail: 'Recruiters filter on this more than anything else.',
      kind: PromptKind.choice,
      options: ['Immediately', 'Within 15 days', 'Within a month', 'More than a month'],
      completionGain: 6,
    ),
    FeedPrompt(
      id: relocate,
      question: 'Are you open to relocating?',
      detail: 'We will include roles outside your current city.',
      kind: PromptKind.yesNo,
      completionGain: 5,
    ),
    FeedPrompt(
      id: jobType,
      question: 'What kind of role are you after?',
      kind: PromptKind.multiChoice,
      options: ['Full time', 'Part time', 'Contract', 'Internship'],
      completionGain: 5,
    ),
    FeedPrompt(
      id: workPermit,
      question: 'Do you have a valid work permit for this market?',
      detail: 'Some employers filter on this before shortlisting.',
      kind: PromptKind.yesNo,
      completionGain: 4,
    ),
  ];
}
