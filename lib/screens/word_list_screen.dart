import 'package:flashcard/controllers/flash_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'word_details_screen.dart';

class WordListScreen extends StatelessWidget {
  const WordListScreen({super.key});

// get controller to correct reflect words - add a test word, delete and check for update

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlashCard')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GetBuilder<FlashCardController>(builder: (flashCardController) {
          return ListView.builder(
            itemCount: flashCardController.words.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () async => await Get.to(() => WordDetailsScreen(title: 'Update Word', word: flashCardController.words[index])),
              child: flashCardController.words.isEmpty
                  ? Center(child: const Text('No words here. Add some words!')) // TODO: this is not working
                  : Column(
                      children: [
                        ListTile(
                          title: Text(flashCardController.words[index].translation),
                          subtitle: Text(flashCardController.words[index].hebrew),
                        ),
                        const Divider(
                          thickness: 1,
                          color: Colors.grey,
                        ),
                      ],
                    ),
            ),
          );
        }),
      ),
    );
  }
}
