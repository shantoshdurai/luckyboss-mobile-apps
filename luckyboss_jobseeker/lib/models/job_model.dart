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
  });

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

  /// Real dynamic Overall AI Compatibility Score %
  double calculateAiMatchPercent(List<String> candidateSkills, String? preferredCategory) {
    if (candidateSkills.isEmpty) return 0.0;
    final skillPct = getTechnicalSkillsMatch(candidateSkills);
    final categoryScore = (preferredCategory == category) ? 100.0 : 20.0;
    final composite = (skillPct * 0.75) + (categoryScore * 0.25);
    return composite.clamp(0.0, 100.0);
  }
}