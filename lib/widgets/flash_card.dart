import 'package:flashcard/models/word.dart';
import 'package:flutter/material.dart';

class FlashCard extends StatelessWidget {
  const FlashCard({super.key});

  @override
  Widget build(BuildContext context) {
    final word = Word(hebrew: "אַבָּא", translation: 'father', attributes: 'ml, s');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // const SizedBox(height: 8),
            Text(
              word.hebrew,
              style: const TextStyle(fontSize: 32),
            ),
            Text(
              word.translation,
              style: const TextStyle(fontSize: 16),
            ),
            if (word.attributes != null)
              Text(
                word.attributes!,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
