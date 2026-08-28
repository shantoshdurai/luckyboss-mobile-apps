import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/candidate.dart';
import '../models/employer_job.dart';
import '../models/job_boost.dart';
import '../models/uploaded_document.dart';
import '../services/candidate_pool_service.dart';
import '../services/local_store.dart';
import '../widgets/ledger_components.dart';

/// The employer's state, and the only place it is written down.
///
/// Rebuilt on the same foundation as the job seeker provider, for the same
/// reason: this app ships as a standalone APK, and the version it replaces kept
/// its jobs, its candidates and its plan counters in memory alone. A hiring
/// manager could complete the whole post-a-vacancy wizard, close the app, and
/// find nothing there on reopening.
///
/// Persistence hangs off [notifyListeners] rather than being called by hand at
/// every mutation, so a method added later cannot forget to save.
class EmployerProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Session and company
  // ---------------------------------------------------------------------------

  bool _isAuthenticated = false;
  bool _isDarkMode = false;
  CompanyProfile _company = const CompanyProfile();

  bool get isAuthenticated => _isAuthenticated;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  CompanyProfile get company => _company;

  String get companyName =>
      _company.name.isEmpty ? 'Your company' : _company.name;

  /// Stable id for this company, minted on first use so a posting always has
  /// something to join on later.
  String get companyId {
    if (_company.id.isNotEmpty) return _company.id;
    final id = 'co-${DateTime.now().microsecondsSinceEpoch}';
    _company = _company.copyWith(id: id);
    return id;
  }

  /// Whether this company may publish and spend credits. See [CompanyStatus].
  bool get canPost => _company.canPost;

  /// Submits the registration for checking.
  ///
  /// Deliberately lands on [CompanyStatus.submitted] and stops there. The app
  /// must never verify itself — that is the same lie as the old fake auth, and
  /// an employer badge nobody checked is worse than no badge at all.
  void submitForVerification() {
    _company = _company.copyWith(
      id: companyId,
      status: CompanyStatus.submitted,
      submittedAt: DateTime.now(),
    );
    notifyListeners();
  }
  String get phone => _company.phone;

  // ---------------------------------------------------------------------------
  // Plan entitlements.
  //
  // Mirrored from the server for display only. Laravel must enforce these
  // independently — a client that decides its own limits can be bypassed by
  // anyone who can call the endpoint directly.
  // ---------------------------------------------------------------------------

  final int _contactCreditsTotal = 250;
  int _contactCreditsUsed = 0;
  final int _aiCreditsTotal = 100;
  final int _aiCreditsUsed = 0;
  final bool _aiEnabledOnPlan = true;

  int get contactCreditsTotal => _contactCreditsTotal;
  int get contactCreditsUsed => _contactCreditsUsed;
  int get contactCreditsRemaining => _contactCreditsTotal - _contactCreditsUsed;
  int get aiCreditsTotal => _aiCreditsTotal;
  int get aiCreditsUsed => _aiCreditsUsed;
  int get aiCreditsRemaining => _aiCreditsTotal - _aiCreditsUsed;

  /// Subscription expiry, spec §38 and §78.
  DateTime get subscriptionExpiry =>
      DateTime.now().add(const Duration(days: 47));

  /// Three distinct states rather than a greyed-out button. "Disabled" without
  /// a reason is the most frustrating possible UI.
  AiAvailability get aiAvailability {
    if (!_aiEnabledOnPlan) return AiAvailability.disabled;
    if (aiCreditsRemaining <= 0) return AiAvailability.noCredits;
    return AiAvailability.live;
  }

  // ---------------------------------------------------------------------------
  // Jobs and candidates
  // ---------------------------------------------------------------------------

  final List<EmployerJobModel> _jobs = [];
  final List<Candidate> _pool = [];
  final Map<String, List<String>> _notes = {};
  final List<EmployerCharge> _charges = [];
  final List<UploadedDocument> _documents = [];

  List<EmployerJobModel> get jobs => List.unmodifiable(_jobs);

  List<EmployerJobModel> get publishedJobs =>
      _jobs.where((j) => j.status == JobStatus.published).toList();

  /// Live vacancies in the order a candidate sees them: boosted first, by
  /// weight, then newest.
  ///
  /// This is what the employer is buying — see [boostJob]. Sorting here rather
  /// than in the UI keeps the employer's preview and the candidate's feed in
  /// agreement, which matters when someone has just paid for the position.
  List<EmployerJobModel> get rankedJobs {
    final ranked = [...publishedJobs]..sort((a, b) {
        final byBoost = b.boostPriority.compareTo(a.boostPriority);
        if (byBoost != 0) return byBoost;
        return b.postedDate.compareTo(a.postedDate);
      });
    return ranked;
  }

  List<EmployerJobModel> get boostedJobs =>
      _jobs.where((j) => j.isBoosted).toList();

  // --------------------------------------------------- promotion, spec §61

  /// Buys a boost for a job.
  ///
  /// Refuses for an unverified company, like every other paid action — selling
  /// prominence to a business nobody has checked is the opposite of what the
  /// verification gate is for.
  ///
  /// The charge is recorded locally so the payment history (spec §66) is
  /// honest on a standalone build. When billing exists this becomes the point
  /// where the server is asked to take the money, and the boost is applied only
  /// once it confirms.
  bool boostJob(String jobId, BoostType type, int days) {
    if (!canPost) return false;
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return false;

    final job = _jobs[index];
    final amount = BoostPricing.priceFor(type, days, job.countryCode);
    final currency = BoostPricing.currencyFor(job.countryCode);
    final now = DateTime.now();

    _jobs[index] = job.copyWith(
      boost: JobBoost(
        type: type,
        startsAt: now,
        endsAt: now.add(Duration(days: days)),
        amount: amount,
        currency: currency,
      ),
    );

    _charges.insert(
      0,
      EmployerCharge(
        id: 'chg-${now.microsecondsSinceEpoch}',
        description: '${type.label} · ${job.title} · $days days',
        amount: amount,
        currency: currency,
        chargedAt: now,
        jobId: jobId,
      ),
    );

    notifyListeners();
    return true;
  }

  /// Ends a boost early. The charge stands — the days were bought.
  void cancelBoost(String jobId) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    final job = _jobs[index];
    if (job.boost == null) return;
    _jobs[index] = EmployerJobModel(
      id: job.id,
      role: job.role,
      title: job.title,
      category: job.category,
      companyId: job.companyId,
      companyName: job.companyName,
      companyLogoUrl: job.companyLogoUrl,
      companyVerified: job.companyVerified,
      companyType: job.companyType,
      location: job.location,
      countryCode: job.countryCode,
      minSalary: job.minSalary,
      maxSalary: job.maxSalary,
      currency: job.currency,
      payPeriod: job.payPeriod,
      workMode: job.workMode,
      shift: job.shift,
      description: job.description,
      requiredSkills: job.requiredSkills,
      requiredCertificates: job.requiredCertificates,
      accommodationProvided: job.accommodationProvided,
      transportProvided: job.transportProvided,
      permitSponsored: job.permitSponsored,
      trainingProvided: job.trainingProvided,
      vacancies: job.vacancies,
      status: job.status,
      postedDate: job.postedDate,
      closingDate: job.closingDate,
    );
    notifyListeners();
  }

  /// Everything charged to this company, newest first — spec §66.
  List<EmployerCharge> get charges => List.unmodifiable(_charges);

  int get totalSpent =>
      _charges.fold(0, (sum, charge) => sum + charge.amount);

  EmployerJobModel? jobById(String id) {
    for (final j in _jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Timer? _saveTimer;
  bool _hydrated = false;

  bool get isReady => _hydrated;

  /// Reads everything back from the device and loads the candidate pool.
  /// Call once at startup, before the first frame that shows jobs.
  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;

    final stored = await EmployerStore.loadCompany();
    if (stored != null) _company = stored;

    _jobs
      ..clear()
      ..addAll(await EmployerStore.loadJobs());

    _notes.addAll(await EmployerStore.loadNotes());

    _charges
      ..clear()
      ..addAll(await EmployerStore.loadCharges());

    _documents
      ..clear()
      ..addAll(await EmployerStore.loadDocuments());

    _pool
      ..clear()
      ..addAll(await CandidatePoolService.fetch());

    // Re-apply what this company had done with each candidate. Kept apart from
    // the pool so refreshing candidates never wipes a recruiter's pipeline.
    final state = await EmployerStore.loadCandidateState();
    var revealed = 0;
    for (final candidate in _pool) {
      final saved = state[candidate.id];
      if (saved is Map<String, dynamic>) {
        candidate.applyState(saved);
        if (candidate.contactRevealed && !candidate.source.contactAlwaysVisible) {
          revealed++;
        }
      }
    }
    _contactCreditsUsed = revealed;

    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleSave();
  }

  void _scheduleSave() {
    // Nothing is worth writing before the stored copy has been read — saving
    // first would overwrite the company's real data with the empty state the
    // provider starts life holding.
    if (!_hydrated) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _saveNow);
  }

  Future<void> _saveNow() async {
    await EmployerStore.saveCompany(_company);
    await EmployerStore.saveJobs(_jobs);
    await EmployerStore.saveNotes(_notes);
    await EmployerStore.saveCharges(_charges);
    await EmployerStore.saveCandidateState({
      for (final c in _pool)
        if (_isTouched(c)) c.id: c.stateToJson(),
    });
  }

  /// Only candidates the company has actually acted on are written. Storing all
  /// 252 default rows would be a quarter-megabyte of "New" on every save.
  bool _isTouched(Candidate c) =>
      c.status != 'New' ||
      c.isArchived ||
      (c.contactRevealed && !c.source.contactAlwaysVisible);

  Future<void> flush() async {
    _saveTimer?.cancel();
    if (_hydrated) await _saveNow();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SPEC §14–16 — the three candidate tables
  //
  // Not three lists but three views of one pool, differing by where the
  // candidate came from:
  //
  //   1. Organic   — applied to this job directly.
  //   2. Recommended — already in the Lucky Boss database and a good fit; they
  //                    have not applied, and the employer needs a credit to
  //                    contact them.
  //   3. External  — from an authorised partner feed or an import. The source
  //                  name is mandatory; the spec says not to hide where a
  //                  candidate came from.
  // ---------------------------------------------------------------------------

  /// Candidates for a job, best match first.
  ///
  /// The pool is the whole database, so it is matched down rather than filtered
  /// by a stored job id — that is what "Lucky Boss recommended" means, and it
  /// is why a newly posted vacancy has candidates against it immediately
  /// instead of an empty table and a wait.
  List<Candidate> candidatesFor(
    String jobId, {
    CandidateSource? source,
    double minimumMatch = 35,
  }) {
    final job = jobById(jobId);
    if (job == null) return const [];

    final scored = _pool
        .where((c) => !c.isArchived)
        .where((c) => source == null || c.source == source)
        // Somebody in another country who needs sponsoring for a job that does
        // not offer it is not a candidate, and putting them in the table wastes
        // a recruiter's attention.
        .where((c) =>
            c.countryCode == job.countryCode ||
            job.permitSponsored ||
            c.workPermitStatus == 'Citizen')
        .map((c) => (candidate: c, score: c.matchFor(job)))
        .where((e) => e.score >= minimumMatch)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.map((e) => e.candidate).toList();
  }

  /// Archived candidates for a job. Archiving is scoped to this company and job
  /// — the candidate stays in the Lucky Boss database and can be restored.
  List<Candidate> archivedFor(String jobId) {
    final job = jobById(jobId);
    if (job == null) return const [];
    return _pool
        .where((c) => c.isArchived && c.matchFor(job) >= 35)
        .toList();
  }

  int countFor(String jobId, {CandidateSource? source}) =>
      candidatesFor(jobId, source: source).length;

  double matchFor(Candidate candidate, String jobId) {
    final job = jobById(jobId);
    return job == null ? 0 : candidate.matchFor(job);
  }

  /// The whole pool, for the assistant to count from. Read-only.
  List<Candidate> get allCandidates => List.unmodifiable(_pool);

  Candidate? candidateById(String id) {
    for (final c in _pool) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // SPEC §78 — dashboard
  // ---------------------------------------------------------------------------

  int get activeJobsCount => publishedJobs.length;

  int get newApplicantsCount => _countAcrossJobs(
        (c) => c.source == CandidateSource.applied && c.status == 'New',
      );

  int get recommendedCount => _countAcrossJobs(
        (c) => c.source == CandidateSource.recommended,
      );

  int get interviewsCount =>
      _countAcrossJobs((c) => c.status == CandidateStages.interview);

  int get offersPendingCount =>
      _countAcrossJobs((c) => c.status == CandidateStages.offered);

  int get hiredCount => _countAcrossJobs((c) => c.status == CandidateStages.hired);

  /// Counts distinct candidates matching [test] across every published job, so
  /// somebody who fits two vacancies is not counted twice.
  int _countAcrossJobs(bool Function(Candidate) test) {
    final seen = <String>{};
    for (final job in publishedJobs) {
      for (final candidate in candidatesFor(job.id)) {
        if (test(candidate)) seen.add(candidate.id);
      }
    }
    return seen.length;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void toggleDarkMode(bool val) {
    _isDarkMode = val;
    notifyListeners();
  }

  void setAuthenticated(bool val) {
    _isAuthenticated = val;
    notifyListeners();
  }

  void updateCompany(CompanyProfile company) {
    _company = company;
    notifyListeners();
  }

  void setCandidateStatus(String candidateId, String status) {
    candidateById(candidateId)?.status = status;
    notifyListeners();
  }

  /// Spends one contact credit to reveal a candidate's phone and email.
  ///
  /// Returns false when there are none left, so the caller can say why rather
  /// than silently doing nothing. The server must charge the credit too — this
  /// only changes what is shown.
  bool revealContact(String candidateId) {
    final candidate = candidateById(candidateId);
    if (candidate == null) return false;
    if (candidate.contactRevealed) return true;
    // An unverified company may look, but not reach out. Handing a candidate's
    // number to a business nobody has checked is the risk this agency exists to
    // remove.
    if (!canPost && !candidate.source.contactAlwaysVisible) return false;
    if (contactCreditsRemaining <= 0) return false;

    candidate.contactRevealed = true;
    _contactCreditsUsed += 1;
    notifyListeners();
    return true;
  }

  void archiveCandidate(String candidateId, String reason, {String by = 'You'}) {
    final candidate = candidateById(candidateId);
    if (candidate == null) return;
    candidate
      ..archiveReason = reason
      ..archivedAt = DateTime.now()
      ..archivedBy = by;
    notifyListeners();
  }

  void restoreCandidate(String candidateId) {
    final candidate = candidateById(candidateId);
    if (candidate == null) return;
    candidate
      ..archiveReason = null
      ..archivedAt = null
      ..archivedBy = null;
    notifyListeners();
  }

  // --------------------------------------------------------- notes, spec §75

  List<String> notesFor(String candidateId) => _notes[candidateId] ?? const [];

  void addNote(String candidateId, String note) {
    final trimmed = note.trim();
    if (trimmed.isEmpty) return;
    _notes.putIfAbsent(candidateId, () => []).add(trimmed);
    notifyListeners();
  }

  // -------------------------------------------------------------------- jobs

  void postJob(EmployerJobModel job) {
    _jobs.insert(0, job);
    notifyListeners();
  }

  void updateJob(EmployerJobModel job) {
    final index = _jobs.indexWhere((j) => j.id == job.id);
    if (index == -1) return;
    _jobs[index] = job;
    notifyListeners();
  }

  void setJobStatus(String jobId, JobStatus status) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(status: status);
    notifyListeners();
  }

  void deleteJob(String jobId) {
    _jobs.removeWhere((j) => j.id == jobId);
    notifyListeners();
  }

  // --------------------------------------------------------------- documents

  List<UploadedDocument> get documents => List.unmodifiable(_documents);

  Future<void> addDocument(UploadedDocument document) async {
    _documents.removeWhere((d) => d.id == document.id);
    _documents.add(document);
    await EmployerStore.saveDocuments(_documents);
    notifyListeners();
  }

  Future<void> signOut() async {
    _saveTimer?.cancel();
    await EmployerStore.clearAll();
    _isAuthenticated = false;
    _company = const CompanyProfile();
    _jobs.clear();
    _notes.clear();
    _charges.clear();
    _documents.clear();
    for (final candidate in _pool) {
      candidate
        ..status = 'New'
        ..contactRevealed = candidate.source.contactAlwaysVisible
        ..archiveReason = null
        ..archivedAt = null
        ..archivedBy = null;
    }
    _contactCreditsUsed = 0;
    notifyListeners();
  }
}
