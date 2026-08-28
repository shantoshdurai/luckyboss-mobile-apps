import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/job_model.dart';
import '../models/purchase_record.dart';
import '../models/application_model.dart';
import '../models/feed_prompt.dart';
import '../models/seeker_profile_model.dart';
import '../services/auth_service.dart';
import '../services/profile_sync_service.dart';
import '../services/gemini_copilot_service.dart';
import '../services/api_service.dart';

class JobSeekerProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isProfileComplete = false;

  /// True while signed in to the seeded read-only demo account. Drives the
  /// in-app banner and disables write affordances; the server refuses the
  /// writes regardless, so this is presentation, not protection.
  bool _isDemoMode = false;
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
    // Third-party listings. Every one of these carries its provider name, and
    // the whole section is hidden when the admin switch is off.
    JobModel(
      id: 'job-ext-01',
      title: 'Backend Engineer (Payments)',
      companyName: 'Northwind Systems',
      countryCode: 'SG',
      location: 'Singapore',
      workMode: 'Hybrid',
      minSalary: '6,000',
      maxSalary: '8,500',
      currency: 'SGD',
      category: 'IT & Software',
      description: 'Listed through an authorised partner feed. Apply on the partner site.',
      requiredSkills: ['Java', 'Kafka', 'PostgreSQL'],
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
      source: JobSource.external,
      sourceName: 'TalentBridge Feed',
      closingDate: DateTime.now().add(const Duration(days: 2)),
    ),
    JobModel(
      id: 'job-ext-02',
      title: 'Warehouse Team Lead',
      companyName: 'Meridian Logistics',
      countryCode: 'MY',
      location: 'Johor Bahru, Malaysia',
      workMode: 'On-site',
      minSalary: '4,500',
      maxSalary: '6,000',
      currency: 'MYR',
      category: 'Logistics & Warehouse',
      description: 'Listed through an authorised recruitment partner.',
      requiredSkills: ['Warehouse Operations', 'Inventory', 'Site Safety'],
      postedDate: DateTime.now().subtract(const Duration(days: 5)),
      source: JobSource.external,
      sourceName: 'Approved Recruitment Partner',
    ),
  ];

  // Starts COMPLETELY EMPTY (No fake applications)
  final List<ApplicationModel> _myApplications = [];

  // --- Getters ---
  // ---------------------------------------------------------------------------
  // SPEC 28 / 80 — the three sections a job seeker dashboard must show, and the
  // profile-completion figure that drives everything else.
  // ---------------------------------------------------------------------------

  /// Mirrored from the admin "Third-Party Jobs" switch. When it is off the
  /// External section does not render at all — the spec is explicit that the
  /// whole table disappears rather than showing an empty state, because an
  /// empty section implies the feature exists and simply has no results.
  ///
  /// The server is the authority. This is a cached copy for rendering only.
  bool _externalJobsEnabled = true;
  bool get externalJobsEnabled => _externalJobsEnabled;
  void setExternalJobsEnabled(bool value) {
    _externalJobsEnabled = value;
    notifyListeners();
  }

  final Set<String> _savedJobIds = <String>{};
  List<JobModel> get savedJobs =>
      _allJobs.where((j) => _savedJobIds.contains(j.id)).toList();
  bool isSaved(String jobId) => _savedJobIds.contains(jobId);

  void toggleSaved(String jobId) {
    if (!_savedJobIds.remove(jobId)) _savedJobIds.add(jobId);
    notifyListeners();
  }

  /// Jobs Lucky Boss matched to this seeker, best match first, excluding
  /// anything they have already applied to — recommending a job someone has
  /// already applied for is noise, not a recommendation.
  List<JobModel> get recommendedJobs {
    final scored = _allJobs
        .where((j) => j.source == JobSource.luckyBoss && !hasApplied(j.id))
        // matchScoreFor returns null when the profile has no skills to match
        // on. Coercing to 0 here means those jobs fall out of the list below,
        // which is right: with no skills there is nothing to recommend from.
        .map((j) => (job: j, score: matchScoreFor(j) ?? 0.0))
        .where((e) => e.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.job).toList();
  }

  /// Third-party listings. Always empty when the admin switch is off, so no
  /// caller can accidentally render them.
  List<JobModel> get externalJobs => _externalJobsEnabled
      ? _allJobs.where((j) => j.source == JobSource.external).toList()
      : const [];

  /// The seeker's match against a job. Returns null when there is nothing to
  /// match on yet — a profile with no skills cannot be scored, and showing 0%
  /// would read as a bad match rather than an incomplete profile.
  double? matchScoreFor(JobModel job) {
    if (_profile.skills.isEmpty) return null;
    return job.calculateAiMatchPercent(_profile.skills, _profile.preferredCategory);
  }

  /// SPEC 30 — the dashboard leads with this number, so it has to mean
  /// something. Each field is weighted by how much it actually improves
  /// matching and employer visibility, not counted equally.
  /// Profile completion, weighted by what actually helps a candidate get hired.
  ///
  /// The weights are the single source of truth for both this number and the
  /// "+N%" on every profile boost card. They sum to exactly 100 — verified, not
  /// assumed: an earlier set totalled 110, so every card over-promised while the
  /// score silently clamped — a card promising +10% that moves the bar
  /// by three is worse than no card at all.
  static const Map<String, int> completionWeights = {
    'name': 5,
    'email': 5,
    'phone': 5,
    'skills': 20,
    'resume': 15,
    'headline': 8,
    'bio': 10,
    'category': 6,
    'department': 6,
    'photo': 5,
    'city': 5,
    'salary': 4,
    'projects': 3,
    'languages': 3,
  };

  /// Whether each weighted field is filled. Keyed by the same names.
  Map<String, bool> get completionState => {
        'name': _profile.name.trim().isNotEmpty,
        'email': _profile.email.trim().isNotEmpty,
        'phone': _profile.phone.trim().isNotEmpty,
        'skills': _profile.skills.isNotEmpty,
        'resume': _profile.resumeFileName != null,
        'headline': _profile.headline.trim().isNotEmpty,
        'bio': _profile.bio.trim().isNotEmpty,
        'category': _profile.preferredCategory.trim().isNotEmpty,
        'department': _profile.department.trim().isNotEmpty,
        'photo': (_profile.photoUrl ?? '').isNotEmpty,
        'city': _profile.currentCity.trim().isNotEmpty,
        'salary': _profile.expectedSalary.trim().isNotEmpty,
        'projects': _profile.projects.isNotEmpty,
        'languages': _profile.languages.isNotEmpty,
      };

  int get profileCompletion {
    final state = completionState;
    var earned = 0;
    completionWeights.forEach((key, weight) {
      if (state[key] == true) earned += weight;
    });
    return earned.clamp(0, 100);
  }

  /// What to ask for next. Naming the single highest-value missing field beats
  /// a generic "complete your profile" prompt nobody acts on.
  String? get nextProfileStep {
    if (_profile.skills.isEmpty) return 'Add your skills to start getting matched';
    if (_profile.resumeFileName == null) return 'Upload your resume so employers can shortlist you';
    if (_profile.bio.trim().isEmpty) return 'Add a short professional summary';
    if (_profile.name.trim().isEmpty) return 'Add your name';
    return null;
  }

  int get interviewCount => _myApplications
      .where((a) => a.stage == ApplicationStage.interview)
      .length;

  int get offerCount =>
      _myApplications.where((a) => a.stage == ApplicationStage.offer).length;

  // ---------------------------------------------------------------------------
  // SPEC 62-65 — candidate monetisation and purchase history.
  //
  // Applications are FREE by default and stay free until an admin turns
  // monetisation on and marks a specific job paid. That default matters: a job
  // board that charges people to apply by default is a different product.
  // ---------------------------------------------------------------------------

  bool _candidateMonetisationEnabled = true;
  bool get candidateMonetisationEnabled => _candidateMonetisationEnabled;
  void setCandidateMonetisation(bool v) {
    _candidateMonetisationEnabled = v;
    notifyListeners();
  }

  final List<PurchaseRecord> _purchases = [];
  List<PurchaseRecord> get purchases => List.unmodifiable(_purchases);

  /// Whether this job actually costs money for this seeker right now. Both the
  /// admin switch and the job's own fee have to agree.
  bool paymentRequiredFor(JobModel job) =>
      _candidateMonetisationEnabled && job.requiresPayment;

  /// Records a completed payment for a paid application. Called only after the
  /// gateway confirms — never optimistically, because a receipt for money that
  /// did not move is worse than no receipt.
  PurchaseRecord recordPurchase(JobModel job) {
    final record = PurchaseRecord(
      transactionId: 'LB-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      jobId: job.id,
      jobTitle: job.title,
      companyName: job.companyName,
      amount: job.applicationFee ?? 0,
      currency: job.applicationFeeCurrency ?? job.currency,
      paidAt: DateTime.now(),
    );
    _purchases.insert(0, record);
    notifyListeners();
    return record;
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDemoMode => _isDemoMode;
  bool get isProfileComplete => _isProfileComplete;
  String get selectedCountry => _selectedCountry;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  SeekerProfileModel get profile => _profile;
  List<ApplicationModel> get myApplications => _myApplications;

  /// Every job the candidate is allowed to search across.
  ///
  /// Respects the admin's third-party toggle (spec section 69): with external
  /// jobs off, partner listings must not be reachable through search either,
  /// or the switch only half works.
  List<JobModel> get searchableJobs => _externalJobsEnabled
      ? List.unmodifiable(_allJobs)
      : _allJobs.where((j) => j.source != JobSource.external).toList();

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
    final session = await AuthService.currentSession();
    _isAuthenticated = session != null;
    _isProfileComplete = await AuthService.isProfileComplete();
    _isDemoMode = session?.isDemo ?? false;

    if (session != null) {
      // Only fill blanks. A candidate who has since edited their profile in the
      // app should not have it overwritten by whatever the token was minted with.
      if (_profile.phone.isEmpty && (session.phone?.isNotEmpty ?? false)) {
        _profile.phone = session.phone!;
      }
      if (_profile.name.isEmpty && session.name.isNotEmpty) {
        _profile.name = session.name;
      }
      if (_profile.email.isEmpty && session.email.isNotEmpty) {
        _profile.email = session.email;
      }
    }

    notifyListeners();
  }

  /// Clears the session and every trace of the previous candidate.
  ///
  /// Resetting the in-memory profile matters as much as dropping the token: the
  /// provider outlives the sign-out navigation, so without this the next person
  /// to sign in on this device briefly sees the last one's name and skills.
  Future<void> signOut() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _isProfileComplete = false;
    _isDemoMode = false;
    _myApplications.clear();
    _savedJobIds.clear();
    _profile
      ..name = ''
      ..email = ''
      ..phone = ''
      ..bio = ''
      ..skills.clear()
      ..resumeFileName = null
      ..photoUrl = null
      ..currentCity = ''
      ..currentTitle = ''
      ..qualification = null
      ..course = ''
      ..passingYear = ''
      ..noticePeriod = ''
      ..isStudent = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // FEED PROMPTS
  //
  // The preference questions that used to be a fourth onboarding step. Asking
  // them inside the feed means a new candidate reaches the job list immediately
  // and answers at their own pace.
  // ---------------------------------------------------------------------------

  final Set<String> _answeredPrompts = {};
  final Set<String> _dismissedPrompts = {};
  bool? _feedFeedback;

  bool? get feedFeedback => _feedFeedback;

  void setFeedFeedback(bool value) {
    _feedFeedback = value;
    notifyListeners();
  }

  /// Prompts still worth asking, in priority order.
  ///
  /// Excludes anything answered or dismissed, and anything the profile already
  /// knows — a candidate who set their market during onboarding must not be
  /// asked for it again in the feed.
  List<FeedPrompt> get pendingPrompts => FeedPrompts.all.where((p) {
        if (_answeredPrompts.contains(p.id)) return false;
        if (_dismissedPrompts.contains(p.id)) return false;
        return switch (p.id) {
          FeedPrompts.preferredCountry => _profile.preferredCountry.isEmpty,
          FeedPrompts.expectedSalary => _profile.expectedSalary.isEmpty,
          FeedPrompts.workMode => _profile.workModes.isEmpty,
          FeedPrompts.availability => _profile.availability.isEmpty,
          FeedPrompts.relocate => _profile.openToRelocate == null,
          FeedPrompts.jobType => _profile.jobTypes.isEmpty,
          FeedPrompts.workPermit => _profile.hasWorkPermit == null,
          _ => true,
        };
      }).toList();

  void dismissPrompt(String id) {
    _dismissedPrompts.add(id);
    notifyListeners();
  }

  /// Records an answer onto the profile.
  ///
  /// The switch is exhaustive over the prompt ids rather than a generic map, so
  /// a new prompt cannot be added without deciding where its answer is stored.
  void answerPrompt(String id, Object value) {
    switch (id) {
      case FeedPrompts.preferredCountry:
        final code = switch (value as String) {
          'India' => 'IN',
          'Singapore' => 'SG',
          'Malaysia' => 'MY',
          _ => '',
        };
        _profile.preferredCountry = code;
        if (code.isNotEmpty) _selectedCountry = code;
      case FeedPrompts.expectedSalary:
        _profile.expectedSalary = value as String;
      case FeedPrompts.workMode:
        _profile.workModes = List<String>.from(value as List);
      case FeedPrompts.availability:
        _profile.availability = value as String;
      case FeedPrompts.relocate:
        _profile.openToRelocate = value as bool;
      case FeedPrompts.jobType:
        _profile.jobTypes = List<String>.from(value as List);
      case FeedPrompts.workPermit:
        _profile.hasWorkPermit = value as bool;
    }
    _answeredPrompts.add(id);
    notifyListeners();
  }

  void setDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }

  void setAuthenticated(bool val, {String? phone}) {
    _isAuthenticated = val;
    if (phone != null) _profile.phone = phone;
    notifyListeners();
  }

  // --- Profile Setup & Updating ---

  /// Folds the onboarding wizard's answers into the candidate profile.
  ///
  /// Name and email are absent by design. The wizard never asks for them —
  /// registration already did — so it must not be able to overwrite them.
  /// Passing them through here would reintroduce exactly the redundancy the
  /// rebuilt wizard exists to remove.
  void applyOnboarding({
    required bool isStudent,
    required String currentCity,
    String currentTitle = '',
    int yearsExperience = 0,
    String? qualification,
    String course = '',
    String passingYear = '',
    String noticePeriod = '',
    String? resumeFileName,
    String preferredCountry = '',
    List<String> workModes = const [],
    List<String> jobTypes = const [],
    String expectedSalary = '',
    String availability = '',
    bool? openToRelocate,
    bool? hasWorkPermit,
  }) {
    _profile.isStudent = isStudent;
    _profile.currentCity = currentCity.trim();
    _profile.currentTitle = currentTitle.trim();
    _profile.qualification = qualification;
    _profile.course = course;
    _profile.passingYear = passingYear;
    _profile.noticePeriod = noticePeriod;
    if (resumeFileName != null) _profile.resumeFileName = resumeFileName;
    _profile.preferredCountry = preferredCountry;
    _profile.workModes = List.of(workModes);
    _profile.jobTypes = List.of(jobTypes);
    _profile.expectedSalary = expectedSalary;
    _profile.availability = availability;
    _profile.openToRelocate = openToRelocate;
    _profile.hasWorkPermit = hasWorkPermit;

    // The country filter on the job list follows the market they chose, so the
    // first screen after onboarding shows jobs where they said they want to work.
    if (preferredCountry.isNotEmpty) _selectedCountry = preferredCountry;

    // Map declared years onto the app's experience bands, which is what job
    // matching actually filters on.
    _profile.experienceLevel = isStudent
        ? ExperienceLevel.entry
        : switch (yearsExperience) {
            <= 1 => ExperienceLevel.entry,
            <= 5 => ExperienceLevel.mid,
            <= 9 => ExperienceLevel.senior,
            _ => ExperienceLevel.lead,
          };

    notifyListeners();
  }


  /// Sets (or clears, with null) the candidate's profile photo.
  ///
  /// Called only after the server has confirmed the upload, so the URL held
  /// here always corresponds to a file that actually exists. Optimistically
  /// showing a local file before the upload lands would leave the avatar
  /// looking set while the server still had nothing.
  void setProfilePhoto(String? url) {
    _profile.photoUrl = (url != null && url.isEmpty) ? null : url;
    notifyListeners();
  }

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

  // ---------------------------------------------------------------------------
  // SERVER SYNC
  //
  // The profile lived only in memory until this existed, which is why a
  // candidate who completed onboarding was asked for everything again on the
  // next launch.
  // ---------------------------------------------------------------------------

  bool _syncing = false;

  /// Pushes the whole profile to `PUT /api/v1/job-seeker/profile`.
  ///
  /// Fire-and-forget from the UI's point of view: the local state is already
  /// updated and the user has moved on, so a failure is logged rather than
  /// thrown back at them mid-edit.
  Future<void> syncProfile() async {
    if (_syncing || _isDemoMode) return;
    _syncing = true;
    try {
      await ProfileSyncService.push(_profile);
    } finally {
      _syncing = false;
    }
  }

  /// Loads the stored profile on launch and merges it in.
  ///
  /// Server values win for anything the local profile has not set, which is the
  /// case that matters — a fresh install with a signed-in account should arrive
  /// fully populated rather than empty.
  Future<void> hydrateProfile() async {
    final remote = await ProfileSyncService.fetch();
    if (remote == null) return;
    ProfileSyncService.applyTo(_profile, remote);
    _isProfileComplete = _profile.skills.isNotEmpty;
    notifyListeners();
  }

  /// Writes one profile field and syncs it to the server.
  ///
  /// One entry point rather than a setter per field, so the editor sheet and
  /// the persistence call stay in step — a new field cannot be added to the UI
  /// without it also being saved.
  Future<void> setProfileField(String key, Object value) async {
    switch (key) {
      case 'headline':
        _profile.headline = value as String;
      case 'bio':
        _profile.bio = value as String;
      case 'department':
        _profile.department = value as String;
      case 'category':
        _profile.preferredCategory = value as String;
      case 'city':
        _profile.currentCity = value as String;
      case 'salary':
        _profile.expectedSalary = value as String;
      case 'phone':
        _profile.phone = value as String;
      case 'name':
        _profile.name = value as String;
      case 'projects':
        _profile.projects = List<String>.from(value as List);
      case 'languages':
        _profile.languages = List<String>.from(value as List);
      case 'skills':
        _profile.skills = List<String>.from(value as List);
    }
    notifyListeners();
    await syncProfile();
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
    await AuthService.markProfileComplete();
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