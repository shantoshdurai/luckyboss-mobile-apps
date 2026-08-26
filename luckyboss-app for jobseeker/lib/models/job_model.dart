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
  });

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