import 'dart:math';

class Word {
  final String hebrew;
  final String translation;
  final String? attributes;

  Word({required this.hebrew, required this.translation, this.attributes = ''});

  static Word getWord() {
    final List<Word> words = [
      Word(hebrew: "אַבָּא", translation: "father", attributes: 'm, sl'),
      Word(hebrew: "אִמָא", translation: "mother", attributes: 'f, sl'),
      Word(hebrew: "יוֹנָה", translation: "dove"),
      Word(hebrew: "לחם", translation: "bread"),
    ];

    final randomIndex = Random().nextInt(words.length);
    return words[randomIndex];
  }

  Map<String, dynamic> toJson() => {
        'hebrew': hebrew,
        'translation': translation,
        "attributes": attributes,
      };

  static List<dynamic> arrayToJsonList(List<Word> words) {
    return List<dynamic>.from(
      words.map((x) => x.toJson()),
    );
  }

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        hebrew: json['hebrew'],
        translation: json["translation"],
        attributes: json['attributes'],
      );

  static List<Word> listFromJsonList(List<dynamic> jsonList) {
    try {
      return List<Word>.from(jsonList.map((x) => Word.fromJson(x)));
    } catch (_) {
      return [];
    }
  }
}
