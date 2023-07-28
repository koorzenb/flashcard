import 'package:flashcard/word_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'update_screen.dart';

class WordListScreen extends StatelessWidget {
  const WordListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wordList = [...WordStorage.box.words];
    wordList.sort(((firstWord, secondWord) => firstWord.translation.compareTo(secondWord.translation)));

    return Scaffold(
      appBar: AppBar(title: const Text('Flashy')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: wordList.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () async => await Get.to(() => UpdateScreen(word: wordList[index])),
            child: Column(
              children: [
                ListTile(
                  title: Text(wordList[index].translation),
                  subtitle: Text(wordList[index].hebrew),
                ),
                const Divider(
                  thickness: 1,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
