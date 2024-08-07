import 'package:firebase_core/firebase_core.dart';
import 'package:flashcard/controllers/flash_card_controller.dart';
import 'package:flashcard/screens/home_screen.dart';
import 'package:flashcard/word_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> commonInit(FirebaseOptions currentPlatform) async {
  await _initializeStorage();
  await _initializeFirebase(currentPlatform);
  _initializeControllers();
}

void _initializeControllers() {
  FlashCardController.getOrPut;
}

Future<void> _initializeFirebase(FirebaseOptions currentPlatform) async {
  await Firebase.initializeApp(name: 'dev', options: currentPlatform);
}

Future<void> _initializeStorage() async {
  await Hive.initFlutter();
  await WordStorage.init();
  // await WordStorage.box.erase();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'FlashCard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(
        title: String.fromEnvironment('FLAVOR') == 'dev' ? 'FlashDev' : 'FlashCard',
      ),
    );
  }
}
