import 'package:flashcard/controllers/flash_card_controller.dart';
import 'package:flashcard/logic/word_logic.dart';
import 'package:flutter/material.dart';
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
    displayedWord = Word(hebrew: "דָבָר", pronunciation: 'de-var', translation: 'word');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _delayShowingTranslation();

    return GestureDetector(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: GetBuilder<FlashCardController>(builder: (flashCardController) {
        // need controller here to update word list after a deletion
        return Card(
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
                AnimatedOpacity(
                  opacity: _showBody ? 1.0 : 0.0,
                  duration: _showBody ? const Duration(milliseconds: 500) : Duration.zero,
                  child: Column(children: [
                    Text(
                      displayedWord.pronunciation,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      displayedWord.translation,
                      style: const TextStyle(fontSize: 12, color: Colors.grey), // TODO: move to theme
                    ),
                    if (displayedWord.attributes != null)
                      Text(
                        displayedWord.attributes!,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                  ]),
                )
              ],
            ),
          ),
        );
      }),
    );
  }

  _onTap() {
    setState(() {
      displayedWord = WordLogic(FlashCardController.getOrPut.words).word;
      _showBody = false;
      debugPrint(displayedWord.translation);
    });
  }

  _onLongPress() async {
    final updatedWord = await Get.to(() => UpdateScreen(word: displayedWord)); // TODO: consider having an setup mode - then hide update and add button
    if (updatedWord != null) {
      FlashCardController.getOrPut.updateDisplayedWord();
      setState(
        () {
          displayedWord = updatedWord;
        },
      );
    }
  }

  _delayShowingTranslation() {
    if (!_showBody) {
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _showBody = true;
        });
      });
    }
  }
}
