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
  final double aiMatchPercent;
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
    required this.aiMatchPercent,
    required this.description,
    required this.requiredSkills,
    required this.postedDate,
    this.isBookmarked = false,
  });

  String get salaryDisplay => '$currency $minSalary - $maxSalary / mo';
}