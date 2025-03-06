import 'package:flashcard/logic/check_word_result.dart';
import 'package:flutter/material.dart';

class WritingLogic {
  static CheckWordResult checkWord(String enteredText, String currentWord, int attemptsRemaining) {
    final isCorrect = enteredText == currentWord;

    if (!isCorrect) {
      if (attemptsRemaining == 0) {
        return CheckWordResult(
          isCorrect: isCorrect,
          icon: Icon(
            Icons.close,
            color: Colors.red,
          ),
          updateCurrentWord: true,
          attemptsRemaining: 2,
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
          attemptsRemaining: attemptsRemaining,
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
        attemptsRemaining: 2,
      );
    }
  }
}
