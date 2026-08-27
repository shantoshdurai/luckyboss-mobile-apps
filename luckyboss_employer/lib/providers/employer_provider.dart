import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/employer_models.dart';
import '../services/api_service.dart';
import '../widgets/ledger_components.dart';

class EmployerProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isDarkMode = false;
  final String _companyName = 'Lucky Boss Enterprise Pte Ltd';
  String _phone = '+65 8123 9900';

  // ---------------------------------------------------------------------------
  // Plan entitlements.
  //
  // These are mirrored from the server for display only. The Laravel API must
  // enforce them independently — a client that decides its own limits can be
  // bypassed by anyone who can call the endpoint directly.
  // ---------------------------------------------------------------------------
  final int _contactCreditsTotal = 250;
  int _contactCreditsUsed = 66;
  final int _aiCreditsTotal = 100;
  final int _aiCreditsUsed = 58;
  final bool _aiEnabledOnPlan = true;

  final List<EmployerJobModel> _jobs = [
    EmployerJobModel(
      id: 'emp-j1',
      title: 'Senior Backend Engineer',
      category: 'IT & Software',
      location: 'Singapore, One-North',
      countryCode: 'SG',
      salaryDisplay: 'SGD 6,500 - 9,000 / mo',
      applicantsCount: 41,
      status: 'published',
      postedDate: DateTime.now().subtract(const Duration(days: 6)),
    ),
    EmployerJobModel(
      id: 'emp-j2',
      title: 'Warehouse Supervisor',
      category: 'Logistics & Warehouse',
      location: 'Singapore, Jurong East',
      countryCode: 'SG',
      salaryDisplay: 'SGD 3,200 - 4,500 / mo',
      applicantsCount: 12,
      status: 'published',
      postedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // DEMO DATA — placeholder until the Laravel API serves candidates.
  //
  // There is currently no employer candidates endpoint: routes/api.php exposes
  // auth, jobs, two dashboards and an FCM token route, and nothing else. These
  // records exist so the screen can be reviewed; every one of them should be
  // replaced by GET /api/v1/employer/jobs/{job}/candidates once it exists.
  // ---------------------------------------------------------------------------
  final List<ApplicantModel> _applicants = [
    ApplicantModel(
      id: 'cand-01',
      jobId: 'emp-j1',
      jobTitle: 'Senior Backend Engineer',
      candidateName: 'Priya Raghunathan',
      headline: 'Senior Backend Engineer, Zalora',
      candidatePhone: '+65 8921 4455',
      candidateEmail: 'priya.r@example.com',
      experience: '8 yrs',
      location: 'Singapore',
      skills: ['Java', 'Kafka', 'PostgreSQL', 'AWS', 'Terraform'],
      aiMatchScore: 91,
      status: 'Shortlisted',
      source: CandidateSource.applied,
      lastActivity: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ApplicantModel(
      id: 'cand-02',
      jobId: 'emp-j1',
      jobTitle: 'Senior Backend Engineer',
      candidateName: 'Nurul Aisyah Binti Rahman',
      headline: 'Senior Full-Stack Engineer (Platform), Grab',
      candidatePhone: '+60 12 456 7788',
      candidateEmail: 'n.aisyah@example.com',
      experience: '5 yrs',
      location: 'Kuala Lumpur',
      skills: ['React', 'Node', 'Go', 'GCP'],
      aiMatchScore: 74,
      status: 'New',
      source: CandidateSource.recommended,
      lastActivity: DateTime.now().subtract(const Duration(hours: 20)),
    ),
    ApplicantModel(
      id: 'cand-03',
      jobId: 'emp-j1',
      jobTitle: 'Senior Backend Engineer',
      candidateName: 'Arjun Venkataraman',
      headline: 'DevOps Engineer, Freshworks',
      candidatePhone: '+91 98407 22119',
      candidateEmail: 'arjun.v@example.com',
      experience: '6 yrs',
      location: 'Chennai',
      skills: ['Kubernetes', 'Terraform', 'AWS', 'CI/CD'],
      // No score: AI scoring was unavailable for this record, so it fell back to
      // rule matching. The UI shows that rather than inventing a number.
      aiMatchScore: null,
      status: 'Viewed',
      source: CandidateSource.external,
      sourceName: 'TalentBridge Feed',
      lastActivity: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ApplicantModel(
      id: 'cand-04',
      jobId: 'emp-j1',
      jobTitle: 'Senior Backend Engineer',
      candidateName: 'Wei Ling Tan',
      headline: 'Backend Engineer, Sea Group',
      candidatePhone: '+65 9134 0088',
      candidateEmail: 'weiling.tan@example.com',
      experience: '4 yrs',
      location: 'Singapore',
      skills: ['Java', 'Spring', 'MySQL'],
      aiMatchScore: 83,
      status: 'Interview Scheduled',
      source: CandidateSource.applied,
      lastActivity: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ApplicantModel(
      id: 'cand-05',
      jobId: 'emp-j1',
      jobTitle: 'Senior Backend Engineer',
      candidateName: 'Daniel Okonkwo',
      headline: 'Platform Engineer, Flutterwave',
      candidatePhone: '+234 803 221 4455',
      candidateEmail: 'd.okonkwo@example.com',
      experience: '7 yrs',
      location: 'Remote',
      skills: ['Go', 'gRPC', 'Postgres'],
      aiMatchScore: 61,
      status: 'Rejected',
      source: CandidateSource.recommended,
      lastActivity: DateTime.now().subtract(const Duration(days: 9)),
      archiveReason: 'Salary expectation',
      archivedAt: null,
      archivedBy: 'You',
    ),
    ApplicantModel(
      id: 'cand-06',
      jobId: 'emp-j2',
      jobTitle: 'Warehouse Supervisor',
      candidateName: 'Santosh Kumar',
      headline: 'Warehouse Team Lead, DB Schenker',
      candidatePhone: '+91 94421 23456',
      candidateEmail: 's.kumar@example.com',
      experience: '3 yrs',
      location: 'Singapore',
      skills: ['WMS', 'Forklift', 'Inventory', 'Safety'],
      aiMatchScore: 88,
      status: 'Contacted',
      source: CandidateSource.applied,
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  bool get isAuthenticated => _isAuthenticated;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  String get companyName => _companyName;
  String get phone => _phone;
  List<EmployerJobModel> get jobs => _jobs;
  List<ApplicantModel> get applicants => _applicants;

  int get contactCreditsTotal => _contactCreditsTotal;
  int get contactCreditsUsed => _contactCreditsUsed;
  int get contactCreditsRemaining => _contactCreditsTotal - _contactCreditsUsed;
  int get aiCreditsTotal => _aiCreditsTotal;
  int get aiCreditsUsed => _aiCreditsUsed;
  int get aiCreditsRemaining => _aiCreditsTotal - _aiCreditsUsed;

  /// What the AI entry point should show. Three distinct states, because
  /// "greyed out" without a reason is the most frustrating possible UI.
  AiAvailability get aiAvailability {
    if (!_aiEnabledOnPlan) return AiAvailability.disabled;
    if (aiCreditsRemaining <= 0) return AiAvailability.noCredits;
    return AiAvailability.live;
  }

  /// Active (non-archived) candidates for a job, optionally filtered by source.
  List<ApplicantModel> candidatesFor(String jobId, {CandidateSource? source}) => _applicants
      .where((a) => a.jobId == jobId && !a.isArchived && (source == null || a.source == source))
      .toList()
    ..sort((a, b) => (b.aiMatchScore ?? -1).compareTo(a.aiMatchScore ?? -1));

  /// Archived candidates for a job. Archiving is scoped to this company + job —
  /// the candidate remains in the Lucky Boss database and can be restored.
  List<ApplicantModel> archivedFor(String jobId) =>
      _applicants.where((a) => a.jobId == jobId && a.isArchived).toList();

  int countFor(String jobId, {CandidateSource? source}) => candidatesFor(jobId, source: source).length;

  void toggleDarkMode(bool val) {
    _isDarkMode = val;
    notifyListeners();
  }

  void setAuthenticated(bool val, {String? phone}) {
    _isAuthenticated = val;
    if (phone != null) _phone = phone;
    notifyListeners();
  }

  void updateApplicantStatus(String applicantId, String newStatus) {
    final idx = _applicants.indexWhere((a) => a.id == applicantId);
    if (idx != -1) {
      _applicants[idx].status = newStatus;
      notifyListeners();
    }
  }

  /// Spends one contact credit to reveal a candidate's phone and email.
  /// Returns false when there are no credits left, so the caller can say why
  /// instead of silently doing nothing.
  ///
  /// The server must charge the credit too — this only updates what is shown.
  bool revealContact(String applicantId) {
    final idx = _applicants.indexWhere((a) => a.id == applicantId);
    if (idx == -1) return false;
    if (_applicants[idx].contactRevealed) return true;
    if (contactCreditsRemaining <= 0) return false;

    _applicants[idx].contactRevealed = true;
    _contactCreditsUsed += 1;
    notifyListeners();
    return true;
  }

  void archiveCandidate(String applicantId, String reason, {String by = 'You'}) {
    final idx = _applicants.indexWhere((a) => a.id == applicantId);
    if (idx == -1) return;
    _applicants[idx]
      ..archiveReason = reason
      ..archivedAt = DateTime.now()
      ..archivedBy = by;
    notifyListeners();
  }

  void restoreCandidate(String applicantId) {
    final idx = _applicants.indexWhere((a) => a.id == applicantId);
    if (idx == -1) return;
    _applicants[idx]
      ..archiveReason = null
      ..archivedAt = null
      ..archivedBy = null;
    notifyListeners();
  }

  void postNewJob({
    required String title,
    required String category,
    required String location,
    required String minSalary,
    required String maxSalary,
    required String currency,
    String countryCode = 'SG',
    String workMode = 'On-site',
    String description = '',
    List<String> requiredSkills = const [],
    String experienceLevel = 'Mid Level',
    String jobType = 'Full-Time',
  }) {
    _jobs.insert(
      0,
      EmployerJobModel(
        id: 'emp-j${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        category: category,
        location: location,
        countryCode: countryCode,
        salaryDisplay: '$currency $minSalary - $maxSalary / mo',
        applicantsCount: 0,
        status: 'published',
        postedDate: DateTime.now(),
      ),
    );
    notifyListeners();

    // NOTE: this currently fails silently. EmployerApiService posts to
    // POST /api/v1/jobs, which is not a registered route — routes/api.php only
    // registers GET /jobs and GET /jobs/{job}. The job is created in local state
    // and never reaches the backend. Needs a real endpoint before launch.
    EmployerApiService.postJobToBackend(
      title: title,
      category: category,
      location: location,
      minSalary: minSalary,
      maxSalary: maxSalary,
      currency: currency,
      countryCode: countryCode,
      workMode: workMode,
      description: description,
    );
  }
}
