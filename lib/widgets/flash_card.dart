import 'package:flashcard/models/word.dart';
import 'package:flutter/material.dart';

class FlashCard extends StatelessWidget {
  const FlashCard({super.key});

  @override
  Widget build(BuildContext context) {
    final word = Word(hebrew: "אַבָּא", translation: 'father');
    return Card(
      elevation: 2,
      child: Text(word.hebrew),
    );
  }
}
