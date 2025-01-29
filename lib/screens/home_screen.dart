import 'package:flashcard/controllers/flash_card_app_controller.dart';
import 'package:flashcard/controllers/word_controller.dart';
import 'package:flashcard/widgets/version_code_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/word.dart';
import '../widgets/flash_card.dart';
import '../widgets/main_drawer.dart';
import 'word_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({
    required this.title,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WordController.getOrPut;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(width: 10.0),
            VersionCodeText(),
          ],
        ),
      ),
      drawer: MainDrawer(),
      body: const Center(
        child: FlashCardWidget(),
      ),
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
