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
  String preferredCategory;
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
  String preferredCountry;
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

  bool isVerified;

  SeekerProfileModel({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.countryCode = 'IN',
    this.experienceLevel = ExperienceLevel.mid,
    this.preferredCategory = 'IT & Software',
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
    this.preferredCountry = '',
    List<String>? workModes,
    List<String>? jobTypes,
    this.expectedSalary = '',
    this.availability = '',
    this.headline = '',
    this.department = '',
    List<String>? projects,
    List<String>? languages,
    this.openToRelocate,
    this.hasWorkPermit,
    this.isVerified = false,
  })  : skills = skills ?? [],
        workModes = workModes ?? [],
        jobTypes = jobTypes ?? [],
        projects = projects ?? [],
        languages = languages ?? [];

  bool get isProfileFilledOut => name.trim().isNotEmpty && email.trim().isNotEmpty;

  String get experienceYears => experienceLevel.shortLabel;

  /// Dynamic profile strength calculation (0 to 100%)
  int get profileStrengthPercent {
    int score = 0;
    // 1. Basic Account & Contact (Name + Phone): 25%
    if (name.trim().isNotEmpty && phone.trim().isNotEmpty) {
      score += 25;
    } else if (name.trim().isNotEmpty || phone.trim().isNotEmpty) {
      score += 15;
    }

    // 2. Email Address: 15%
    if (email.trim().isNotEmpty) {
      score += 15;
    }

    // 3. Resume Document: 20%
    if (resumeFileName != null && resumeFileName!.trim().isNotEmpty) {
      score += 20;
    }

    // 4. Skills & Competencies: up to 20%
    if (skills.length >= 3) {
      score += 20;
    } else if (skills.isNotEmpty) {
      score += (skills.length * 7).clamp(0, 20);
    }

    // 5. Executive Bio: up to 20%
    if (bio.trim().length >= 30) {
      score += 20;
    } else if (bio.trim().isNotEmpty) {
      score += 10;
    }

    return score.clamp(0, 100);
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
      preferredCategory: json['preferredCategory'] as String? ?? 'IT & Software',
      bio: json['bio'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      resumeFileName: json['resumeFileName'] as String?,
      isVerified: true,
    );
  }
}