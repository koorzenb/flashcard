import 'package:flutter/material.dart';

import '../models/word.dart';
import '../widgets/flash_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Word word = Word(hebrew: "דָבָר", pronunciation: 'de-var', translation: 'word');

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
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() {
            word = Word.getWord();
            debugPrint(word.translation);
          }),
          child: FlashCard(word: word),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Theme.of(context).colorScheme.primary,
        hoverColor: Theme.of(context).colorScheme.inversePrimary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
