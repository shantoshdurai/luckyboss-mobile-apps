import '../core/theme/app_theme.dart';

class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String countryCode;
  final String location;
  final String workMode; // On-site, Hybrid, Remote
  final String minSalary;
  final String maxSalary;
  final String currency;
  final String category;
  final String description;
  final List<String> requiredSkills;
  final DateTime postedDate;
  bool isBookmarked;

  /// Where this listing came from. The specification requires that a
  /// third-party listing always shows its source — a seeker deciding whether to
  /// trust a posting needs to know who published it.
  final JobSource source;

  /// The actual provider name, for external listings. "External" alone tells a
  /// seeker nothing about whether the listing can be trusted.
  final String? sourceName;

  /// Closing date, where the employer set one. Drives the "closing soon" state.
  final DateTime? closingDate;

  /// Set when the employer has made this a paid application. Null means free,
  /// which is the default until an admin turns candidate monetisation on.
  final double? applicationFee;
  final String? applicationFeeCurrency;

  // ---------------------------------------------------------------------------
  // FIELD WORK
  //
  // What a site worker, driver or domestic helper reads a posting for. None of
  // it existed while the app was an IT job board, and all of it decides whether
  // somebody applies: a construction job that houses you and one that does not
  // are different jobs at the same wage.
  // ---------------------------------------------------------------------------

  /// The specific job, distinct from a free-text [title]. Matched against the
  /// candidate's own trade.
  final String role;

  /// Whether the wage is quoted per day, per month or per year. A day rate
  /// shown without its unit is not a number anybody can act on.
  final String payPeriod;

  /// Licences the employer requires. Kept apart from [requiredSkills] because
  /// it is a hard gate, not a preference — no forklift ticket, no shortlist.
  final List<String> requiredCertificates;

  final bool accommodationProvided;
  final bool transportProvided;
  final bool permitSponsored;

  /// True for the sample vacancies bundled with the app. Carried through from
  /// the catalogue so these rows stay identifiable after they are loaded into
  /// MySQL, and can be removed in one statement once real postings arrive.
  final bool isSeed;

  JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.countryCode,
    required this.location,
    required this.workMode,
    required this.minSalary,
    required this.maxSalary,
    required this.currency,
    required this.category,
    required this.description,
    required this.requiredSkills,
    required this.postedDate,
    this.isBookmarked = false,
    this.source = JobSource.luckyBoss,
    this.sourceName,
    this.closingDate,
    this.applicationFee,
    this.applicationFeeCurrency,
    this.role = '',
    this.payPeriod = 'Per month',
    this.requiredCertificates = const [],
    this.accommodationProvided = false,
    this.transportProvided = false,
    this.permitSponsored = false,
    this.isSeed = false,
  });

  /// Builds a job from one row of the catalogue.
  ///
  /// Column names are snake_case because they are the MySQL column names, not a
  /// Dart convention — the bundled `assets/data/seed_jobs.json` is shaped like
  /// the `jobs` table so the same rows can be loaded server-side unchanged, and
  /// so the API response this will eventually replace needs no translation
  /// layer.
  factory JobModel.fromCatalogJson(Map<String, dynamic> j) {
    List<String> strings(String key) =>
        ((j[key] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList();

    final hoursAgo = (j['posted_hours_ago'] as num?)?.toInt();
    final postedAt = j['posted_at'] as String?;

    return JobModel(
      id: j['id'] as String,
      title: (j['title'] ?? '') as String,
      companyName: (j['company_name'] ?? '') as String,
      countryCode: (j['country_code'] ?? '') as String,
      location: (j['location'] ?? '') as String,
      workMode: (j['work_mode'] ?? 'On-site') as String,
      minSalary: (j['min_salary'] ?? '') as String,
      maxSalary: (j['max_salary'] ?? '') as String,
      currency: (j['currency'] ?? '') as String,
      category: (j['category'] ?? '') as String,
      description: (j['description'] ?? '') as String,
      requiredSkills: strings('required_skills'),
      // Relative rather than absolute so a bundled catalogue does not age into
      // a feed of vacancies posted "eight months ago" on a phone installed next
      // year.
      postedDate: postedAt != null
          ? (DateTime.tryParse(postedAt) ?? DateTime.now())
          : DateTime.now().subtract(Duration(hours: hoursAgo ?? 0)),
      source: (j['source'] == 'partner') ? JobSource.external : JobSource.luckyBoss,
      sourceName: j['source_name'] as String?,
      role: (j['role'] ?? j['title'] ?? '') as String,
      payPeriod: (j['pay_period'] ?? 'Per month') as String,
      requiredCertificates: strings('required_certificates'),
      accommodationProvided: (j['accommodation_provided'] as bool?) ?? false,
      transportProvided: (j['transport_provided'] as bool?) ?? false,
      permitSponsored: (j['permit_sponsored'] as bool?) ?? false,
      isSeed: (j['seed'] as bool?) ?? false,
    );
  }

  /// The perks a field candidate scans for before anything else.
  List<String> get benefits => [
        if (accommodationProvided) 'Accommodation',
        if (transportProvided) 'Transport',
        if (permitSponsored) 'Permit sponsored',
      ];

  /// A paid application. Free is the default, and stays the default until an
  /// admin enables candidate monetisation and marks a specific job paid.
  bool get requiresPayment => applicationFee != null && applicationFee! > 0;

  String get feeDisplay =>
      requiresPayment ? '${applicationFeeCurrency ?? 'SGD'} ${applicationFee!.toStringAsFixed(0)}' : 'Free';

  /// Days until the posting closes. Negative means it has already closed.
  int? get daysUntilClosing =>
      closingDate?.difference(DateTime.now()).inDays;

  bool get isClosingSoon {
    final d = daysUntilClosing;
    return d != null && d >= 0 && d <= 3;
  }

  String get salaryDisplay => '$currency $minSalary - $maxSalary / mo';

  /// Real dynamic AI Technical Skills match % (0% if no skills match)
  double getTechnicalSkillsMatch(List<String> candidateSkills) {
    if (candidateSkills.isEmpty || requiredSkills.isEmpty) return 0.0;
    int matched = 0;
    for (final req in requiredSkills) {
      if (candidateSkills.any((s) =>
          s.trim().toLowerCase() == req.trim().toLowerCase() ||
          s.trim().toLowerCase().contains(req.trim().toLowerCase()) ||
          req.trim().toLowerCase().contains(s.trim().toLowerCase()))) {
        matched++;
      }
    }
    return ((matched / requiredSkills.length) * 100).clamp(0.0, 100.0);
  }

  /// How many of the licences this job demands the candidate actually holds.
  ///
  /// A separate figure from skills because it behaves differently: a job that
  /// requires a forklift licence is not 60% suitable for somebody without one,
  /// it is closed to them. [calculateAiMatchPercent] weights it accordingly.
  double getCertificateMatch(List<String> held) {
    if (requiredCertificates.isEmpty) return 100.0;
    if (held.isEmpty) return 0.0;
    final lower = held.map((c) => c.trim().toLowerCase()).toSet();
    final matched = requiredCertificates
        .where((c) => lower.contains(c.trim().toLowerCase()))
        .length;
    return ((matched / requiredCertificates.length) * 100).clamp(0.0, 100.0);
  }

  /// Overall compatibility, 0–100.
  ///
  /// Rewritten because the previous version could not score a field candidate
  /// at all. It returned 0 whenever `candidateSkills` was empty and weighted
  /// skills at 75%, so a Mason with his trade, his years and his safety card on
  /// file — but no chips ticked in a list he was never shown — matched nothing,
  /// and the home feed told him to "add a few skills and recommendations start
  /// appearing". He had nothing to add.
  ///
  /// What a field candidate is actually matched on, in the order an agency
  /// would use: is it his trade, is it his line of work, does he hold the
  /// licence, and can he do the tasks.
  double calculateAiMatchPercent(
    List<String> candidateSkills,
    String? preferredCategory, {
    String candidateRole = '',
    List<String> certificates = const [],
  }) {
    final sameCategory = preferredCategory == category;
    final sameRole = candidateRole.trim().isNotEmpty &&
        (candidateRole.trim().toLowerCase() == role.trim().toLowerCase() ||
            candidateRole.trim().toLowerCase() == title.trim().toLowerCase());

    // Nothing at all to go on. Returning 0 is honest here — it is what keeps a
    // brand new profile out of the recommendation list rather than filling it
    // with noise.
    if (!sameCategory && !sameRole && candidateSkills.isEmpty) return 0.0;

    final skillPct = getTechnicalSkillsMatch(candidateSkills);
    final certPct = getCertificateMatch(certificates);

    var score = 0.0;
    score += sameRole ? 45.0 : 0.0;
    score += sameCategory ? 25.0 : 0.0;
    score += skillPct * 0.20;
    score += certPct * 0.10;

    // A licence the job insists on and the candidate does not hold is a hard
    // ceiling, not a deduction. Showing it as a 70% match would send somebody
    // to an interview they cannot pass.
    if (requiredCertificates.isNotEmpty && certPct == 0) {
      score = score.clamp(0.0, 55.0);
    }

    return score.clamp(0.0, 100.0);
  }
}