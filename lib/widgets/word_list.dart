import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/word_controller.dart';
import '../screens/word_details_screen.dart';

class WordList extends StatelessWidget {
  final textEditingController = TextEditingController();

  WordList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(
          controller: textEditingController,
          onChanged: (value) => WordController.instance.onSearchChange(value),
          hintText: 'Search...',
        ),
        Expanded(
          child: GetBuilder<WordController>(builder: (wordController) {
            return ListView.builder(
              itemCount: wordController.filteredWords.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () async => await Get.to(() => WordDetailsScreen(
                      title: 'Update Word',
                      word: wordController.filteredWords[index],
                    )),
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
                                wordController.filteredWords[index].native),
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
    );
  }
}
