import 'gender.dart';

class WordAttributes {
  final Gender gender;
  final bool isPlural;

  const WordAttributes({required this.gender, required this.isPlural});

  const WordAttributes.blank()
      : gender = Gender.neutral,
        isPlural = false;

  Map<String, dynamic> toJson() => {
        'gender': gender.name,
        'isPlural': isPlural,
      };

  factory WordAttributes.fromJson(Map<String, dynamic> json) => WordAttributes(
        gender: Gender.values.firstWhere((g) => g.name == json['gender']),
        isPlural: json['isPlural'] ?? false,
      );

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
