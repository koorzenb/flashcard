import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/word_controller.dart';
import '../models/word.dart';
import '../widgets/flash_card.dart';
import 'word_details_screen.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading'),
      ),
      body: GetBuilder<WordController>(builder: (wordController) {
        return Center(
          child: wordController.currentWord.hebrew.isEmpty
              ? Text('No words to display')
              : FlashCardWidget(
                  displayedWord: wordController.currentWord,
                ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await Get.to(() => WordDetailsScreen(
              title: 'Add Word',
              word: Word(
                hebrew: '',
                pronunciation: '',
                translation: '',
                attributes: '',
                isNew: true,
              ),
            )),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
