import '../core/theme/app_theme.dart';
import 'employer_job.dart';

/// A candidate as the employer sees them.
///
/// Rewritten around what an agency placing field workers actually screens on.
/// The model this replaces had a name, a headline, an experience string and a
/// list of skills — a CV in miniature. It could not say what trade somebody
/// works in, which licences they hold, what languages they speak or whether
/// they may legally work in the country, which between them decide most of the
/// placements Lucky Boss makes.
///
/// Field names mirror the seeker app's profile, because they are the same
/// person seen from the other side.
class Candidate {
  final String id;

  /// The Laravel `job_applications.id` for a real applicant, null for the
  /// bundled samples. Drafting a letter or moving a stage needs it: acting on
  /// a candidate by a display id like "cand-12" is how the wrong person gets
  /// an offer.
  final int? applicationId;
  final String name;

  /// The trade, from the shared taxonomy. What a recruiter reads after the name.
  final String role;
  final String category;
  final int yearsExperience;

  final String city;
  final String countryCode;
  final String phone;
  final String email;

  final List<String> skills;

  /// Licences the candidate claims. Whether the card itself has been uploaded
  /// and checked is a separate question — see [verifiedCertificates].
  final List<String> certificates;

  /// The subset of [certificates] the agency has actually seen a document for.
  /// Shown differently on purpose: an employer sending someone to a site on the
  /// strength of an unverified claim is the failure mode worth designing out.
  final List<String> verifiedCertificates;

  final List<String> languages;
  final String workPermitStatus;
  final String availability;
  final String expectedSalary;

  /// Which of the three tables in spec §14–16 this candidate belongs to.
  final CandidateSource source;

  /// Mandatory for [CandidateSource.external]. The spec is explicit: do not
  /// hide where a candidate came from.
  final String? sourceName;

  final DateTime appliedDate;

  /// True for the sample records bundled with the app.
  final bool isSeed;

  // --- Mutable, and owned by this company rather than the candidate ---

  /// Where they are in this company's pipeline.
  String status;

  /// Contact details start hidden for recommended and external candidates and
  /// are revealed by spending a credit. Anyone who applied directly is visible
  /// from the start — charging for a contact the candidate volunteered is
  /// indefensible.
  bool contactRevealed;

  String? archiveReason;
  DateTime? archivedAt;
  String? archivedBy;

  Candidate({
    required this.id,
    this.applicationId,
    required this.name,
    required this.role,
    required this.category,
    required this.yearsExperience,
    required this.city,
    required this.countryCode,
    required this.phone,
    required this.email,
    required this.appliedDate,
    this.skills = const [],
    this.certificates = const [],
    this.verifiedCertificates = const [],
    this.languages = const [],
    this.workPermitStatus = '',
    this.availability = '',
    this.expectedSalary = '',
    this.source = CandidateSource.applied,
    this.sourceName,
    this.isSeed = false,
    this.status = 'New',
    bool? contactRevealed,
    this.archiveReason,
    this.archivedAt,
    this.archivedBy,
  }) : contactRevealed = contactRevealed ?? source.contactAlwaysVisible;

  bool get isArchived => archiveReason != null;

  String get location => '$city, $countryCode';

  String get experienceLabel => switch (yearsExperience) {
        0 => 'No experience',
        1 => 'Under 1 year',
        _ => '$yearsExperience yrs',
      };

  bool holdsCertificate(String certificate) => certificates
      .any((c) => c.trim().toLowerCase() == certificate.trim().toLowerCase());

  bool isVerified(String certificate) => verifiedCertificates
      .any((c) => c.trim().toLowerCase() == certificate.trim().toLowerCase());

  /// Masked until a credit is spent. Enough of the number is shown that a
  /// recruiter can spot a duplicate without paying for it twice.
  String get maskedPhone {
    final digits = phone.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 5) return '•••••';
    return '${digits.substring(0, 3)}•••••${digits.substring(digits.length - 2)}';
  }

  String get maskedEmail {
    if (!email.contains('@')) return '•••••@•••••';
    final parts = email.split('@');
    final shown = parts.first.isEmpty ? '' : parts.first[0];
    return '$shown•••••@${parts.last}';
  }

  /// How well this candidate fits [job], 0–100.
  ///
  /// Deliberately the same shape as the scorer in the seeker app — trade,
  /// category, skills, licences — so a percentage means the same thing on both
  /// sides of the placement. An employer and a candidate seeing different
  /// numbers for the same pairing is how an ATS loses a recruiter's trust.
  ///
  /// Spec §27 requires a rule-based fallback when AI scoring is unavailable.
  /// This is it: no model, no network, and it always returns something.
  double matchFor(EmployerJobModel job) {
    final jobRoles = job.role
        .split(',')
        .map((r) => r.trim().toLowerCase())
        .where((r) => r.isNotEmpty)
        .toList();
    final candRole = role.trim().toLowerCase();
    final exactRole = jobRoles.contains(candRole) ||
        jobRoles.any((jr) => jr == candRole || jr.contains(candRole) || candRole.contains(jr));
    final sameCategory = category.trim().toLowerCase() == job.category.trim().toLowerCase();

    var score = 0.0;
    if (exactRole) {
      score += 45;
    } else if (sameCategory) {
      score += 35; // Related role affinity in same category
    }

    score += sameCategory ? 25 : 0;

    if (job.requiredSkills.isNotEmpty) {
      final mine = skills.map((s) => s.trim().toLowerCase()).toSet();
      final matched = job.requiredSkills
          .where((s) => mine.contains(s.trim().toLowerCase()))
          .length;
      score += (matched / job.requiredSkills.length) * 20;
    } else {
      score += 20;
    }

    final missing = job.requiredCertificates
        .where((c) => !holdsCertificate(c))
        .toList();
    if (job.requiredCertificates.isEmpty) {
      score += 10;
    } else {
      final held = job.requiredCertificates.length - missing.length;
      score += (held / job.requiredCertificates.length) * 10;
    }

    if (yearsExperience >= 2) {
      score += 5;
    }

    if (missing.length == job.requiredCertificates.length &&
        job.requiredCertificates.isNotEmpty) {
      score = score.clamp(0, 55);
    }

    return score.clamp(0, 98).toDouble();
  }

  /// Spec §26 — why this candidate scored what they scored, in plain terms.
  /// A number with no explanation is not something a recruiter can act on.
  List<String> matchReasons(EmployerJobModel job) {
    final reasons = <String>[];
    final jobRoles = job.role
        .split(',')
        .map((r) => r.trim().toLowerCase())
        .where((r) => r.isNotEmpty)
        .toList();
    final candRole = role.trim().toLowerCase();
    final exactRole = jobRoles.contains(candRole) ||
        jobRoles.any((jr) => jr == candRole || jr.contains(candRole) || candRole.contains(jr));

    if (exactRole) {
      reasons.add('Works as a $role');
    } else if (category.trim().toLowerCase() == job.category.trim().toLowerCase()) {
      reasons.add('Works in $category');
    }
    if (yearsExperience > 0) {
      reasons.add('$experienceLabel of experience');
    }

    final mine = skills.map((s) => s.trim().toLowerCase()).toSet();
    final matchedSkills = job.requiredSkills
        .where((s) => mine.contains(s.trim().toLowerCase()))
        .toList();
    if (matchedSkills.isNotEmpty) {
      reasons.add('Can do ${matchedSkills.take(3).join(', ')}');
    }

    final held =
        job.requiredCertificates.where(holdsCertificate).toList();
    if (held.isNotEmpty) reasons.add('Holds ${held.join(', ')}');

    final missing =
        job.requiredCertificates.where((c) => !holdsCertificate(c)).toList();
    if (missing.isNotEmpty) {
      reasons.add('Missing ${missing.join(', ')}');
    }

    if (countryCode != job.countryCode) {
      reasons.add('Currently in $city, not ${job.countryCode}');
    }
    if (workPermitStatus.isNotEmpty) reasons.add(workPermitStatus);
    if (availability.isNotEmpty) reasons.add('Can start $availability');

    return reasons;
  }

  factory Candidate.fromJson(Map<String, dynamic> j) {
    List<String> strings(String key) =>
        ((j[key] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList();
    String text(String key) => (j[key] as String?) ?? '';

    final hours = (j['applied_hours_ago'] as num?)?.toInt();

    return Candidate(
      id: j['id'] as String,
      name: text('name'),
      role: text('role'),
      category: text('category'),
      yearsExperience: (j['years_experience'] as num?)?.toInt() ?? 0,
      city: text('city'),
      countryCode: text('country_code'),
      phone: text('phone'),
      email: text('email'),
      skills: strings('skills'),
      certificates: strings('certificates'),
      verifiedCertificates: strings('verified_certificates'),
      languages: strings('languages'),
      workPermitStatus: text('work_permit_status'),
      availability: text('availability'),
      expectedSalary: text('expected_salary'),
      source: switch (j['source']) {
        'recommended' => CandidateSource.recommended,
        'external' => CandidateSource.external,
        _ => CandidateSource.applied,
      },
      sourceName: j['source_name'] as String?,
      status: (j['status'] as String?) ?? 'New',
      isSeed: (j['seed'] as bool?) ?? false,
      appliedDate: DateTime.tryParse(text('applied_at')) ??
          DateTime.now().subtract(Duration(hours: hours ?? 0)),
    );
  }

  /// What this company has done with the candidate, kept apart from the
  /// candidate record itself so refreshing the pool never wipes a pipeline.
  Map<String, dynamic> stateToJson() => {
        'status': status,
        'contact_revealed': contactRevealed,
        'archive_reason': archiveReason,
        'archived_at': archivedAt?.toIso8601String(),
        'archived_by': archivedBy,
      };

  void applyState(Map<String, dynamic> state) {
    status = (state['status'] as String?) ?? status;
    contactRevealed = (state['contact_revealed'] as bool?) ?? contactRevealed;
    archiveReason = state['archive_reason'] as String?;
    archivedAt = DateTime.tryParse((state['archived_at'] as String?) ?? '');
    archivedBy = state['archived_by'] as String?;
  }
}

/// The pipeline stages, spec §77.
class CandidateStages {
  CandidateStages._();

  static const String newApplicant = 'New';
  static const String shortlisted = 'Shortlisted';
  static const String contacted = 'Contacted';
  static const String interview = 'Interview';
  static const String offered = 'Offered';
  static const String hired = 'Hired';

  static const List<String> all = [
    newApplicant,
    shortlisted,
    contacted,
    interview,
    offered,
    hired,
  ];
}
