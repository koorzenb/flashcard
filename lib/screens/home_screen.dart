import 'package:flashcard/controllers/flash_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/flash_card.dart';
import '../widgets/main_drawer.dart';
import 'update_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final flashCardController = FlashCardController.getOrPut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const MainDrawer(),
      body: const Center(
        child: FlashCard(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await Get.to(() => const UpdateScreen()), // TODO: rather use Get.dialog with background blur
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
