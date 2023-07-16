import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'word_storage.dart';
import 'screens/home_screen.dart';

void main() {
  WordStorage.init();
  runApp(const Flashy());
}

class Flashy extends StatelessWidget {
  const Flashy({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
