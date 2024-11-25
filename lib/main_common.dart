import 'package:firebase_core/firebase_core.dart';
import 'package:flashcard/models/server_environment.dart';
import 'package:flashcard/services/flashcard_api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/flash_card_app_controller.dart';
import 'controllers/word_controller.dart';
import 'screens/home_screen.dart';
import 'storage/main_app_storage.dart';
import 'storage/word_storage.dart';
import 'styles/themes.dart';

Future<void> commonInit(FirebaseOptions currentPlatform, ServerEnvironment serverEnvironment) async {
  await _initializeStorage();
  await _initializeFirebase(currentPlatform, serverEnvironment);
  _initializeControllers();
}

void _initializeControllers() {
  WordController.getOrPut;
  FlashCardAppController.getOrPut;
}

Future<void> _initializeFirebase(FirebaseOptions currentPlatform, ServerEnvironment serverEnvironment) async {
  FlashCardApiService.init(serverEnvironment);
  await Firebase.initializeApp(name: serverEnvironment.name, options: currentPlatform);
}

Future<void> _initializeStorage() async {
  await Hive.initFlutter();
  await WordStorage.init();
  // await WordStorage.box.erase();
  await MainAppStorage.init();
}

class MyApp extends StatelessWidget {
  final String displayName;

  MyApp({required this.displayName, super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'FlashCard',
      theme: Themes.primary,
      home: HomeScreen(
        title: displayName,
      ),
    );
  }
}
