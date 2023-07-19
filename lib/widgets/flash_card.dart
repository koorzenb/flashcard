import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/word.dart';
import '../screens/update_screen.dart';

class FlashCard extends StatefulWidget {
  final Word word;

  const FlashCard({required this.word, super.key});

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  late Word displayedWord;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    displayedWord = widget.word;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() {
        displayedWord = Word.getWord();
        debugPrint(displayedWord.translation);
      }),
      child: GestureDetector(
        onLongPress: () async {
          final updatedWord = await Get.to(UpdateScreen(word: displayedWord)); // TODO: consider having an setup mode - then hide update and add button
          if (updatedWord != null) {
            setState(
              () {
                displayedWord = updatedWord;
              },
            );
          }
        },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
