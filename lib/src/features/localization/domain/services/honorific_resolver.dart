/// Honorific (title) resolution for Arabic: title + gender → localized string.
/// Unknown titles fall back to name only or a generic label per spec US7.
library;

import '../entities/user_context.dart';

/// Default Arabic honorific strings (male/female) for common titles.
/// Keys are normalized lowercase (e.g. "dr", "mr", "mrs", "engineer").
const Map<String, Map<ResolutionGender, String>> kArabicHonorifics = {
  'dr': {ResolutionGender.male: 'د.', ResolutionGender.female: 'د.'},
  'mr': {ResolutionGender.male: 'السيد', ResolutionGender.female: 'السيدة'},
  'mrs': {ResolutionGender.male: 'السيد', ResolutionGender.female: 'السيدة'},
  'miss': {ResolutionGender.male: 'السيد', ResolutionGender.female: 'الآنسة'},
  'ms': {ResolutionGender.male: 'السيد', ResolutionGender.female: 'السيدة'},
  'engineer': {ResolutionGender.male: 'م.‏', ResolutionGender.female: 'م.‏'},
  'prof': {ResolutionGender.male: 'أ.د.', ResolutionGender.female: 'أ.د.'},
  'professor': {ResolutionGender.male: 'أ.د.', ResolutionGender.female: 'أ.د.'},
};

/// Resolves an honorific title with [gender] to a localized string (e.g. Arabic).
/// [title] is normalized (trimmed, lowercased, dots removed); if it matches a known
/// key in [kArabicHonorifics], returns the corresponding male/female string; otherwise
/// returns [nameOnly] (show name only) or [unknownLabel] if [nameOnly] is null/empty.
String resolveHonorific(
  String title,
  ResolutionGender gender, {
  String? nameOnly,
  String unknownLabel = '',
}) {
  final normalized = title.trim().toLowerCase().replaceAll(RegExp(r'[.\s]+'), '');
  if (normalized.isEmpty) return nameOnly?.trim() ?? unknownLabel;
  final map = kArabicHonorifics[normalized];
  if (map != null) return map[gender] ?? map[ResolutionGender.male]!;
  return nameOnly?.trim() ?? unknownLabel;
}
