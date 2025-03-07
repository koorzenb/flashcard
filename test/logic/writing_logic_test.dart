import 'package:flashcard/logic/writing_logic.dart';
import 'package:flashcard/models/word.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkWord() -', () {
    late int initialAttemptsRemaining;
    late int startingScore;
    late Word wrongWord;

    setUpAll(() {
      initialAttemptsRemaining = 2;
      startingScore = 0;
      wrongWord = Word(native: 'example2', pronunciation: '', translation: '');
    });

    test('wrong word', () {
      var res = WritingLogic.checkWord('example', wrongWord, initialAttemptsRemaining, startingScore);

      expect(res.isCorrect, isFalse);
      expect(res.icon.icon, Icons.close);
      expect(res.updateCurrentWord, isFalse);
      expect(res.translation, '');
      expect(res.attemptsRemaining, 1);
      expect(res.score, 0);

      res = WritingLogic.checkWord('example', wrongWord, res.attemptsRemaining, res.score);

      expect(res.isCorrect, isFalse);
      expect(res.icon.icon, Icons.close);
      expect(res.updateCurrentWord, isFalse);
      expect(res.translation, '');
      expect(res.attemptsRemaining, 0);
      expect(res.score, 0);
    });

    test('first wrong, then right', () {
      var res = WritingLogic.checkWord('example', wrongWord, initialAttemptsRemaining, startingScore);

      expect(res.isCorrect, isFalse);
      expect(res.icon.icon, Icons.close);
      expect(res.updateCurrentWord, isFalse);
      expect(res.translation, '');
      expect(res.attemptsRemaining, 1);
      expect(res.score, 0);

      res = WritingLogic.checkWord('example', Word(native: 'example', pronunciation: '', translation: 'tExample'), res.attemptsRemaining, res.score);

      expect(res.isCorrect, isTrue);
      expect(res.icon.icon, Icons.check);
      expect(res.updateCurrentWord, isTrue);
      expect(res.translation, 'tExample');
      expect(res.attemptsRemaining, 2);
      expect(res.score, 0);
    });

    test('right word', () {
      var res = WritingLogic.checkWord('example', Word(native: 'example', pronunciation: '', translation: 'tExample'), initialAttemptsRemaining, startingScore);

      expect(res.isCorrect, isTrue);
      expect(res.icon.icon, Icons.check);
      expect(res.updateCurrentWord, isTrue);
      expect(res.translation, 'tExample');
      expect(res.attemptsRemaining, 2);
      expect(res.score, 1);
    });
  });
}
