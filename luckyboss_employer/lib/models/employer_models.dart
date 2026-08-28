import '../core/theme/app_theme.dart';

export 'employer_job.dart';

/// A candidate as the employer sees them, from any of the three sources the
/// functional specification requires.
///
/// The fields added beyond the original demo model are the ones the Candidates
/// screen cannot work without: where the candidate came from, whether their
/// contact details have been paid for, and what has happened to them since.
class ApplicantModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String candidateName;
  final String candidatePhone;
  final String experience;
  final String location;

  /// Null means the platform could not score this candidate and fell back to
  /// rule-based matching. The UI must say so rather than inventing a number.
  final double? aiMatchScore;

  String status;

  /// The candidate's current or most recent role. What a recruiter reads first
  /// after the name.
  final String headline;

  final String? candidateEmail;
  final List<String> skills;

  /// Which of the three tables this candidate belongs to.
  final CandidateSource source;

  /// For external candidates only — the actual provider. "External" on its own
  /// tells a recruiter nothing about whether the record can be trusted.
  final String? sourceName;

  /// Contact details start hidden for recommended and external candidates and
  /// are revealed by spending a contact credit. Anyone who applied directly is
  /// revealed from the start — they chose to make contact.
  bool contactRevealed;

  final DateTime? lastActivity;

  /// Set when the candidate has been archived for this company + job. Archiving
  /// is scoped to the job, never global — the candidate stays in the database.
  String? archiveReason;
  DateTime? archivedAt;
  String? archivedBy;

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
    this.headline = '',
    this.candidateEmail,
    this.skills = const [],
    this.source = CandidateSource.applied,
    this.sourceName,
    bool? contactRevealed,
    this.lastActivity,
    this.archiveReason,
    this.archivedAt,
    this.archivedBy,
  }) : contactRevealed = contactRevealed ?? source.contactAlwaysVisible;

  bool get isArchived => archiveReason != null;

  /// Masked for display before a credit is spent. Shows enough of the number
  /// that a recruiter can spot a duplicate without paying for it.
  String get maskedPhone {
    final digits = candidatePhone.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 5) return '•••••';
    return '${digits.substring(0, 3)}•••••${digits.substring(digits.length - 2)}';
  }

  String get maskedEmail {
    final email = candidateEmail;
    if (email == null || !email.contains('@')) return '•••••@•••••';
    final parts = email.split('@');
    final name = parts.first;
    final shown = name.isEmpty ? '' : name[0];
    return '$shown•••••@${parts.last}';
  }
}

/// The archive reasons the specification defines. Archiving always takes a
/// reason so the pipeline stays auditable.
class ArchiveReasons {
  ArchiveReasons._();

  static const List<String> all = [
    'Not suitable',
    'Experience mismatch',
    'Salary expectation',
    'Location',
    'Not responding',
    'Position filled',
    'Duplicate record',
    'Future consideration',
    'Other',
  ];
}

