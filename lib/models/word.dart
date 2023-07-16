import 'dart:math';

import '../word_storage.dart';

class Word {
  final String hebrew;
  final String pronunciation;
  final String translation;
  final String? attributes;
  static List<int> indexListOfUndisplayedWords = []; // index of words that has not been displayed

  Word({required this.hebrew, required this.pronunciation, required this.translation, this.attributes = ''});

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

  static Word getWord() {
    final words = WordStorage.box.words;

    if (indexListOfUndisplayedWords.isEmpty) {
      _initializeUndisplayedIndexList(indexListOfUndisplayedWords, words);
    }

    // randomize showing of words and remove previous shown words from list until all words are shown
    final randomIndex = Random().nextInt(indexListOfUndisplayedWords.length);
    final wordIndex = indexListOfUndisplayedWords[randomIndex];
    indexListOfUndisplayedWords.remove(wordIndex);

    return words[wordIndex];
  }

  static void _initializeUndisplayedIndexList(List<int> undisplayedIndexList, List<Word> words) {
    for (var i = 0; i < words.length; i++) {
      undisplayedIndexList.add(i);
    }
  }

  static createWord(Word word) {
    // final words = WordStorage.box.words;
    final List<Word> words = [
      // TODO: Save to GoogleDrive
      Word(hebrew: "אַבָּא", pronunciation: "a-bah", translation: "father", attributes: 'm, sl'),
      Word(hebrew: "אִמָא", pronunciation: 'i-mah', translation: "mother", attributes: 'f, sl'),
      Word(hebrew: "יוֹנָה", pronunciation: "joh-nah", translation: "dove"),
      Word(hebrew: "לחם", pronunciation: "le-khem", translation: "bread"),
    ];
    words.add(word);
    WordStorage.box.words = words;
  }

  static updateWord(Word originalWord, Word word) {
    final words = WordStorage.box.words;
    words.remove((element) => element.hebrew == originalWord.hebrew);
    words.add(word);
    WordStorage.box.words = words;
  }
}
