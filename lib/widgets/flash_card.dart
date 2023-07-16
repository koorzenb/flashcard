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
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120, // TODO: fix to word width
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 30,
                      child: IconButton(
                          onPressed: () async {
                            final updatedWord = await Get.to(UpdateScreen(word: displayedWord));
                            setState(() {
                              displayedWord = updatedWord;
                            });
                          },
                          iconSize: 10,
                          icon: const Icon(
                            Icons.edit,
                            size: 10,
                          )),
                    )
                  ],
                ),
              ),
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
    );
  }
}
