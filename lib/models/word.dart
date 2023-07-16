import 'dart:math';

import 'package:flashcard/word_storage.dart';

class Word {
  final String hebrew;
  final String pronunciation;
  final String translation;
  final String? attributes;

  Word({required this.hebrew, required this.pronunciation, required this.translation, this.attributes = ''});

  static Word getWord() {
    final List<Word> words = [
      //TODO: save to localStorage.
      // save only on update/new
      // Save to GoogleDrive
      Word(hebrew: "אַבָּא", pronunciation: "a-bah", translation: "father", attributes: 'm, sl'),
      Word(hebrew: "אִמָא", pronunciation: 'i-mah', translation: "mother", attributes: 'f, sl'),
      Word(hebrew: "יוֹנָה", pronunciation: "joh-nah", translation: "dove"),
      Word(hebrew: "לחם", pronunciation: "le-khem", translation: "bread"),
    ];

    final randomIndex = Random().nextInt(words.length);
    return words[randomIndex];
  }

  static saveWord(Word word) {
    WordStorage.box.words.add(word);
  }

  Map<String, dynamic> toJson() => {
        'hebrew': hebrew,
        'pronunciation': pronunciation,
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
        pronunciation: json['pronunciation'],
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
