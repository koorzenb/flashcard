import 'package:flashcard/controllers/flash_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/word.dart';

class UpdateScreen extends StatefulWidget {
  final Word? word;

  const UpdateScreen({this.word, super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final _form = GlobalKey<FormState>();
  final _hebrewTextController = TextEditingController();
  final _pronunciationTextController = TextEditingController();
  final _translationTextController = TextEditingController();
  final _attributesTextController = TextEditingController();

  bool _isLoading = false;
  Word? originalWord;

  @override
  void initState() {
    if (widget.word != null) {
      originalWord = widget.word;
      setState(() {
        _hebrewTextController.text = widget.word!.hebrew;
        _pronunciationTextController.text = widget.word!.pronunciation;
        _translationTextController.text = widget.word!.translation;
        _attributesTextController.text = widget.word!.attributes;
      });
    }
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

  _saveWord() {
    if (!_form.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final word = Word(
      hebrew: _hebrewTextController.text,
      pronunciation: _pronunciationTextController.text,
      translation: _translationTextController.text,
      attributes: _attributesTextController.text,
    );

    final flashCardController = FlashCardController.getOrPut;

    if (originalWord == null) {
      flashCardController.addWord(word);
    } else {
      flashCardController.updateWord(originalWord!, word);
    }

    setState(() {
      _isLoading = false;
    });

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.word != null)
            IconButton(
              onPressed: () => FlashCardController.getOrPut.deleteWord(widget.word!),
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            )
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Flashy', //TODO: import from Main
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
                child: GetBuilder<FlashCardController>(builder: (flashCardController) {
                  return Column(
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
                          return _hebrewTextController.text.trim().isEmpty ? 'Please enter valid word' : null;
                        },
                      ),
                      TextFormField(
                        controller: _pronunciationTextController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.record_voice_over),
                          hintText: 'How would this word be pronounced phonetically?',
                          labelText: 'Pronunciation',
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (String? _) {
                          return _pronunciationTextController.text.trim().isEmpty ? 'Please enter valid pronunciation' : null;
                        },
                      ),
                      TextFormField(
                        controller: _translationTextController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.abc_rounded),
                          hintText: 'What does this word translate to in English?',
                          labelText: 'English',
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (String? _) {
                          return _hebrewTextController.text.trim().isEmpty ? 'Please enter valid word' : null;
                        },
                      ),
                      TextFormField(
                        controller: _attributesTextController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.checklist_rounded),
                          hintText: 'What type of word is this? (hint: gender, grammatical type, etc.)',
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
}
