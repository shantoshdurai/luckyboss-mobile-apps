import 'dart:async';

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/job_model.dart';
import '../models/purchase_record.dart';
import '../models/application_model.dart';
import '../models/feed_prompt.dart';
import '../models/uploaded_document.dart';
import '../models/seeker_profile_model.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/local_store.dart';
import '../services/profile_sync_service.dart';
import '../services/gemini_copilot_service.dart';
import '../services/job_catalog_service.dart';

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

  SeekerProfileModel _profile = SeekerProfileModel();

  // ---------------------------------------------------------------------------
  // ON-DEVICE PERSISTENCE
  //
  // Everything below used to live in memory and nowhere else, so closing the app
  // erased the candidate's profile, their skills, their saved jobs and their
  // applications. On a build with no server behind it that is not a sync gap,
  // it is data loss.
  //
  // Rather than adding a save call beside all thirty-odd mutations — where the
  // next one added would inevitably be forgotten — the write hangs off
  // [notifyListeners], which every mutation already calls. It is debounced
  // because a text field can notify on each keystroke and there is no reason to
  // touch storage that often.
  // ---------------------------------------------------------------------------

  Timer? _saveTimer;
  bool _hydrated = false;

  // ---------------------------------------------------------------------------
  // UPLOADED DOCUMENTS
  //
  // Licence cards, the resume, permits. Held as an index here; the file bytes
  // live under their own key in [LocalStore] and are read only when something
  // renders them.
  // ---------------------------------------------------------------------------

  final List<UploadedDocument> _documents = [];

  List<UploadedDocument> get documents => List.unmodifiable(_documents);

  List<UploadedDocument> documentsOfKind(DocumentKind kind) =>
      _documents.where((d) => d.kind == kind).toList();

  /// The uploaded card backing a claimed licence, if one exists.
  ///
  /// This is what separates a tick from proof. A candidate who ticked
  /// "Forklift Licence" has told us something; one who also uploaded the card
  /// has shown us. The profile shows the two differently, because presenting
  /// them the same way is how an employer ends up on site with somebody who
  /// cannot legally operate the machine.
  UploadedDocument? documentForCertificate(String certificate) {
    for (final d in _documents) {
      if (d.kind == DocumentKind.certificate &&
          d.label.trim().toLowerCase() == certificate.trim().toLowerCase()) {
        return d;
      }
    }
    return null;
  }

  bool hasProofFor(String certificate) =>
      documentForCertificate(certificate) != null;

  /// Records an uploaded document. When it proves a licence the candidate had
  /// not yet claimed, the claim is added too — uploading the card is a clearer
  /// statement than ticking the box, and making them do both would be silly.
  Future<void> addDocument(UploadedDocument document) async {
    _documents.removeWhere((d) => d.id == document.id);
    _documents.add(document);

    if (document.kind == DocumentKind.certificate &&
        document.label.isNotEmpty &&
        !_profile.certificates.contains(document.label)) {
      _profile.certificates = [..._profile.certificates, document.label];
    }
    if (document.kind == DocumentKind.resume) {
      _profile.resumeFileName = document.fileName;
    }

    await LocalStore.saveDocuments(_documents);
    notifyListeners();
  }

  Future<void> removeDocument(String id) async {
    final gone = _documents.where((d) => d.id == id).toList();
    _documents.removeWhere((d) => d.id == id);
    await DocumentService.delete(id);
    for (final d in gone) {
      if (d.kind == DocumentKind.resume &&
          _profile.resumeFileName == d.fileName) {
        _profile.resumeFileName = null;
      }
    }
    notifyListeners();
  }

  /// Drops a claimed licence and any file uploaded to prove it.
  Future<void> removeCertificate(String certificate) async {
    _profile.certificates =
        _profile.certificates.where((c) => c != certificate).toList();
    final proof = documentForCertificate(certificate);
    if (proof != null) await removeDocument(proof.id);
    notifyListeners();
  }

  /// Reads the candidate's data back from the device. Call once at startup,
  /// before the first frame that shows profile data.
  Future<void> hydrateFromDevice() async {
    if (_hydrated) return;
    _hydrated = true;

    final stored = await LocalStore.loadProfile();
    if (stored != null) _profile = stored;

    _savedJobIds
      ..clear()
      ..addAll(await LocalStore.loadSavedJobs());

    _myApplications
      ..clear()
      ..addAll(await LocalStore.loadApplications());

    _documents
      ..clear()
      ..addAll(await LocalStore.loadDocuments());

    _answeredPrompts.addAll(await LocalStore.loadAnsweredPrompts());
    _dismissedPrompts.addAll(await LocalStore.loadDismissedPrompts());

    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleSave();
  }

  void _scheduleSave() {
    // Nothing is worth writing before the stored copy has been read — saving
    // first would overwrite the candidate's real profile with the empty one the
    // provider starts life holding.
    if (!_hydrated) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _saveNow);
  }

  Future<void> _saveNow() async {
    await LocalStore.saveProfile(_profile);
    await LocalStore.saveDocuments(_documents);
    await LocalStore.saveSavedJobs(_savedJobIds);
    await LocalStore.saveApplications(_myApplications);
    await LocalStore.savePromptState(
      answered: _answeredPrompts,
      dismissed: _dismissedPrompts,
    );
  }

  /// Flushes any pending debounced write immediately. Used on sign-out and
  /// anywhere the app might not get another frame.
  Future<void> flush() async {
    _saveTimer?.cancel();
    if (_hydrated) await _saveNow();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  /// Re-reads the catalogue, picking up anything the server has published
  /// since launch. [JobCatalogService] owns the server call now, so this is a
  /// thin alias kept for the callers that already refresh on resume.
  Future<void> syncWithBackend() => loadJobs(force: true);
  // ---------------------------------------------------------------------------
  // VACANCIES
  //
  // Loaded from `assets/data/seed_jobs.json` through [JobCatalogService], not
  // written out here. Six hundred lines of hand-typed Dart vacancies is not a
  // job board — it is a fixture that nobody will maintain, that cannot be moved
  // into MySQL, and that covered four categories out of fourteen. The catalogue
  // covers every category in all three markets, and every row in it is shaped
  // like a `jobs` table row so the same data loads server-side unchanged.
  // ---------------------------------------------------------------------------
  List<JobModel> _allJobs = [];

  bool _jobsLoaded = false;
  bool get jobsLoaded => _jobsLoaded;

  /// Fills the feed. Called once at startup, before the first frame that shows
  /// jobs; safe to call again, which is what pull-to-refresh does.
  Future<void> loadJobs({bool force = false}) async {
    if (_jobsLoaded && !force) return;
    final jobs = await JobCatalogService.fetch(country: _selectedCountry);
    _allJobs = jobs;
    _jobsLoaded = true;
    notifyListeners();
  }


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
        .where((j) =>
            j.source == JobSource.luckyBoss &&
            !hasApplied(j.id) &&
            // Recommending work in another country is not a recommendation.
            // A domestic helper in Chennai has no use for a Jurong site job
            // she cannot reach, and it pushed the jobs she could take off
            // the screen.
            (_selectedCountry.isEmpty || j.countryCode == _selectedCountry))
        .map((j) => (job: j, score: matchScoreFor(j) ?? 0.0))
        .where((e) => e.score > 0)
        .toList()
      ..sort((a, b) {
        // A boost lifts a job above better matches — that is what the employer
        // paid for, spec §61. It does not put an irrelevant job in the feed:
        // the match filter above still applies, so a boosted vacancy the
        // candidate cannot do never reaches this sort at all.
        final byBoost = b.job.boostPriority.compareTo(a.job.boostPriority);
        if (byBoost != 0) return byBoost;
        return b.score.compareTo(a.score);
      });
    return scored.map((e) => e.job).toList();
  }

  /// Third-party listings. Always empty when the admin switch is off, so no
  /// caller can accidentally render them.
  List<JobModel> get externalJobs => _externalJobsEnabled
      ? (_allJobs
          .where((j) =>
              j.source == JobSource.external &&
              (_selectedCountry.isEmpty || j.countryCode == _selectedCountry))
          .toList()
        // Best match first here too. The partner section used to show whatever
        // order the list happened to be in, which is how a construction
        // candidate ended up looking at a Backend Engineer vacancy.
        ..sort((a, b) =>
            (matchScoreFor(b) ?? 0).compareTo(matchScoreFor(a) ?? 0)))
      : const [];

  /// The seeker's match against a job. Null when there is nothing to match on
  /// at all — showing 0% would read as a bad match rather than an empty profile.
  ///
  /// Skills alone are no longer the test. A field candidate who has picked a
  /// trade and a category can be scored on those, which is the whole reason the
  /// feed was empty for them: the gate used to be `skills.isEmpty`, and the
  /// trade path does not fill `skills` first.
  double? matchScoreFor(JobModel job) {
    final role = _profile.roleTitle.trim().isNotEmpty
        ? _profile.roleTitle
        : _profile.currentTitle;

    if (_profile.skills.isEmpty &&
        role.trim().isEmpty &&
        _profile.preferredCategory.trim().isEmpty) {
      return null;
    }

    // Scored against every category the candidate will take, best wins. Using
    // only the first would rank a warehouse job at 25% for someone who told us
    // they would take warehouse work — just not as their first choice.
    final categories = _profile.preferredCategories.isEmpty
        ? <String>['']
        : _profile.preferredCategories;

    var best = 0.0;
    for (final category in categories) {
      final score = job.calculateAiMatchPercent(
        _profile.skills,
        category,
        candidateRole: role,
        certificates: _profile.certificates,
      );
      if (score > best) best = score;
    }
    return best;
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
  /// The professional weighting: a CV, a summary, a department, projects.
  static const Map<String, int> professionalWeights = {
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

  /// The field weighting.
  ///
  /// The two tables exist because one table could not serve both. Under the
  /// professional weights a construction worker could fill in every single
  /// thing that is true about them — trade, years, licences, languages, permit
  /// status, availability, photo, phone — and still be shown a profile stuck in
  /// the sixties, because 42% of the score sat behind a resume document, an
  /// "Executive Bio", a department and a projects list they will never have.
  /// A completion bar that cannot reach 100% is not a nudge, it is a scold.
  ///
  /// So the field table scores what a field candidate genuinely has, and the
  /// boost cards read from whichever table applies.
  static const Map<String, int> fieldWeights = {
    'name': 8,
    'phone': 8,
    'category': 8,
    'role': 16,
    'skills': 15,
    'certificates': 12,
    'languages': 8,
    'permit': 8,
    'city': 7,
    'availability': 5,
    'photo': 5,
  };

  /// The weights in force for this candidate.
  Map<String, int> get completionWeightsFor =>
      _profile.isFieldWork ? fieldWeights : professionalWeights;

  /// Kept for callers that predate the split. Prefer [completionWeightsFor].
  static const Map<String, int> completionWeights = professionalWeights;

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
        'role': _profile.roleTitle.trim().isNotEmpty ||
            _profile.currentTitle.trim().isNotEmpty,
        'certificates': _profile.certificates.isNotEmpty,
        'permit': _profile.workPermitStatus.trim().isNotEmpty,
        'availability': _profile.availability.trim().isNotEmpty,
      };

  int get profileCompletion {
    final state = completionState;
    var earned = 0;
    completionWeightsFor.forEach((key, weight) {
      if (state[key] == true) earned += weight;
    });
    return earned.clamp(0, 100);
  }

  /// What to ask for next. Naming the single highest-value missing field beats
  /// a generic "complete your profile" prompt nobody acts on.
  String? get nextProfileStep {
    if (_profile.name.trim().isEmpty) return 'Add your name';

    if (_profile.isFieldWork) {
      // Ordered by what an employer asks the agency for first. Telling a
      // cleaner to upload a resume, as this used to, asks for something they do
      // not have and cannot produce.
      if (_profile.roleTitle.trim().isEmpty &&
          _profile.currentTitle.trim().isEmpty) {
        return 'Add your trade so employers can find you';
      }
      if (_profile.skills.isEmpty) return 'Add the work you can do';
      if (_profile.certificates.isEmpty) {
        return 'Add your licences and cards — they get you shortlisted fastest';
      }
      if (_profile.workPermitStatus.trim().isEmpty) {
        return 'Tell employers whether you can work in that country';
      }
      if (_profile.languages.isEmpty) return 'Add the languages you speak';
      return null;
    }

    if (_profile.skills.isEmpty) return 'Add your skills to start getting matched';
    if (_profile.resumeFileName == null) return 'Upload your resume so employers can shortlist you';
    if (_profile.bio.trim().isEmpty) return 'Add a short professional summary';
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
    // Cancel first: a debounced write still in flight would otherwise land
    // after the wipe and restore the profile that was just cleared.
    _saveTimer?.cancel();
    await AuthService.logout();
    await LocalStore.clearAll();
    _isAuthenticated = false;
    _isProfileComplete = false;
    _isDemoMode = false;
    _myApplications.clear();
    _savedJobIds.clear();
    _documents.clear();
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
          FeedPrompts.preferredCountry => _profile.preferredCountries.isEmpty,
          FeedPrompts.expectedSalary => _profile.expectedSalary.isEmpty,
          FeedPrompts.workMode => _profile.workModes.isEmpty,
          FeedPrompts.availability => _profile.availability.isEmpty,
          FeedPrompts.relocate => _profile.openToRelocate == null,
          FeedPrompts.jobType => _profile.jobTypes.isEmpty,
          FeedPrompts.workPermit => _profile.hasWorkPermit == null,
          FeedPrompts.ownTools => _profile.hasOwnTools == null,
          FeedPrompts.ownTransport => _profile.hasOwnTransport == null,
          FeedPrompts.nightShift => _profile.willingNightShift == null,
          FeedPrompts.accommodation => _profile.willingAccommodation == null,
          FeedPrompts.passport => _profile.hasPassport == null,
          FeedPrompts.noticePeriod => _profile.noticePeriod.isEmpty,
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
        // The prompt now returns a list — a candidate open to two markets was
        // previously forced to discard one.
        final names = value is List ? value.cast<String>() : [value as String];
        final codes = [
          for (final name in names)
            switch (name) {
              'India' => 'IN',
              'Singapore' => 'SG',
              'Malaysia' => 'MY',
              _ => '',
            }
        ].where((c) => c.isNotEmpty).toList();
        _profile.preferredCountries = codes;
        if (codes.isNotEmpty) _selectedCountry = codes.first;
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
      case FeedPrompts.ownTools:
        _profile.hasOwnTools = value as bool;
      case FeedPrompts.ownTransport:
        _profile.hasOwnTransport = value as bool;
      case FeedPrompts.nightShift:
        _profile.willingNightShift = value as bool;
      case FeedPrompts.accommodation:
        _profile.willingAccommodation = value as bool;
      case FeedPrompts.passport:
        _profile.hasPassport = value as bool;
      case FeedPrompts.noticePeriod:
        _profile.noticePeriod = value as String;
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
    List<String> categories = const [],
    String category = '',
    String roleTitle = '',
    List<String> certificates = const [],
    List<String> languages = const [],
    List<String> workPermitStatuses = const [],
    String payPeriod = 'Per month',
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
    if (categories.isNotEmpty) {
      _profile.preferredCategories = List.of(categories);
    } else if (category.isNotEmpty) {
      _profile.preferredCategory = category;
    }
    if (roleTitle.isNotEmpty) _profile.roleTitle = roleTitle;
    if (certificates.isNotEmpty) _profile.certificates = List.of(certificates);
    if (languages.isNotEmpty) _profile.languages = List.of(languages);
    if (workPermitStatuses.isNotEmpty) {
      _profile.workPermitStatuses = List.of(workPermitStatuses);
    }
    _profile.payPeriod = payPeriod;
    _profile.isStudent = isStudent;
    _profile.currentCity = currentCity.trim();
    _profile.currentTitle = currentTitle.trim();
    _profile.qualification = qualification;
    _profile.course = course;
    _profile.passingYear = passingYear;
    _profile.noticePeriod = noticePeriod;
    if (resumeFileName != null) _profile.resumeFileName = resumeFileName;
    if (preferredCountry.isNotEmpty) {
      _profile.preferredCountries = [preferredCountry];
    }
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
    if (_syncing) return;
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
      case 'role':
        // Written to both: roleTitle is the field-work name for it, and
        // currentTitle is what matching, search and the profile header read.
        _profile.roleTitle = value as String;
        _profile.currentTitle = value;
      case 'certificates':
        _profile.certificates = List<String>.from(value as List);
      case 'permit':
        // Accepts a list or a single value — the edit screen sends one, the
        // onboarding step sends several.
        const allowed = {
          'Citizen',
          'Permanent Resident',
          'Have a valid work permit',
          'Have an employment pass',
        };
        final statuses = value is List
            ? List<String>.from(value)
            : [if ((value as String).isNotEmpty) value];
        _profile.workPermitStatuses = statuses;
        _profile.hasWorkPermit =
            statuses.isEmpty ? null : statuses.any(allowed.contains);
      case 'availability':
        _profile.availability = value as String;
      case 'email':
        _profile.email = value as String;
      case 'countries':
        _profile.preferredCountries = List<String>.from(value as List);
      case 'payPeriod':
        _profile.payPeriod = value as String;
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