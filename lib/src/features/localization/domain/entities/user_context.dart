/// User or resolution context for Arabic (and other locale) message resolution.
/// App-level default with optional per-call overrides per spec.
library;

/// Gender for message resolution; only male or female. Default when not set is male.
enum ResolutionGender {
  male,
  female,
}

/// Regional variant (dialect) for Arabic. Default when not set is MSA.
enum RegionalVariant {
  msa,
  gulf,
  egyptian,
}

/// Formality level for pronouns and phrasing.
enum FormalityLevel {
  formal,
  informal,
}

/// Context used for message resolution: locale, gender, formality, regional variant.
/// Defaults: gender = male, regionalVariant = MSA when not set.
class UserContext {
  const UserContext({
    required this.locale,
    this.gender = ResolutionGender.male,
    this.formality = FormalityLevel.formal,
    this.regionalVariant = RegionalVariant.msa,
  });

  /// Locale code (e.g. 'ar', 'ar_SA', 'en').
  final String locale;

  /// Gender for gendered strings. Default male.
  final ResolutionGender gender;

  /// Formality for formal/informal variants.
  final FormalityLevel formality;

  /// Regional variant (e.g. MSA, Gulf, Egyptian). Default MSA.
  final RegionalVariant regionalVariant;

  UserContext copyWith({
    String? locale,
    ResolutionGender? gender,
    FormalityLevel? formality,
    RegionalVariant? regionalVariant,
  }) {
    return UserContext(
      locale: locale ?? this.locale,
      gender: gender ?? this.gender,
      formality: formality ?? this.formality,
      regionalVariant: regionalVariant ?? this.regionalVariant,
    );
  }

  /// Merge overrides onto this context. Overrides win.
  UserContext mergeOverrides({
    String? locale,
    ResolutionGender? gender,
    FormalityLevel? formality,
    RegionalVariant? regionalVariant,
  }) {
    return UserContext(
      locale: locale ?? this.locale,
      gender: gender ?? this.gender,
      formality: formality ?? this.formality,
      regionalVariant: regionalVariant ?? this.regionalVariant,
    );
  }
}
