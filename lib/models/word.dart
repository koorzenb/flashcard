class Word {
  final String id;
  final String hebrew;
  final String pronunciation;
  final String translation;
  final String attributes;

  Word({this.id = '', required this.hebrew, required this.pronunciation, required this.translation, this.attributes = ''});

  Map<String, dynamic> toJson() => {
        'id': id,
        'hebrew': hebrew,
        'pronunciation': pronunciation,
        'translation': translation,
        'attributes': attributes,
      };

  static List<dynamic> arrayToJsonList(List<Word> words) {
    return List<dynamic>.from(
      words.map((x) => x.toJson()),
    );
  }

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: json['id'],
        hebrew: json['hebrew'],
        pronunciation: json['pronunciation'],
        translation: json['translation'],
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
