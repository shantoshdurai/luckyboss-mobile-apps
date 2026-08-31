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

  // Asked only after onboarding, and only of the people they apply to.
  static const String ownTools = 'own_tools';
  static const String ownTransport = 'own_transport';
  static const String nightShift = 'night_shift';
  static const String accommodation = 'accommodation';
  static const String passport = 'passport';
  static const String noticePeriod = 'notice_period';

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
      kind: PromptKind.choice,
      options: [
        'Under ₹25,000',
        '₹25,000 – ₹50,000',
        '₹50,000 – ₹1,00,000',
        'Above ₹1,00,000',
        'S\$2,500 – S\$5,000',
        'S\$5,000+',
      ],
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

    // --- The rest, asked between job cards over time ---
    //
    // Deliberately short and answerable in one tap. A question that needs
    // thinking about does not belong between two job cards.
    FeedPrompt(
      id: ownTools,
      question: 'Do you have your own tools?',
      detail: 'Some employers only take workers who bring their own.',
      kind: PromptKind.yesNo,
      completionGain: 4,
    ),
    FeedPrompt(
      id: ownTransport,
      question: 'Do you have your own vehicle?',
      detail: 'A bike or a van. It widens which sites you can reach.',
      kind: PromptKind.yesNo,
      completionGain: 4,
    ),
    FeedPrompt(
      id: nightShift,
      question: 'Would you work night shifts?',
      detail: 'Warehouse, security and factory work is often nights.',
      kind: PromptKind.yesNo,
      completionGain: 5,
    ),
    FeedPrompt(
      id: accommodation,
      question: 'Would you stay in accommodation the employer provides?',
      detail: 'Most jobs in another country come with a room.',
      kind: PromptKind.yesNo,
      completionGain: 5,
    ),
    FeedPrompt(
      id: passport,
      question: 'Do you have a passport?',
      detail: 'Needed before we can put you forward for work abroad.',
      kind: PromptKind.yesNo,
      completionGain: 4,
    ),
    FeedPrompt(
      id: noticePeriod,
      question: 'If you are working now, how much notice do you owe?',
      kind: PromptKind.choice,
      options: ['None', '1 week', '2 weeks', '1 month', 'More than a month'],
      completionGain: 4,
    ),
  ];
}
