import 'gender.dart';

/// Structured attributes of a [Word].
///
/// The parser is intentionally total: it never throws, so a single malformed
/// record can never abort the loading of an entire word list.
class WordAttributes {
  final Gender gender;
  final bool isPlural;

  const WordAttributes({required this.gender, required this.isPlural});

  const WordAttributes.blank()
      : gender = Gender.neutral,
        isPlural = false;

  /// Legacy free-text tokens mapped to a gender.
  static const Map<String, Gender> _legacyGenders = {
    'masculine': Gender.male,
    'male': Gender.male,
    'm': Gender.male,
    'feminine': Gender.female,
    'female': Gender.female,
    'f': Gender.female,
    'neutral': Gender.neutral,
    'n': Gender.neutral,
  };

  /// Legacy free-text tokens marking a plural word.
  static const Set<String> _legacyPluralTokens = {'pl', 'plural'};

  Map<String, dynamic> toJson() => {
        'gender': gender.name,
        'isPlural': isPlural,
      };

  /// Builds attributes from any persisted shape.
  ///
  /// Accepts the current map format (`gender`/`isPlural`), the legacy
  /// free-text string format, and `null`/missing values. Unknown or malformed
  /// input degrades to [WordAttributes.blank] instead of throwing.
  factory WordAttributes.fromJson(dynamic json) {
    if (json is String) {
      return WordAttributes.fromLegacy(json);
    }
    if (json is! Map) {
      return const WordAttributes.blank();
    }
    return WordAttributes(
      gender: _genderFromValue(json['gender']),
      isPlural: json['isPlural'] == true,
    );
  }

  /// Maps legacy free-text attributes to a structured value.
  ///
  /// Unrecognized text maps to [Gender.neutral] and `isPlural: false`.
  static WordAttributes fromLegacy(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const WordAttributes.blank();
    }

    final tokens = normalized.split(RegExp(r'[\s,/|]+'));
    var gender = Gender.neutral;
    var isPlural = false;

    for (final token in tokens) {
      final mapped = _legacyGenders[token];
      if (mapped != null) {
        gender = mapped;
        continue;
      }
      if (_legacyPluralTokens.contains(token)) {
        isPlural = true;
      }
    }

    return WordAttributes(gender: gender, isPlural: isPlural);
  }

  /// Resolves a persisted gender value, falling back to [Gender.neutral].
  static Gender _genderFromValue(dynamic value) {
    if (value is Gender) {
      return value;
    }
    if (value is! String) {
      return Gender.neutral;
    }
    for (final gender in Gender.values) {
      if (gender.name == value.trim().toLowerCase()) {
        return gender;
      }
    }
    return Gender.neutral;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordAttributes &&
          runtimeType == other.runtimeType &&
          gender == other.gender &&
          isPlural == other.isPlural;

  @override
  int get hashCode => Object.hash(gender, isPlural);
}
