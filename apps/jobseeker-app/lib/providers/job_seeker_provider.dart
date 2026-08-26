import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/seeker_profile_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/gemini_copilot_service.dart';

class JobSeekerProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isProfileComplete = false;
  String _selectedCountry = 'IN'; // India default
  String _selectedCategory = 'All Roles';
  String _searchQuery = '';

  SeekerProfileModel _profile = SeekerProfileModel(
    name: 'Arjun Mehta',
    email: 'arjun.mehta@gmail.com',
    phone: '+91 98765-43210',
    experienceLevel: ExperienceLevel.mid,
    preferredCategory: 'IT & Software',
    bio: 'Full-stack mobile engineer with 4+ years of experience building cross-platform applications using Flutter, Dart, and cloud-native backend services.',
    skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Docker', 'Python', 'Node.js'],
    resumeFileName: 'Arjun_Mehta_Resume_2026.pdf',
    isVerified: true,
  );

  // --- Demo job data ---
  final List<JobModel> _allJobs = [
    JobModel(
      id: 'job-101',
      title: 'Lead AI & Mobile Flutter Engineer',
      companyName: 'Lucky Boss Global Tech',
      countryCode: 'IN',
      location: 'Bengaluru, India',
      workMode: 'Hybrid',
      minSalary: '1,20,000',
      maxSalary: '1,80,000',
      currency: 'INR',
      category: 'IT & Software',
      aiMatchPercent: 94.0,
      description: 'Lead next-generation mobile development with Flutter, Firebase OTP, and intelligent recruitment workflows.',
      requiredSkills: ['Flutter', 'Dart', 'Firebase', 'Python', 'REST APIs'],
      postedDate: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    JobModel(
      id: 'job-102',
      title: 'Senior Warehouse Operations Lead',
      companyName: 'Tuas Port Logistics Group',
      countryCode: 'SG',
      location: 'Jurong East, Singapore',
      workMode: 'On-site',
      minSalary: '3,800',
      maxSalary: '5,200',
      currency: 'SGD',
      category: 'Logistics & Warehouse',
      aiMatchPercent: 78.0,
      description: 'Oversee automated sorting systems, multi-tier inventory fulfillment, and workforce safety compliance.',
      requiredSkills: ['Warehouse Operations', 'Supply Chain', 'Forklift Operator'],
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JobModel(
      id: 'job-103',
      title: 'Cloud DevOps & Platform Engineer',
      companyName: 'Infosys Global Tech',
      countryCode: 'IN',
      location: 'Hyderabad, India',
      workMode: 'Remote',
      minSalary: '85,000',
      maxSalary: '1,40,000',
      currency: 'INR',
      category: 'IT & Software',
      aiMatchPercent: 88.0,
      description: 'Build robust Kubernetes clusters, automated CI/CD deployment pipelines, and microservice infrastructure.',
      requiredSkills: ['Docker', 'Kubernetes', 'Python', 'Firebase'],
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    JobModel(
      id: 'job-104',
      title: 'Cross-Border Supply Chain Manager',
      companyName: 'Tata Freight & Logistics',
      countryCode: 'MY',
      location: 'Kuala Lumpur, Malaysia',
      workMode: 'Hybrid',
      minSalary: '6,500',
      maxSalary: '9,000',
      currency: 'MYR',
      category: 'Logistics & Warehouse',
      aiMatchPercent: 82.0,
      description: 'Manage cross-border logistics lanes between Singapore, Malaysia, and regional distribution centers.',
      requiredSkills: ['Supply Chain', 'Warehouse Operations', 'Site Safety'],
      postedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final List<ApplicationModel> _myApplications = [
    ApplicationModel(
      id: 'app-001',
      jobId: 'job-101',
      jobTitle: 'Lead AI & Mobile Flutter Engineer',
      companyName: 'Lucky Boss Global Tech',
      location: 'Bengaluru, India',
      salaryDisplay: 'INR 1,20,000 - 1,80,000 / mo',
      matchScore: 94.0,
      stage: ApplicationStage.interview,
      appliedDate: DateTime.now().subtract(const Duration(days: 2)),
      interviewSchedule: 'Friday, 28 Aug 2026 • 02:30 PM (Google Meet)',
      recruiterRemarks: 'Impressive mobile portfolio. Scheduled for Stage 2 Technical Interview.',
    ),
    ApplicationModel(
      id: 'app-002',
      jobId: 'job-102',
      jobTitle: 'Senior Warehouse Operations Lead',
      companyName: 'Tuas Port Logistics Group',
      location: 'Singapore, Jurong East',
      salaryDisplay: 'SGD 3,800 - 5,200 / mo',
      matchScore: 78.0,
      stage: ApplicationStage.shortlisted,
      appliedDate: DateTime.now().subtract(const Duration(days: 4)),
      recruiterRemarks: 'Profile under review by Senior Hiring Team.',
    ),
  ];

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isProfileComplete => _isProfileComplete;
  String get selectedCountry => _selectedCountry;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  SeekerProfileModel get profile => _profile;
  List<ApplicationModel> get myApplications => _myApplications;

  List<JobModel> get filteredJobs {
    return _allJobs.where((job) {
      final matchesCountry = _selectedCountry.isEmpty || job.countryCode == _selectedCountry;
      final matchesCategory = _selectedCategory == 'All Roles' || job.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.companyName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCountry && matchesCategory && matchesSearch;
    }).toList();
  }

  // --- Auth & Profile State ---

  Future<void> checkAuthStatus() async {
    _isAuthenticated = await FirebaseAuthService.isLoggedIn();
    _isProfileComplete = await FirebaseAuthService.isProfileComplete();

    // If returning user, hydrate profile with saved phone
    if (_isAuthenticated && _isProfileComplete && _profile.name.isEmpty) {
      final phone = await FirebaseAuthService.getSavedPhone();
      _profile = SeekerProfileModel(
        name: 'Arjun Mehta',
        phone: phone ?? '+91 98765 43210',
        email: 'arjun.mehta@gmail.com',
        countryCode: 'IN',
        experienceLevel: ExperienceLevel.mid,
        preferredCategory: 'IT & Software',
        bio: 'Full-stack mobile engineer with 4+ years building cross-platform Flutter applications.',
        skills: ['Flutter', 'Dart', 'Python', 'Firebase', 'Docker', 'REST APIs'],
        isVerified: true,
      );
    }

    notifyListeners();
  }

  void setAuthenticated(bool val, {String? phone}) {
    _isAuthenticated = val;
    if (phone != null) _profile.phone = phone;
    notifyListeners();
  }

  // --- Profile Setup Wizard ---

  void updateProfileBasicInfo({
    required String name,
    required String email,
    required ExperienceLevel experienceLevel,
    required String preferredCategory,
  }) {
    _profile.name = name;
    _profile.email = email;
    _profile.experienceLevel = experienceLevel;
    _profile.preferredCategory = preferredCategory;
    notifyListeners();
  }

  /// Simulate uploading a resume and having AI extract structured data
  Future<SeekerProfileModel> parseResumeWithAI(String fileName) async {
    _isLoading = true;
    notifyListeners();

    final extractedData = await GeminiCopilotService.extractResumeData(fileName);
    final extracted = SeekerProfileModel.fromExtractedJson(
      extractedData,
      phone: _profile.phone,
    );

    // Merge: keep user-entered name/email if they already filled Step 1
    if (_profile.name.isNotEmpty) extracted.name = _profile.name;
    if (_profile.email.isNotEmpty) extracted.email = _profile.email;
    extracted.resumeFileName = fileName;

    _profile = extracted;
    _isLoading = false;
    notifyListeners();
    return extracted;
  }

  void updateProfileFromExtraction({
    String? bio,
    List<String>? skills,
    ExperienceLevel? experienceLevel,
  }) {
    if (bio != null) _profile.bio = bio;
    if (skills != null) _profile.skills = skills;
    if (experienceLevel != null) _profile.experienceLevel = experienceLevel;
    notifyListeners();
  }

  Future<void> completeProfileSetup() async {
    _profile.isVerified = true;
    _isProfileComplete = true;
    await FirebaseAuthService.markProfileComplete();
    notifyListeners();
  }

  // --- Job Browsing ---

  void setCountry(String code) {
    _selectedCountry = code;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool hasApplied(String jobId) {
    return _myApplications.any((a) => a.jobId == jobId);
  }

  Future<bool> applyToJob(JobModel job) async {
    if (hasApplied(job.id)) return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _myApplications.insert(
      0,
      ApplicationModel(
        id: 'app-${DateTime.now().millisecondsSinceEpoch}',
        jobId: job.id,
        jobTitle: job.title,
        companyName: job.companyName,
        location: job.location,
        salaryDisplay: job.salaryDisplay,
        matchScore: job.aiMatchPercent,
        stage: ApplicationStage.applied,
        appliedDate: DateTime.now(),
        recruiterRemarks: 'Application submitted successfully. Waiting for recruiter review.',
      ),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void addSkill(String skill) {
    if (!_profile.skills.contains(skill)) {
      _profile.skills.add(skill);
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    _profile.skills.remove(skill);
    notifyListeners();
  }
}