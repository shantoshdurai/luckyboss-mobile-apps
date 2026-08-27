import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/seeker_profile_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/gemini_copilot_service.dart';
import '../services/api_service.dart';

class JobSeekerProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isProfileComplete = false;
  String _selectedCountry = 'IN'; // India default
  String _selectedCategory = 'All Roles';
  String _searchQuery = '';

  final SeekerProfileModel _profile = SeekerProfileModel(
    name: '',
    email: '',
    phone: '',
    experienceLevel: ExperienceLevel.mid,
    preferredCategory: 'IT & Software',
    bio: '',
    skills: [],
    resumeFileName: null,
    isVerified: false,
  );

  /// Synchronize live job listings from the Laravel Backend
  Future<void> syncWithBackend() async {
    final liveJobs = await ApiService.fetchLiveJobs(country: _selectedCountry);
    if (liveJobs != null && liveJobs.isNotEmpty) {
      for (final liveJob in liveJobs) {
        final idx = _allJobs.indexWhere((j) => j.id == liveJob.id);
        if (idx == -1) {
          _allJobs.insert(0, liveJob);
        }
      }
      notifyListeners();
    }
  }

  // --- Real Job Database with specific required skills ---
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
      description: 'Oversee automated sorting systems, multi-tier inventory fulfillment, and workforce safety compliance.',
      requiredSkills: ['Warehouse Operations', 'Supply Chain', 'Forklift Operator', 'Site Safety'],
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
      description: 'Design CI/CD automation pipelines, Kubernetes clusters, and multi-region cloud deployment architectures.',
      requiredSkills: ['Docker', 'Kubernetes', 'AWS', 'Python', 'CI/CD'],
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    JobModel(
      id: 'job-104',
      title: 'Regional Supply Chain Manager',
      companyName: 'Petronas Supply Solutions',
      countryCode: 'MY',
      location: 'Kuala Lumpur, Malaysia',
      workMode: 'Hybrid',
      minSalary: '6,500',
      maxSalary: '9,000',
      currency: 'MYR',
      category: 'Logistics & Warehouse',
      description: 'Manage cross-border logistics lanes between Singapore, Malaysia, and regional distribution centers.',
      requiredSkills: ['Supply Chain', 'Warehouse Operations', 'Site Safety'],
      postedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    JobModel(
      id: 'job-105',
      title: 'Senior Financial Analyst',
      companyName: 'DBS Treasury Solutions',
      countryCode: 'SG',
      location: 'Marina Bay, Singapore',
      workMode: 'Hybrid',
      minSalary: '5,500',
      maxSalary: '7,800',
      currency: 'SGD',
      category: 'Finance',
      description: 'Conduct corporate valuation models, financial variance reporting, and cross-border tax compliance.',
      requiredSkills: ['Financial Analysis', 'GST Compliance', 'Data Analysis'],
      postedDate: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  // Starts COMPLETELY EMPTY (No fake applications)
  final List<ApplicationModel> _myApplications = [];

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

    if (_isAuthenticated) {
      final phone = await FirebaseAuthService.getSavedPhone();
      if (phone != null && _profile.phone.isEmpty) {
        _profile.phone = phone;
      }
    }

    notifyListeners();
  }

  void setAuthenticated(bool val, {String? phone}) {
    _isAuthenticated = val;
    if (phone != null) _profile.phone = phone;
    notifyListeners();
  }

  // --- Profile Setup & Updating ---
  void updateProfileBasicInfo({
    required String name,
    required String email,
    ExperienceLevel? experienceLevel,
    String? preferredCategory,
  }) {
    _profile.name = name;
    _profile.email = email;
    if (experienceLevel != null) _profile.experienceLevel = experienceLevel;
    if (preferredCategory != null) _profile.preferredCategory = preferredCategory;
    notifyListeners();
  }

  void updateAllProfileDetails({
    required String name,
    required String email,
    required String phone,
    required ExperienceLevel experienceLevel,
    required String preferredCategory,
    required List<String> skills,
    required String bio,
    String? resumeFileName,
  }) {
    _profile.name = name;
    _profile.email = email;
    _profile.phone = phone;
    _profile.experienceLevel = experienceLevel;
    _profile.preferredCategory = preferredCategory;
    _profile.skills = List.from(skills);
    _profile.bio = bio;
    _profile.resumeFileName = resumeFileName;
    notifyListeners();
  }

  void updateBio(String newBio) {
    _profile.bio = newBio;
    notifyListeners();
  }

  void updateResume(String? fileName) {
    _profile.resumeFileName = fileName;
    notifyListeners();
  }

  Future<void> parseResumeWithAI(String fileName) async {
    _isLoading = true;
    notifyListeners();

    _profile.resumeFileName = fileName;
    final extracted = await GeminiCopilotService.extractResumeData(fileName);

    if (extracted['bio'] != null && extracted['bio'].toString().isNotEmpty) {
      _profile.bio = extracted['bio'];
    }

    final newSkills = List<String>.from(extracted['skills'] ?? []);
    for (final s in newSkills) {
      if (!_profile.skills.contains(s)) {
        _profile.skills.add(s);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !_profile.skills.contains(trimmed)) {
      _profile.skills.add(trimmed);
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    _profile.skills.remove(skill);
    notifyListeners();
  }

  void setSkills(List<String> skills) {
    _profile.skills = List.from(skills);
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

    final matchScore = job.calculateAiMatchPercent(_profile.skills, _profile.preferredCategory);

    _myApplications.insert(
      0,
      ApplicationModel(
        id: 'app-${DateTime.now().millisecondsSinceEpoch}',
        jobId: job.id,
        jobTitle: job.title,
        companyName: job.companyName,
        location: job.location,
        salaryDisplay: job.salaryDisplay,
        matchScore: matchScore,
        stage: ApplicationStage.applied,
        appliedDate: DateTime.now(),
        recruiterRemarks: 'Application submitted directly to hiring manager.',
      ),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }
}