import '../core/constants/app_data.dart';
import 'job_boost.dart';

/// Where a vacancy is in its life.
enum JobStatus {
  draft,
  published,
  paused,
  closed;

  String get label => switch (this) {
        JobStatus.draft => 'Draft',
        JobStatus.published => 'Published',
        JobStatus.paused => 'Paused',
        JobStatus.closed => 'Closed',
      };
}

/// A vacancy as the employer owns it.
///
/// Deliberately the mirror image of the job seeker app's `JobModel`: same
/// columns, same names, same `pay_period` / `accommodation_provided` /
/// `permit_sponsored` fields. That is not tidiness — it is the only way the
/// two sides can match. A vacancy posted here has to be scoreable against a
/// candidate profile built there, and the moment the two describe work
/// differently the match percentage becomes fiction.
///
/// The old model had five fields: title, category, location, a salary string
/// and a count. It could not express a day rate, a licence requirement, whether
/// accommodation came with the job, or which specific trade was wanted — which
/// is most of what an employer placing site workers needs to say.
class EmployerJobModel {
  final String id;

  /// The trade being hired, chosen from [AppData]. Free text would break
  /// matching: "fork lift driver" and "Forklift Driver" are the same job to a
  /// person and different strings to a scorer.
  final String role;

  /// Shown on the listing. Defaults to [role]; an employer may add detail
  /// ("Mason — high-rise experience") without breaking the match.
  final String title;

  final String category;

  // --- Employer identity, carried with the posting ---
  //
  // Denormalised onto the job on purpose. A candidate reading a vacancy needs
  // to know who is hiring and whether we have checked them, and that has to
  // survive the row being handed to the seeker app, cached, and rendered
  // offline. A join back to a companies table the handset does not have is not
  // an option.

  /// Stable id of the posting company. The join key once there is a server.
  final String companyId;

  final String companyName;

  /// Logo as a data URI, or null. Optional by design — Shantosh was doubtful it
  /// was needed, and a job card has to look right without one.
  final String? companyLogoUrl;

  /// Whether Lucky Boss had verified this company at the time of posting.
  /// Never set by the handset; see CompanyStatus.
  final bool companyVerified;

  /// Construction, Maid Agency, and so on. Tells a candidate what kind of
  /// business is hiring, which for domestic and site work matters as much as
  /// the company name.
  final String companyType;

  final String location;
  final String countryCode;

  final String minSalary;
  final String maxSalary;
  final String currency;

  /// Per day, per month or per year. A site worker is quoted a day rate and a
  /// salaried employee a monthly figure; a number without its unit is not a
  /// number anyone can act on.
  final String payPeriod;

  final String workMode;
  final String shift;
  final String description;

  /// What the work involves — matched against the candidate's abilities.
  final List<String> requiredSkills;

  /// Licences the job genuinely requires. A hard gate rather than a
  /// preference: no ticket, no shortlist, and the seeker app caps the match
  /// accordingly.
  final List<String> requiredCertificates;

  final bool accommodationProvided;
  final bool transportProvided;
  final bool permitSponsored;

  /// Set when the employer will consider candidates with no experience. For
  /// entry-level field work this is the single most important line in the
  /// posting.
  final bool trainingProvided;

  final int vacancies;

  /// The promotion bought for this vacancy, spec §61. Null when unboosted,
  /// which is most jobs.
  final JobBoost? boost;

  final JobStatus status;
  final DateTime postedDate;
  final DateTime? closingDate;

  const EmployerJobModel({
    required this.id,
    required this.role,
    required this.title,
    required this.category,
    required this.companyName,
    this.companyId = '',
    this.companyLogoUrl,
    this.companyVerified = false,
    this.companyType = '',
    required this.location,
    required this.countryCode,
    required this.minSalary,
    required this.maxSalary,
    required this.currency,
    required this.postedDate,
    this.payPeriod = 'Per month',
    this.workMode = 'On-site',
    this.shift = '',
    this.description = '',
    this.requiredSkills = const [],
    this.requiredCertificates = const [],
    this.accommodationProvided = false,
    this.transportProvided = false,
    this.permitSponsored = false,
    this.trainingProvided = false,
    this.vacancies = 1,
    this.boost,
    this.status = JobStatus.published,
    this.closingDate,
  });

  /// Whether this job is currently promoted. Checked through the boost's own
  /// dates, so one expires without anything having to sweep it up.
  bool get isBoosted => boost?.isActive ?? false;

  /// Ranking weight in the candidate's feed. Zero for an unboosted or expired
  /// job, which is the overwhelming majority.
  int get boostPriority => boost?.priority ?? 0;

  bool get isFieldWork => AppData.isFieldCategory(category);

  /// The pay line as a candidate reads it.
  String get salaryDisplay {
    if (minSalary.isEmpty && maxSalary.isEmpty) return 'Salary not disclosed';
    final unit = switch (payPeriod) {
      'Per day' => '/ day',
      'Per year' => '/ year',
      _ => '/ month',
    };
    if (maxSalary.isEmpty) return '$currency $minSalary $unit';
    return '$currency $minSalary – $maxSalary $unit';
  }

  /// The perks a field candidate scans for before anything else.
  List<String> get benefits => [
        if (accommodationProvided) 'Accommodation',
        if (transportProvided) 'Transport',
        if (permitSponsored) 'Permit sponsored',
        if (trainingProvided) 'Training given',
      ];

  EmployerJobModel copyWith({
    String? title,
    JobStatus? status,
    int? vacancies,
    DateTime? closingDate,
    String? companyName,
    bool? companyVerified,
    JobBoost? boost,
  }) =>
      EmployerJobModel(
        id: id,
        role: role,
        title: title ?? this.title,
        category: category,
        companyId: companyId,
        companyName: companyName ?? this.companyName,
        companyLogoUrl: companyLogoUrl,
        companyVerified: companyVerified ?? this.companyVerified,
        companyType: companyType,
        location: location,
        countryCode: countryCode,
        minSalary: minSalary,
        maxSalary: maxSalary,
        currency: currency,
        payPeriod: payPeriod,
        workMode: workMode,
        shift: shift,
        description: description,
        requiredSkills: requiredSkills,
        requiredCertificates: requiredCertificates,
        accommodationProvided: accommodationProvided,
        transportProvided: transportProvided,
        permitSponsored: permitSponsored,
        trainingProvided: trainingProvided,
        vacancies: vacancies ?? this.vacancies,
        boost: boost ?? this.boost,
        status: status ?? this.status,
        postedDate: postedDate,
        closingDate: closingDate ?? this.closingDate,
      );

  /// Column names are the MySQL `jobs` column names, matching the seeker app's
  /// catalogue exactly. A vacancy posted on a handset can be pushed to the API
  /// with no translation layer, and read back by the seeker app unchanged.
  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'title': title,
        'category': category,
        'company_id': companyId,
        'company_name': companyName,
        'company_logo_url': companyLogoUrl,
        'company_verified': companyVerified,
        'company_type': companyType,
        'location': location,
        'country_code': countryCode,
        'min_salary': minSalary,
        'max_salary': maxSalary,
        'currency': currency,
        'pay_period': payPeriod,
        'work_mode': workMode,
        'shift': shift,
        'description': description,
        'required_skills': requiredSkills,
        'required_certificates': requiredCertificates,
        'accommodation_provided': accommodationProvided,
        'transport_provided': transportProvided,
        'permit_sponsored': permitSponsored,
        'training_provided': trainingProvided,
        'vacancies': vacancies,
        // Travels with the posting so the seeker app can rank and badge it
        // without a second call.
        'boost': boost?.toJson(),
        'status': status.name,
        'posted_at': postedDate.toIso8601String(),
        'closing_at': closingDate?.toIso8601String(),
      };

  factory EmployerJobModel.fromJson(Map<String, dynamic> j) {
    List<String> strings(String key) =>
        ((j[key] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList();
    String text(String key) => (j[key] as String?) ?? '';

    return EmployerJobModel(
      id: j['id'] as String,
      role: text('role'),
      title: text('title'),
      category: text('category'),
      companyId: text('company_id'),
      companyName: text('company_name'),
      companyLogoUrl: j['company_logo_url'] as String?,
      companyVerified: (j['company_verified'] as bool?) ?? false,
      companyType: text('company_type'),
      location: text('location'),
      countryCode: text('country_code'),
      minSalary: text('min_salary'),
      maxSalary: text('max_salary'),
      currency: text('currency'),
      payPeriod: (j['pay_period'] as String?) ?? 'Per month',
      workMode: (j['work_mode'] as String?) ?? 'On-site',
      shift: text('shift'),
      description: text('description'),
      requiredSkills: strings('required_skills'),
      requiredCertificates: strings('required_certificates'),
      accommodationProvided: (j['accommodation_provided'] as bool?) ?? false,
      transportProvided: (j['transport_provided'] as bool?) ?? false,
      permitSponsored: (j['permit_sponsored'] as bool?) ?? false,
      trainingProvided: (j['training_provided'] as bool?) ?? false,
      vacancies: (j['vacancies'] as num?)?.toInt() ?? 1,
      boost: j['boost'] == null
          ? null
          : JobBoost.fromJson(j['boost'] as Map<String, dynamic>),
      status: JobStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => JobStatus.published,
      ),
      postedDate:
          DateTime.tryParse((j['posted_at'] as String?) ?? '') ?? DateTime.now(),
      closingDate: DateTime.tryParse((j['closing_at'] as String?) ?? ''),
    );
  }
}

/// Where a company stands with Lucky Boss.
///
/// The same rule as a candidate's licence documents, for the same reason: the
/// handset can never mark itself verified. An employer asserting its own
/// legitimacy is worth nothing to the job seeker who is deciding whether to get
/// on a bus to a site address.
///
/// Shantosh: *"it is not straight register, we take all info to process to
/// verify them with AI letting them know we contact them after verification."*
/// So registration ends at [submitted], not at a working account.
enum CompanyStatus {
  /// Registration started, not sent.
  draft,

  /// Documents sent. The state a company sits in after registering.
  submitted,

  /// A person at Lucky Boss is looking at it.
  underReview,

  /// Checked and accepted. Set by the server, never by the app.
  verified,

  /// Refused — wrong document, expired, or details that did not match.
  rejected;

  String get label => switch (this) {
        CompanyStatus.draft => 'Not submitted',
        CompanyStatus.submitted => 'Awaiting verification',
        CompanyStatus.underReview => 'Being reviewed',
        CompanyStatus.verified => 'Verified',
        CompanyStatus.rejected => 'Not accepted',
      };

  /// What the company may do right now.
  ///
  /// Only a verified company may publish a vacancy or spend a contact credit.
  /// A candidate applying to a site should be able to assume we checked who is
  /// hiring, and that assumption is the product.
  bool get canPost => this == CompanyStatus.verified;
}

/// The hiring company.
///
/// Spec §34 (company type), §35 (grade) and §40 (identity lock) all hang off
/// this. Kept small for now: what a posting needs to carry a company name and
/// what the profile screen needs to show.
class CompanyProfile {
  /// Stable id, generated when the company first registers. Becomes the join
  /// key to the MySQL `companies` table.
  final String id;

  final String name;

  /// Registered legal name, where it differs from the trading name.
  final String legalName;

  final String type;

  /// Business registration / UEN / CIN number, checked against the uploaded
  /// certificate during verification.
  final String registrationNumber;

  final CompanyStatus status;

  /// Set by the server when a registration is refused, so the company is told
  /// what to fix rather than left looking at a red label.
  final String? reviewNote;

  final DateTime? submittedAt;
  final String contactName;
  final String email;
  final String phone;
  final String countryCode;
  final String city;
  final String about;

  /// Data URI of the company logo, stored on the device like every other
  /// upload in these apps.
  final String? logoUrl;

  const CompanyProfile({
    this.id = '',
    this.name = '',
    this.legalName = '',
    this.type = '',
    this.registrationNumber = '',
    this.status = CompanyStatus.draft,
    this.reviewNote,
    this.submittedAt,
    this.contactName = '',
    this.email = '',
    this.phone = '',
    this.countryCode = 'SG',
    this.city = '',
    this.about = '',
    this.logoUrl,
  });

  bool get isVerified => status == CompanyStatus.verified;
  bool get canPost => status.canPost;

  /// Whether registration has been filled in far enough to submit.
  bool get isSubmittable =>
      name.trim().isNotEmpty &&
      type.trim().isNotEmpty &&
      registrationNumber.trim().isNotEmpty &&
      contactName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      email.trim().isNotEmpty;

  CompanyProfile copyWith({
    String? id,
    String? name,
    String? legalName,
    String? type,
    String? registrationNumber,
    CompanyStatus? status,
    String? reviewNote,
    DateTime? submittedAt,
    String? contactName,
    String? email,
    String? phone,
    String? countryCode,
    String? city,
    String? about,
    String? logoUrl,
  }) =>
      CompanyProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        legalName: legalName ?? this.legalName,
        type: type ?? this.type,
        registrationNumber: registrationNumber ?? this.registrationNumber,
        status: status ?? this.status,
        reviewNote: reviewNote ?? this.reviewNote,
        submittedAt: submittedAt ?? this.submittedAt,
        contactName: contactName ?? this.contactName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        countryCode: countryCode ?? this.countryCode,
        city: city ?? this.city,
        about: about ?? this.about,
        logoUrl: logoUrl ?? this.logoUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'legal_name': legalName,
        'type': type,
        'registration_number': registrationNumber,
        'status': status.name,
        'review_note': reviewNote,
        'submitted_at': submittedAt?.toIso8601String(),
        'contact_name': contactName,
        'email': email,
        'phone': phone,
        'country_code': countryCode,
        'city': city,
        'about': about,
        'logo_url': logoUrl,
      };

  factory CompanyProfile.fromJson(Map<String, dynamic> j) => CompanyProfile(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        legalName: (j['legal_name'] ?? '') as String,
        type: (j['type'] ?? '') as String,
        registrationNumber: (j['registration_number'] ?? '') as String,
        status: CompanyStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => CompanyStatus.draft,
        ),
        reviewNote: j['review_note'] as String?,
        submittedAt: DateTime.tryParse((j['submitted_at'] as String?) ?? ''),
        contactName: (j['contact_name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        countryCode: (j['country_code'] ?? 'SG') as String,
        city: (j['city'] ?? '') as String,
        about: (j['about'] ?? '') as String,
        logoUrl: j['logo_url'] as String?,
      );

  /// Spec §34. The agency's own company-type master, blue-collar first — these
  /// are the businesses Lucky Boss actually signs.
  static const List<String> types = [
    'Construction',
    'Manufacturing',
    'Logistics',
    'Warehouse',
    'Maid Agency',
    'Domestic Worker Agency',
    'Cleaning & Facilities',
    'Security Services',
    'Hospitality',
    'Healthcare',
    'Retail',
    'Recruitment Agency',
    'IT',
    'SME',
    'Enterprise',
  ];
}
