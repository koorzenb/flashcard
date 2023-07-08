import '../models/word.dart';
import 'package:flutter/material.dart';

import '../widgets/flash_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Word word = Word(hebrew: "דָבָר", translation: 'word');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() {
            word = Word.getWord();
            print(word.translation);
          }),
          child: FlashCard(word: word),
        ),
      ),
    );
  }
}
