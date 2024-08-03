import 'package:flashcard/controllers/word_controller.dart';
import 'package:flashcard/models/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FlashCardWidget extends StatefulWidget {
  const FlashCardWidget({super.key});

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> {
  bool _showBody = false;

  @override
  Widget build(BuildContext context) {
    _delayShowingTranslation();

    return GetBuilder<WordController>(builder: (flashCardController) {
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
                  style: const TextStyle(fontSize: 45, fontFamily: 'Noto Sans Hebrew'),
                ),
                AnimatedOpacity(
                  opacity: _showBody ? 1.0 : 0.0,
                  duration: _showBody
                      ? const Duration(milliseconds: Constants.hideDuration)
                      : Duration.zero, // TODO: display circular countdown timer before showing pronounciation/meaning
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
