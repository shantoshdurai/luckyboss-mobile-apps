import '../core/constants/app_data.dart';

enum ExperienceLevel {
  entry,
  mid,
  senior,
  lead;

  String get label => displayLabel;

  String get displayLabel {
    switch (this) {
      case ExperienceLevel.entry:
        return 'Entry Level (0–2 yrs)';
      case ExperienceLevel.mid:
        return 'Mid Level (3–5 yrs)';
      case ExperienceLevel.senior:
        return 'Senior (6–9 yrs)';
      case ExperienceLevel.lead:
        return 'Lead / Principal (10+ yrs)';
    }
  }

  String get shortLabel {
    switch (this) {
      case ExperienceLevel.entry:
        return '0–2 yrs';
      case ExperienceLevel.mid:
        return '3–5 yrs';
      case ExperienceLevel.senior:
        return '6–9 yrs';
      case ExperienceLevel.lead:
        return '10+ yrs';
    }
  }
}

class SeekerProfileModel {
  String name;
  String phone;
  String email;
  String countryCode;
  ExperienceLevel experienceLevel;
  /// Markets of work the candidate will take, best first.
  ///
  /// A list because a general worker will take construction *or* warehouse and
  /// picking one throws away half the vacancies we could show them. Capped at
  /// [maxCategories] — beyond three, "I will take anything" is what is really
  /// being said, and it stops discriminating between jobs at all.
  List<String> preferredCategories;

  /// How many categories a candidate may claim.
  static const int maxCategories = 3;
  String bio;
  List<String> skills;
  String? resumeFileName;

  /// Absolute URL of the uploaded profile photo, or null when the candidate
  /// has not set one and initials are shown instead.
  String? photoUrl;

  // Collected by the onboarding wizard. Which of these are meaningful depends
  // on [isStudent] — a fresher has a qualification and passing year, someone
  // working has a title and notice period.
  bool isStudent;
  String currentCity;
  String currentTitle;
  String? qualification;
  String course;
  String passingYear;
  String noticePeriod;

  // Job preferences. These are matching constraints, not decoration — see
  // JobSeekerProvider.matchScoreFor.

  /// Markets the candidate will work in.
  ///
  /// A list, not one value. Shantosh: *"what if they want three countries?"* —
  /// and for this agency that is the normal case rather than the exception:
  /// somebody in Chennai open to Singapore and Malaysia is exactly who Lucky
  /// Boss places. Storing one market meant the other two were thrown away at
  /// the moment they were chosen.
  ///
  /// [preferredCountry] is kept as a read-only view for callers that still
  /// think in one market, and so a stored profile written by an older build
  /// still loads — see [fromJson].
  List<String> preferredCountries;
  List<String> workModes;
  List<String> jobTypes;
  String expectedSalary;
  String availability;
  bool? openToRelocate;
  bool? hasWorkPermit;

  /// One-line pitch shown at the top of the profile — spec section 31's
  /// "Professional Summary" in its short form.
  String headline;

  /// Function or department, e.g. Engineering, Finance. Distinct from
  /// [preferredCategory], which is the job market; this is what they do inside it.
  String department;

  /// Projects and languages. Both are lists because a candidate has several and
  /// employers filter on any one of them.
  List<String> projects;
  List<String> languages;

  // ---------------------------------------------------------------------------
  // FIELD WORK
  //
  // Spec §31 asks for Job Category, Certification, Languages, Preferred Salary
  // and Work Permit Information. The app collected none of them, because the
  // profile it was built around belonged to an office candidate: a headline, a
  // department, projects, key skills. For the construction workers, factory
  // labour, drivers and domestic helpers this agency places, those fields are
  // blank and these are the entire profile.
  // ---------------------------------------------------------------------------

  /// The trade, as the candidate named it — "Plumber", "Forklift Driver".
  /// Distinct from [currentTitle] only in intent: this is the work they want,
  /// which for field candidates is usually the work they already do.
  String roleTitle;

  /// Licences and cards. A forklift ticket or a safety card is frequently the
  /// difference between a shortlist and a rejection, and it is a fact about the
  /// candidate rather than a claim, so it is stored apart from [skills].
  List<String> certificates;

  /// Work authorisation as a stated status. [hasWorkPermit] is kept alongside
  /// it for the matching engine, but a boolean cannot distinguish "needs
  /// sponsorship" from "not sure", and employers treat those very differently.
  String workPermitStatus;

  /// Whether [expectedSalary] is quoted per day, per month or per year. Without
  /// it the number is not interpretable: 800 is a good daily rate and a poor
  /// monthly one.
  String payPeriod;

  bool isVerified;

  SeekerProfileModel({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.countryCode = 'IN',
    this.experienceLevel = ExperienceLevel.mid,
    List<String>? preferredCategories,
    this.bio = '',
    List<String>? skills,
    this.resumeFileName,
    this.photoUrl,
    this.isStudent = false,
    this.currentCity = '',
    this.currentTitle = '',
    this.qualification,
    this.course = '',
    this.passingYear = '',
    this.noticePeriod = '',
    List<String>? preferredCountries,
    List<String>? workModes,
    List<String>? jobTypes,
    this.expectedSalary = '',
    this.availability = '',
    this.headline = '',
    this.department = '',
    List<String>? projects,
    List<String>? languages,
    this.roleTitle = '',
    List<String>? certificates,
    this.workPermitStatus = '',
    this.payPeriod = 'Per month',
    this.openToRelocate,
    this.hasWorkPermit,
    this.isVerified = false,
  })  : preferredCategories = preferredCategories ?? [],
        preferredCountries = preferredCountries ?? [],
        skills = skills ?? [],
        workModes = workModes ?? [],
        jobTypes = jobTypes ?? [],
        projects = projects ?? [],
        languages = languages ?? [],
        certificates = certificates ?? [];

  bool get isProfileFilledOut => name.trim().isNotEmpty && email.trim().isNotEmpty;

  String get experienceYears => experienceLevel.shortLabel;

  /// The first chosen market, or empty. For callers that genuinely need one —
  /// a currency symbol, a default filter.
  String get preferredCountry =>
      preferredCountries.isEmpty ? '' : preferredCountries.first;

  /// First choice. Matching scores against every chosen category and takes the
  /// best, but the profile header and the field/office split need one answer.
  String get preferredCategory => preferredCategories.isEmpty
      ? AppData.categories.first
      : preferredCategories.first;

  /// Replaces the whole list with one category.
  ///
  /// Kept so the many callers that legitimately set a single category — the
  /// profile editor, resume autofill, the server sync — do not each need to
  /// know the field is a list now.
  set preferredCategory(String value) {
    preferredCategories = value.trim().isEmpty ? [] : [value];
  }

  bool wantsCategory(String name) =>
      preferredCategories.isEmpty || preferredCategories.contains(name);

  bool wantsCountry(String code) =>
      preferredCountries.isEmpty || preferredCountries.contains(code);

  /// True when this profile is field work, and should be scored and displayed
  /// in those terms rather than as a CV.
  bool get isFieldWork => AppData.isFieldCategory(preferredCategory);

  /// Dynamic profile strength, 0–100.
  ///
  /// Scored differently on the two paths, because the old single formula was
  /// unreachable for half the candidates using the app. It awarded 20% for a
  /// resume document and 20% for an "Executive Bio" of thirty characters — a
  /// site worker has neither and never will, so 40% of the score was closed to
  /// them before they started. The profile then told them they were incomplete
  /// no matter how much they filled in, which is both untrue and demoralising.
  ///
  /// The field formula scores the things that actually get a field candidate
  /// hired: a trade, years, the work they can do, their licences, the languages
  /// they speak and their availability.
  int get profileStrengthPercent {
    int score = 0;

    // Contact details are worth the same on both paths — nobody is placed
    // without them.
    if (name.trim().isNotEmpty && phone.trim().isNotEmpty) {
      score += 25;
    } else if (name.trim().isNotEmpty || phone.trim().isNotEmpty) {
      score += 15;
    }

    if (isFieldWork) {
      if (roleTitle.trim().isNotEmpty || currentTitle.trim().isNotEmpty) {
        score += 20;
      }
      if (skills.length >= 3) {
        score += 15;
      } else if (skills.isNotEmpty) {
        score += (skills.length * 5).clamp(0, 15);
      }
      if (certificates.isNotEmpty) score += 15;
      if (languages.isNotEmpty) score += 10;
      if (workPermitStatus.trim().isNotEmpty) score += 10;
      if (availability.trim().isNotEmpty) score += 5;
      if ((photoUrl ?? '').isNotEmpty) score += 5;
      return score.clamp(0, 100);
    }

    if (email.trim().isNotEmpty) score += 15;

    if (resumeFileName != null && resumeFileName!.trim().isNotEmpty) {
      score += 20;
    }

    if (skills.length >= 3) {
      score += 20;
    } else if (skills.isNotEmpty) {
      score += (skills.length * 7).clamp(0, 20);
    }

    if (bio.trim().length >= 30) {
      score += 20;
    } else if (bio.trim().isNotEmpty) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  // ---------------------------------------------------------------------------
  // PERSISTENCE
  //
  // Everything a candidate types has to survive the app being closed. On the
  // standalone build there is no server to fetch it back from, so this pair of
  // methods is the only thing standing between them and re-entering their whole
  // profile on the next launch.
  //
  // fromJson is written to tolerate a stored blob from an older version of the
  // app: every field falls back to its default, so adding a field here never
  // makes an existing install look corrupted.
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'countryCode': countryCode,
        'experienceLevel': experienceLevel.name,
        'preferredCategories': preferredCategories,
        'bio': bio,
        'skills': skills,
        'resumeFileName': resumeFileName,
        'photoUrl': photoUrl,
        'isStudent': isStudent,
        'currentCity': currentCity,
        'currentTitle': currentTitle,
        'qualification': qualification,
        'course': course,
        'passingYear': passingYear,
        'noticePeriod': noticePeriod,
        'preferredCountries': preferredCountries,
        'workModes': workModes,
        'jobTypes': jobTypes,
        'expectedSalary': expectedSalary,
        'availability': availability,
        'openToRelocate': openToRelocate,
        'hasWorkPermit': hasWorkPermit,
        'headline': headline,
        'department': department,
        'projects': projects,
        'languages': languages,
        'roleTitle': roleTitle,
        'certificates': certificates,
        'workPermitStatus': workPermitStatus,
        'payPeriod': payPeriod,
        'isVerified': isVerified,
      };

  factory SeekerProfileModel.fromJson(Map<String, dynamic> j) {
    List<String> strings(String key) =>
        (j[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    String text(String key) => (j[key] as String?) ?? '';

    return SeekerProfileModel(
      name: text('name'),
      phone: text('phone'),
      email: text('email'),
      countryCode: (j['countryCode'] as String?) ?? 'IN',
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == j['experienceLevel'],
        orElse: () => ExperienceLevel.mid,
      ),
      // New key first, then the single-value key an older build wrote, so an
      // existing install keeps the category it chose during onboarding.
      preferredCategories: strings('preferredCategories').isNotEmpty
          ? strings('preferredCategories')
          : [
              if (text('preferredCategory').isNotEmpty)
                text('preferredCategory'),
            ],
      bio: text('bio'),
      skills: strings('skills'),
      resumeFileName: j['resumeFileName'] as String?,
      photoUrl: j['photoUrl'] as String?,
      isStudent: (j['isStudent'] as bool?) ?? false,
      currentCity: text('currentCity'),
      currentTitle: text('currentTitle'),
      qualification: j['qualification'] as String?,
      course: text('course'),
      passingYear: text('passingYear'),
      noticePeriod: text('noticePeriod'),
      // Reads the new key, then falls back to the single-value key an older
      // build wrote. Without this every existing install silently loses the
      // market the candidate chose during onboarding.
      preferredCountries: strings('preferredCountries').isNotEmpty
          ? strings('preferredCountries')
          : [
              if (text('preferredCountry').isNotEmpty) text('preferredCountry'),
            ],
      workModes: strings('workModes'),
      jobTypes: strings('jobTypes'),
      expectedSalary: text('expectedSalary'),
      availability: text('availability'),
      openToRelocate: j['openToRelocate'] as bool?,
      hasWorkPermit: j['hasWorkPermit'] as bool?,
      headline: text('headline'),
      department: text('department'),
      projects: strings('projects'),
      languages: strings('languages'),
      roleTitle: text('roleTitle'),
      certificates: strings('certificates'),
      workPermitStatus: text('workPermitStatus'),
      payPeriod: (j['payPeriod'] as String?) ?? 'Per month',
      isVerified: (j['isVerified'] as bool?) ?? false,
    );
  }

  /// Build a profile from AI-extracted resume data
  factory SeekerProfileModel.fromExtractedJson(Map<String, dynamic> json, {String phone = ''}) {
    ExperienceLevel level = ExperienceLevel.mid;
    final years = json['experienceYears'] as int? ?? 3;
    if (years <= 2) {
      level = ExperienceLevel.entry;
    } else if (years <= 5) {
      level = ExperienceLevel.mid;
    } else if (years <= 9) {
      level = ExperienceLevel.senior;
    } else {
      level = ExperienceLevel.lead;
    }

    return SeekerProfileModel(
      name: json['name'] as String? ?? '',
      phone: phone,
      email: json['email'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'IN',
      experienceLevel: level,
      preferredCategories: [
        if ((json['preferredCategory'] as String?)?.isNotEmpty ?? false)
          json['preferredCategory'] as String,
      ],
      bio: json['bio'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      resumeFileName: json['resumeFileName'] as String?,
      isVerified: true,
    );
  }
}