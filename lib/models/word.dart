import 'word_attributes.dart';

class Word {
  final String id;
  final String native;
  final String pronunciation;
  final String translation;
  final WordAttributes attributes;
  String audioId;
  final bool isNew;

  Word(
      {this.id = '',
      required this.native,
      required this.pronunciation,
      required this.translation,
      this.attributes = const WordAttributes.blank(),
      this.audioId = '',
      this.isNew = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'native': native,
        'pronunciation': pronunciation,
        'translation': translation,
        'attributes': attributes.toJson(),
        'audioId': audioId,
        'isNew': isNew,
      };

  static List<dynamic> arrayToJsonList(List<Word> words) {
    return List<dynamic>.from(
      words.map((x) => x.toJson()),
    );
  }

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: json['id'],
        native: json['native'],
        pronunciation: json['pronunciation'],
        translation: json['translation'],
        attributes: WordAttributes.fromJson(json['attributes']),
        audioId: json['audioId'],
        isNew: json['isNew'] ?? false,
      );

  static List<Word> listFromJsonList(List<dynamic> jsonList) {
    try {
      return List<Word>.from(jsonList.map((x) => Word.fromJson(x)));
    } catch (_) {
      return [];
    }
  }
}
