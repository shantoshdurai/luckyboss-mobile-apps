class EmployerJobModel {
  final String id;
  final String title;
  final String category;
  final String location;
  final String countryCode;
  final String salaryDisplay;
  final int applicantsCount;
  final String status; // published, draft, expired
  final DateTime postedDate;

  EmployerJobModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.countryCode,
    required this.salaryDisplay,
    required this.applicantsCount,
    required this.status,
    required this.postedDate,
  });
}

class ApplicantModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String candidateName;
  final String candidatePhone;
  final String experience;
  final String location;
  final double aiMatchScore;
  String status; // New, Shortlisted, Interview, Offer, Rejected

  ApplicantModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.candidateName,
    required this.candidatePhone,
    required this.experience,
    required this.location,
    required this.aiMatchScore,
    required this.status,
  });
}