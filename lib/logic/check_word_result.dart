import 'package:flutter/widgets.dart';

class CheckWordResult {
  final bool isCorrect;
  final Icon icon;
  final bool updateCurrentWord;
  final String translation;
  final int attemptsRemaining;
  final int score;

  CheckWordResult({
    required this.isCorrect,
    required this.icon,
    required this.updateCurrentWord,
    required this.translation,
    required this.attemptsRemaining,
    required this.score,
  });
}
