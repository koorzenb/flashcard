import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/word_controller.dart';
import '../models/word.dart';

class WordDetailsScreen extends StatefulWidget {
  final Word word;
  final String title;

  const WordDetailsScreen({required this.title, required this.word, super.key});

  @override
  State<WordDetailsScreen> createState() => _WordDetailsScreenState();
}

class _WordDetailsScreenState extends State<WordDetailsScreen> {
  final _form = GlobalKey<FormState>();
  final _hebrewTextController = TextEditingController();
  final _pronunciationTextController = TextEditingController();
  final _translationTextController = TextEditingController();
  final _attributesTextController = TextEditingController();

  bool _isLoading = false;
  Word? originalWord;

  @override
  void initState() {
    originalWord = widget.word;
    setState(() {
      _hebrewTextController.text = widget.word.hebrew;
      _pronunciationTextController.text = widget.word.pronunciation;
      _translationTextController.text = widget.word.translation;
      _attributesTextController.text = widget.word.attributes;
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _hebrewTextController.dispose();
    _pronunciationTextController.dispose();
    _translationTextController.dispose();
    _attributesTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => WordController.getOrPut.deleteWord(widget.word),
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Form(
            key: _form,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child:
                    GetBuilder<WordController>(builder: (flashCardController) {
                  return _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _hebrewTextController,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.translate),
                                hintText: 'What is the Hebrew word?',
                                labelText: 'Hebrew',
                              ),
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              validator: (String? _) {
                                return _hebrewTextController.text.trim().isEmpty
                                    ? 'Please enter valid word'
                                    : null;
                              },
                            ),
                            TextFormField(
                              controller: _pronunciationTextController,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.record_voice_over),
                                hintText:
                                    'How would this word be pronounced phonetically?',
                                labelText: 'Pronunciation',
                              ),
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              validator: (String? _) {
                                return _pronunciationTextController.text
                                        .trim()
                                        .isEmpty
                                    ? 'Please enter valid pronunciation'
                                    : null;
                              },
                            ),
                            TextFormField(
                              controller: _translationTextController,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.abc_rounded),
                                hintText:
                                    'What does this word translate to in English?',
                                labelText: 'English',
                              ),
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              validator: (String? _) {
                                return _hebrewTextController.text.trim().isEmpty
                                    ? 'Please enter valid word'
                                    : null;
                              },
                            ),
                            TextFormField(
                              controller: _attributesTextController,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.checklist_rounded),
                                hintText:
                                    'What type of word is this? (hint: gender, grammatical type, etc.)',
                                labelText: 'Attributes',
                              ),
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.done,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                    onPressed: _saveWord,
                                    child: const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                }),
              ),
            )),
      ),
    );
  }

  _saveWord() {
    if (!_form.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final word = Word(
      id: widget.word.id,
      hebrew: _hebrewTextController.text,
      pronunciation: _pronunciationTextController.text,
      translation: _translationTextController.text,
      attributes: _attributesTextController.text,
      isNew: false,
    );

    if (widget.word.isNew) {
      WordController.getOrPut.addWord(word);
    } else {
      WordController.getOrPut.updateWord(word);
    }

    setState(() {
      _isLoading = false;
    });

    Get.back();
  }
}
