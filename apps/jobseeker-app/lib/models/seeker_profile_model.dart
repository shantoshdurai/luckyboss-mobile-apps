enum ExperienceLevel {
  entry,
  mid,
  senior,
  lead;

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
    this.isVerified = false,
  }) : skills = skills ?? [];

  bool get isProfileFilledOut => name.trim().isNotEmpty && email.trim().isNotEmpty;

  String get experienceYears => experienceLevel.shortLabel;

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