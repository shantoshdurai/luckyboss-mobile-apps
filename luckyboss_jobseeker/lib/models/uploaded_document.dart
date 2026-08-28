/// Where a document stands with the agency.
///
/// A candidate who has uploaded their forklift card has not been verified, and
/// the app must never imply otherwise — an unverified claim shown as a green
/// tick is how an employer ends up at a site with someone who cannot legally
/// operate the machine. Until a human or the AI check runs, the honest state is
/// "sent, waiting".
enum DocumentStatus {
  /// Uploaded and waiting on the agency. The only state this app can set.
  pending,

  /// Checked and accepted. Set by the server, never by the handset.
  verified,

  /// Checked and refused — wrong document, expired, unreadable.
  rejected;

  String get label => switch (this) {
        DocumentStatus.pending => 'Awaiting verification',
        DocumentStatus.verified => 'Verified',
        DocumentStatus.rejected => 'Not accepted',
      };
}

/// What a document is attached to.
enum DocumentKind {
  /// A licence, card or certificate — the forklift ticket, the safety card.
  certificate,

  /// A CV or resume.
  resume,

  /// Passport, work permit, NRIC — proof of the right to work.
  identity,

  /// Anything else the candidate wanted on file.
  other;

  String get label => switch (this) {
        DocumentKind.certificate => 'Licence or certificate',
        DocumentKind.resume => 'Resume',
        DocumentKind.identity => 'Identity or permit',
        DocumentKind.other => 'Document',
      };
}

/// A file the candidate has uploaded.
///
/// The bytes are **not** held here. This is the index entry: metadata small
/// enough to load with the profile on every launch, pointing at a payload that
/// [LocalStore] keeps under its own key. A candidate with four licence photos on
/// file should not pay for decoding eight megabytes of base64 every time the
/// profile screen rebuilds.
class UploadedDocument {
  final String id;
  final DocumentKind kind;

  /// What this document proves — 'Forklift Licence', 'Class 4 Licence'. Matches
  /// the certificate name on the profile when there is one, which is how the
  /// licences card knows which claim has proof behind it.
  final String label;

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final DateTime uploadedAt;
  final DocumentStatus status;

  /// Set by the server when a document is refused, so the candidate is told
  /// what to do rather than left looking at a red label.
  final String? reviewNote;

  const UploadedDocument({
    required this.id,
    required this.kind,
    required this.label,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.status = DocumentStatus.pending,
    this.reviewNote,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get sizeDisplay {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).round()} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  UploadedDocument copyWith({DocumentStatus? status, String? reviewNote}) =>
      UploadedDocument(
        id: id,
        kind: kind,
        label: label,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        uploadedAt: uploadedAt,
        status: status ?? this.status,
        reviewNote: reviewNote ?? this.reviewNote,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'label': label,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'uploaded_at': uploadedAt.toIso8601String(),
        'status': status.name,
        'review_note': reviewNote,
      };

  factory UploadedDocument.fromJson(Map<String, dynamic> j) => UploadedDocument(
        id: j['id'] as String,
        kind: DocumentKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => DocumentKind.other,
        ),
        label: (j['label'] ?? '') as String,
        fileName: (j['file_name'] ?? '') as String,
        mimeType: (j['mime_type'] ?? 'application/octet-stream') as String,
        sizeBytes: (j['size_bytes'] as num?)?.toInt() ?? 0,
        uploadedAt:
            DateTime.tryParse((j['uploaded_at'] as String?) ?? '') ?? DateTime.now(),
        status: DocumentStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => DocumentStatus.pending,
        ),
        reviewNote: j['review_note'] as String?,
      );
}
