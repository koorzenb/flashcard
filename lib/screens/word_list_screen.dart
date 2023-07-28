import 'package:flashcard/word_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'update_screen.dart';

class WordListScreen extends StatelessWidget {
  const WordListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WordStorage.box.words.sort(((firstWord, secondWord) => firstWord.translation.compareTo(secondWord.translation)));

    return Scaffold(
      appBar: AppBar(title: const Text('Flashy')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(children: [
          ...WordStorage.box.words.map(
            (word) => GestureDetector(
              onTap: () async => await Get.to(() => UpdateScreen(word: word)),
              child: Column(
                children: [
                  ListTile(
                    title: Text(word.translation),
                    subtitle: Text(word.hebrew),
                  ),
                  const Divider(
                    thickness: 1,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
