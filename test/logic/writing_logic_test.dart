import 'package:flashcard/logic/writing_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkWord() -', () {
    late int initialAttemptsRemaining;

    setUpAll(() {
      initialAttemptsRemaining = 2;
    });

    test('wrong word', () {
      var res = WritingLogic.checkWord('example', 'example2', initialAttemptsRemaining);

      expect(res.isCorrect, isFalse);
      expect(res.icon.icon, Icons.close);
      expect(res.updateCurrentWord, isFalse);
      expect(res.attemptsRemaining, 1);

      res = WritingLogic.checkWord('example', 'example2', res.attemptsRemaining);

      expect(res.isCorrect, isFalse);
      expect(res.icon.icon, Icons.close);
      expect(res.updateCurrentWord, isFalse);
      expect(res.attemptsRemaining, 0);
    });

    test('first wrong, then right', () {
      var res = WritingLogic.checkWord('example', 'example2', initialAttemptsRemaining);

      expect(res.isCorrect, isFalse);
      expect(res.icon.icon, Icons.close);
      expect(res.updateCurrentWord, isFalse);
      expect(res.attemptsRemaining, 1);

      res = WritingLogic.checkWord('example2', 'example2', res.attemptsRemaining);

      expect(res.isCorrect, isTrue);
      expect(res.icon.icon, Icons.check);
      expect(res.updateCurrentWord, isTrue);
      expect(res.attemptsRemaining, 2);
    });

    test('right word', () {
      var res = WritingLogic.checkWord('example', 'example', initialAttemptsRemaining);

      expect(res.isCorrect, isTrue);
      expect(res.icon.icon, Icons.check);
      expect(res.updateCurrentWord, isTrue);
      expect(res.attemptsRemaining, 2);
    });
  });
}
