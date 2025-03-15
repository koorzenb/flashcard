import 'package:flutter/material.dart';

import '../models/word.dart';
import 'check_word_result.dart';

class WritingLogic {
  static CheckWordResult checkWord(String enteredText, Word currentWord, int attemptsRemaining, int score) {
    final isCorrect = enteredText == currentWord.native;

    if (!isCorrect) {
      if (attemptsRemaining == 0) {
        return CheckWordResult(
          isCorrect: isCorrect,
          icon: Icon(
            Icons.close,
            color: Colors.red,
          ),
          updateCurrentWord: true,
          translation: currentWord.translation,
          attemptsRemaining: 2,
          score: score,
        );
      } else {
        attemptsRemaining--;
        return CheckWordResult(
          isCorrect: isCorrect,
          icon: Icon(
            Icons.close,
            color: Colors.red,
          ),
          updateCurrentWord: false,
          translation: '',
          attemptsRemaining: attemptsRemaining,
          score: score,
        );
      }
    } else {
      return CheckWordResult(
        isCorrect: isCorrect,
        icon: Icon(
          Icons.check,
          color: Colors.green,
        ),
        updateCurrentWord: true,
        translation: currentWord.translation,
        attemptsRemaining: 2,
        score: attemptsRemaining == 2 ? score + 1 : score,
      );
    }
  }
}
