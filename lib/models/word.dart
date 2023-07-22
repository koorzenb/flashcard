import 'dart:math';

import 'package:flashcard/controllers/flash_card_controller.dart';

class Word {
  final String hebrew;
  final String pronunciation;
  final String translation;
  final String? attributes;
  static List<int> indexListOfUndisplayedWords = []; // index of words that has not been displayed
  static final FlashCardController flashCardController = FlashCardController.getOrPut;

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
    // final words = WordStorage.box.words;

    if (indexListOfUndisplayedWords.isEmpty) {
      _initializeUndisplayedIndexList(indexListOfUndisplayedWords, flashCardController.words);
    }

    // randomize showing of words and remove previous shown words from list until all words are shown
    final randomIndex = Random().nextInt(indexListOfUndisplayedWords.length);
    final wordIndex = indexListOfUndisplayedWords[randomIndex];
    indexListOfUndisplayedWords.remove(wordIndex);

    return flashCardController.words[wordIndex];
  }

  static void _initializeUndisplayedIndexList(List<int> undisplayedIndexList, List<Word> words) {
    for (var i = 0; i < words.length; i++) {
      undisplayedIndexList.add(i);
    }
  }

  static updateWord(Word? originalWord, Word updatedWord) {
    final words = flashCardController.words;
    if (originalWord != null) {
      words.remove(originalWord);
    }
    words.add(updatedWord);
    flashCardController.words = words;
  }

  static removeWord(Word word) {
    flashCardController.words.remove(word);
  }
}
