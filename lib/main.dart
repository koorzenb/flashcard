import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/home_screen.dart';
import 'word_storage.dart';

void main() {
  WordStorage.init();
  // WordStorage.box.erase();
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
