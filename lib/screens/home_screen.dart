import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/flash_card_app_controller.dart';
import '../controllers/word_controller.dart';
import '../models/word.dart';
import '../storage/main_app_storage.dart';
import '../widgets/flash_card.dart';
import '../widgets/main_drawer.dart';
import '../widgets/version_code_text.dart';
import 'word_details_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WordController.getOrPut;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MainAppStorage.box.displayedWelcomeScreen) {
        KardsAppController.getOrPut.showWelcomeScreen();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            VersionCodeText(),
          ],
        ),
      ),
      drawer: MainDrawer(),
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
