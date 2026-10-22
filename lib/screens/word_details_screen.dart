import '../models/word_attributes.dart';

import '../widgets/flashcard_snackbar.dart';
import '../widgets/word_attributes_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sound_controller.dart';
import '../controllers/word_controller.dart';
import '../controllers/writing_controller.dart';
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
  bool _isLoading = false;
  bool _hasAudio = false;
  late final String _tempAudioId;
  late WordAttributes _attributes;

  @override
  void initState() {
    SoundController.getOrPut;
    _attributes = widget.word.attributes;
    _nativeTextController.text = widget.word.native;
    _pronunciationTextController.text = widget.word.pronunciation;
    _translationTextController.text = widget.word.translation;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _nativeTextController.dispose();
    _pronunciationTextController.dispose();
    _translationTextController.dispose();
    SoundController.getOrPut.onClose();
    Get.delete<SoundController>();
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
                          fillColor: _nativeTextController.text.isNotEmpty
                              ? Colors.grey[300]
                              : null,
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (String? _) {
                          return _nativeTextController.text.trim().isEmpty
                              ? 'Please enter valid word'
                              : null;
                        },
                        enabled: _nativeTextController.text.isEmpty,
                        style: TextStyle(
                          color: _nativeTextController.text.isNotEmpty
                              ? Colors.grey
                              : Colors.black,
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
                                  hintText:
                                      'How would this word be pronounced phonetically?',
                                  labelText: 'Pronunciation',
                                ),
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                validator: (String? _) {
                                  return _pronunciationTextController.text
                                              .trim()
                                              .isEmpty &&
                                          _hasAudio == false
                                      ? 'Please enter valid pronunciation'
                                      : null;
                                },
                              ),
                            ),
                          ),
                          widget.word.audioId.isNotEmpty || _hasAudio
                              ? GestureDetector(
                                  onTap: () async {
                                    await SoundController.getOrPut.playAudio(
                                        widget.word.audioId.isNotEmpty
                                            ? widget.word.audioId
                                            : _nativeTextController.text);
                                  },
                                  child: Icon(Icons.play_arrow),
                                )
                              : GestureDetector(
                                  onLongPressStart: (_) {
                                    if (_nativeTextController.text.isEmpty) {
                                      FlashcardSnackbar.showSnackBar(
                                          'Please enter a word before recording audio');
                                      return;
                                    }
                                    _tempAudioId = _nativeTextController.text;
                                    SoundController.getOrPut
                                        .startRecordAudio(_tempAudioId);
                                  },
                                  onLongPressEnd: (_) {
                                    if (_nativeTextController.text.isEmpty) {
                                      return;
                                    }
                                    SoundController.getOrPut
                                        .stopRecordAudio(_tempAudioId);
                                    setState(() => _hasAudio = true);
                                  },
                                  child: Icon(Icons.mic),
                                ),
                        ],
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
                          return _nativeTextController.text.trim().isEmpty
                              ? 'Please enter valid word'
                              : null;
                        },
                      ),
                      WordAttributesInput(
                        attributes: _attributes,
                        onChanged: (value) =>
                            setState(() => _attributes = value),
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
      attributes: _attributes,
      isNew: widget.word.isNew,
      audioId: _hasAudio ? _tempAudioId : '',
    ));

    WritingController.instance.updateCurrentWord(WordController.instance.words);

    setState(() {
      _isLoading = false;
    });

    Get.back();
  }
}
