enum ApplicationStage { applied, shortlisted, interview, offer, rejected }

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String location;
  final String salaryDisplay;
  final double matchScore;
  final ApplicationStage stage;
  final DateTime appliedDate;
  final String? interviewSchedule;
  final String? recruiterRemarks;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.salaryDisplay,
    required this.matchScore,
    required this.stage,
    required this.appliedDate,
    this.interviewSchedule,
    this.recruiterRemarks,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'location': location,
        'salaryDisplay': salaryDisplay,
        'matchScore': matchScore,
        'stage': stage.name,
        'appliedDate': appliedDate.toIso8601String(),
        'interviewSchedule': interviewSchedule,
        'recruiterRemarks': recruiterRemarks,
      };

  factory ApplicationModel.fromJson(Map<String, dynamic> j) => ApplicationModel(
        id: j['id'] as String,
        jobId: (j['jobId'] as String?) ?? '',
        jobTitle: (j['jobTitle'] as String?) ?? '',
        companyName: (j['companyName'] as String?) ?? '',
        location: (j['location'] as String?) ?? '',
        salaryDisplay: (j['salaryDisplay'] as String?) ?? '',
        matchScore: (j['matchScore'] as num?)?.toDouble() ?? 0,
        stage: ApplicationStage.values.firstWhere(
          (e) => e.name == j['stage'],
          orElse: () => ApplicationStage.applied,
        ),
        appliedDate:
            DateTime.tryParse((j['appliedDate'] as String?) ?? '') ?? DateTime.now(),
        interviewSchedule: j['interviewSchedule'] as String?,
        recruiterRemarks: j['recruiterRemarks'] as String?,
      );

  int get stageStepIndex {
    switch (stage) {
      case ApplicationStage.applied: return 0;
      case ApplicationStage.shortlisted: return 1;
      case ApplicationStage.interview: return 2;
      case ApplicationStage.offer: return 3;
      case ApplicationStage.rejected: return 0;
    }
  }

  String get stageTitle {
    switch (stage) {
      case ApplicationStage.applied: return 'Application Received';
      case ApplicationStage.shortlisted: return 'Profile Shortlisted';
      case ApplicationStage.interview: return 'Interview Scheduled';
      case ApplicationStage.offer: return 'Offer Extended';
      case ApplicationStage.rejected: return 'Application Closed';
    }
  }
}