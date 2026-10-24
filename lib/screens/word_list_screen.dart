import '../widgets/word_list.dart';
import 'package:flutter/material.dart';

class WordListScreen extends StatelessWidget {
  WordListScreen({super.key});

// get controller to correct reflect words - add a test word, delete and check for update

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word List')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: WordList(),
      ),
    );
  }
}
