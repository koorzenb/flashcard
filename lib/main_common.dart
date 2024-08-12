import 'package:firebase_core/firebase_core.dart';
import 'package:flashcard/controllers/word_controller.dart';
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
  WordController.getOrPut;
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
    // TODO:  use TutorialCoachMark to show tutorial
    return GetMaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'FlashCard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue.shade300),
        textTheme: TextTheme(
            titleLarge: TextStyle(
              color: Colors.white,
              fontFamily: 'Segeo UI',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            headlineLarge: TextStyle(
              fontSize: 48,
              color: Colors.black,
              fontFamily: 'Noto Sans Hebrew',
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontFamily: 'Segeo UI',
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontFamily: 'Segeo UI',
            ),
            bodySmall: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Segeo UI')),
        useMaterial3: true,
      ),
      home: const HomeScreen(
        title: String.fromEnvironment('FLAVOR') == 'dev' ? 'FlashDev' : 'FlashCard',
      ),
    );
  }
}
