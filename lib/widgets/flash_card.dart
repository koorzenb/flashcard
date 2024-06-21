import 'package:flashcard/controllers/flash_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FlashCard extends StatefulWidget {
  const FlashCard({super.key});

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  bool _showBody = false;

  @override
  Widget build(BuildContext context) {
    _delayShowingTranslation();

    return GetBuilder<FlashCardController>(builder: (flashCardController) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _showBody = false;
            flashCardController.onTap();
          });
        },
        onLongPress: flashCardController.onLongPress,
        // need controller here to update word list after a deletion
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  flashCardController.displayedWord.hebrew,
                  style: const TextStyle(fontSize: 45, fontFamily: 'Frank Ruhl Libre'),
                ),
                AnimatedOpacity(
                  opacity: _showBody ? 1.0 : 0.0,
                  duration: _showBody ? const Duration(milliseconds: 500) : Duration.zero,
                  child: Column(children: [
                    Text(
                      flashCardController.displayedWord.pronunciation,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      flashCardController.displayedWord.translation,
                      style: const TextStyle(fontSize: 12, color: Colors.grey), // TODO: move to theme
                    ),
                    flashCardController.displayedWord.attributes.isNotEmpty
                        ? Text(
                            flashCardController.displayedWord.attributes,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                          )
                        : SizedBox(),
                  ]),
                )
              ],
            ),
          ),
        ),
      );
    });
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
