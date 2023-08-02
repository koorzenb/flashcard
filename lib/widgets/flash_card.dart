import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../models/word.dart';
import '../screens/update_screen.dart';

class FlashCard extends StatefulWidget {
  const FlashCard({super.key});

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  late Word displayedWord;
  bool _showBody = false;

  @override
  void initState() {
    displayedWord = Word.getWord();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() {
        displayedWord = Word.getWord();
        _showBody = true;
      }),
      onLongPress: () async => await _updateWord(),
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayedWord.hebrew,
                style: const TextStyle(fontSize: 45, fontFamily: "Frank Ruhl Libre"),
              ),
              Animate(
                child: Column(children: [
                  Text(
                    displayedWord.pronunciation,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    displayedWord.translation,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (displayedWord.attributes != null)
                    Text(
                      displayedWord.attributes!,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                ]).animate().fadeIn(curve: Curves.easeIn, delay: const Duration(seconds: 2)).callback(callback: (_) => _showBody = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateWord() async {
    final updatedWord = await Get.to(() => UpdateScreen(word: displayedWord)); // TODO: consider having an setup mode - then hide update and add button
    if (updatedWord != null) {
      setState(
        () {
          displayedWord = updatedWord;
        },
      );
    }
  }
}
