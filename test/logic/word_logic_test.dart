import 'package:flashcard/logic/word_logic.dart';
import 'package:flashcard/models/word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updating unread words', () {
    final allWords = [
      Word(
        hebrew: 'שלום',
        pronunciation: 'shalom',
        translation: 'hello',
        attributes: 'greeting',
      ),
      Word(
        hebrew: 'להתראות',
        pronunciation: 'lehitraot',
        translation: 'goodbye',
        attributes: 'greeting',
      ),
    ];

    final wordLogic = WordLogic(allWords);
    final newWord = wordLogic.word;
    expect(allWords.length, 1);
  });
}
