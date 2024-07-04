import 'package:firebase_core/firebase_core.dart';
import 'package:flashcard/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home_screen.dart';
import 'word_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await WordStorage.init();
  // await WordStorage.box.erase();
  runApp(const Flashy());
}

class Flashy extends StatelessWidget {
  const Flashy({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'Flashy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(
        title: 'Flashy',
      ),
    );
  }
}
