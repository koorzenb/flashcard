import 'package:flashcard/app_constants.dart';
import 'package:flashcard/controllers/writing_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sound_controller.dart';
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
  final _nativeTextController = TextEditingController();
  final _pronunciationTextController = TextEditingController();
  final _translationTextController = TextEditingController();
  final _attributesTextController = TextEditingController();
  bool _isLoading = false;
  bool _hasAudio = false;
  String _audioFileName = '';

  @override
  void initState() {
    _audioFileName = widget.word.id.isEmpty ? AppConstants.tempAudioFileName : widget.word.id;
    SoundController.getOrPut;
    setState(() {
      _nativeTextController.text = widget.word.native;
      _pronunciationTextController.text = widget.word.pronunciation;
      _translationTextController.text = widget.word.translation;
      _attributesTextController.text = widget.word.attributes;
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _nativeTextController.dispose();
    _pronunciationTextController.dispose();
    _translationTextController.dispose();
    _attributesTextController.dispose();
    SoundController.getOrPut.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => WordController.instance.deleteWord(widget.word),
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nativeTextController,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.translate),
                          hintText: 'What is the native word?',
                          labelText: 'Native word',
                          filled: _nativeTextController.text.isNotEmpty,
                          fillColor: _nativeTextController.text.isNotEmpty ? Colors.grey[300] : null,
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (String? _) {
                          return _nativeTextController.text.trim().isEmpty ? 'Please enter valid word' : null;
                        },
                        enabled: _nativeTextController.text.isEmpty,
                        style: TextStyle(
                          color: _nativeTextController.text.isNotEmpty ? Colors.grey : Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextFormField(
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
                            ),
                          ),
                          widget.word.id.isEmpty
                              ? GestureDetector(
                                  onLongPressStart: (_) {
                                    SoundController.getOrPut.startRecordAudio(_audioFileName);
                                  },
                                  onLongPressEnd: (_) {
                                    SoundController.getOrPut.stopRecordAudio(_audioFileName);
                                    _hasAudio = true;
                                  },
                                  child: Icon(widget.word.audioId.isEmpty ? Icons.mic : Icons.play_arrow),
                                )
                              : GestureDetector(
                                  onTap: () async {
                                    await SoundController.getOrPut.playAudio(_audioFileName);
                                  },
                                  child: Icon(Icons.play_arrow),
                                ),
                        ],
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
                          return _nativeTextController.text.trim().isEmpty ? 'Please enter valid word' : null;
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
                              onPressed: () async => await _saveWord(),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
          ),
        ),
      )),
    );
  }

  Future<void> _saveWord() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await WordController.instance.saveWord(Word(
      id: widget.word.id,
      native: _nativeTextController.text,
      pronunciation: _pronunciationTextController.text,
      translation: _translationTextController.text,
      attributes: _attributesTextController.text,
      isNew: widget.word.isNew,
      audioId: _hasAudio ? _audioFileName : '',
    ));

    WritingController.instance.updateCurrentWord(WordController.instance.words);

    setState(() {
      _isLoading = false;
    });

    Get.back();
  }
}
