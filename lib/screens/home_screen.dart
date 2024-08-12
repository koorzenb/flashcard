import 'package:flashcard/controllers/word_controller.dart';
import 'package:flashcard/widgets/version_code_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/word.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/flash_card.dart';
import '../widgets/main_drawer.dart';
import 'word_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dividerHeight = 50.0; // TODO: percentage of screen

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CustomDialog.showWelcomeMessage(
          content: Column(
            children: [
              Hero(
                tag: 'image',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0), // Adjust the value as needed
                  child: Image.asset('assets/images/hero_welcome.jpeg'),
                ),
              ),
              SizedBox(height: dividerHeight),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    Text('Welcome to FlashLearn!', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.secondary)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Ready for a fun and interactive language learning experience? ',
                  style: Theme.of(context).textTheme.bodyLarge!,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: dividerHeight),
              ElevatedButton(
                onPressed: Get.back,
                child: Text("Let's go!"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
    super.initState();
  }

  final flashCardController = WordController.getOrPut;

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
