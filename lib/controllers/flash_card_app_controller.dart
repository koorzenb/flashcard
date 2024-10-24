import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/main_app_storage.dart';
import '../widgets/custom_dialog.dart';

class FlashCardAppController extends GetxController {
  static FlashCardAppController get getOrPut {
    try {
      return Get.find<FlashCardAppController>();
    } catch (e) {
      return Get.put(FlashCardAppController._());
    }
  }

  FlashCardAppController._() {}

  void showWelcomeScreen() async {
    if (!MainAppStorage.box.displayedWelcomeScreen) {
      await _showWelcomeScreen();
      MainAppStorage.box.displayedWelcomeScreen = true;
      update();
    }
  }

  Future<void> _showWelcomeScreen() async {
    final dividerHeight = 50.0; // TODO: percentage of screen
    final context = Get.context!;

    await CustomDialog.showWelcomeMessage(
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
            child: Text('Welcome to FlashLearn!', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.secondary)),
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
}
