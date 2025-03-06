import 'package:flutter/widgets.dart';

class CheckWordResult {
  final bool isCorrect;
  final Icon icon;
  final bool updateCurrentWord;
  final int attemptsRemaining;

  CheckWordResult({required this.isCorrect, required this.icon, required this.updateCurrentWord, required this.attemptsRemaining});
}
