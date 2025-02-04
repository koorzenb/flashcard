import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/word_controller.dart';
import 'word_details_screen.dart';

class WordListScreen extends StatelessWidget {
  final textEditingController = TextEditingController();

  WordListScreen({super.key});

// get controller to correct reflect words - add a test word, delete and check for update

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word List')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SearchBar(
              controller: textEditingController,
              onChanged: (value) =>
                  WordController.getOrPut.onSearchChange(value),
              hintText: 'Search...',
            ),
            Expanded(
              child: GetBuilder<WordController>(builder: (wordController) {
                return ListView.builder(
                  itemCount: wordController.filteredWords.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () async => await Get.to(() => WordDetailsScreen(
                        title: 'Update Word',
                        word: wordController.filteredWords[index])),
                    child: wordController.filteredWords.isEmpty
                        ? Center(
                            child: const Text(
                                'No words here. Add some words!')) // FIXME: this is not working
                        : Column(
                            children: [
                              ListTile(
                                title: Text(wordController
                                    .filteredWords[index].translation),
                                subtitle: Text(
                                    wordController.filteredWords[index].hebrew),
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
          ],
        ),
      ),
    );
  }
}
