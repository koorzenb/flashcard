import '../models/word_attributes.dart';

import '../widgets/flashcard_snackbar.dart';
import '../widgets/niqqud_reference_card.dart';
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
  bool _showNiqqudCard = false;
  String _nativeTextAtCardOpen = '';
  late final String _tempAudioId;
  late WordAttributes _attributes;

  @override
  void initState() {
    SoundController.getOrPut;
    _attributes = widget.word.attributes;
    _nativeTextController.text = widget.word.native;
    _pronunciationTextController.text = widget.word.pronunciation;
    _translationTextController.text = widget.word.translation;
    _nativeTextController.addListener(_handleNativeTextChange);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _nativeTextController.removeListener(_handleNativeTextChange);
    _nativeTextController.dispose();
    _pronunciationTextController.dispose();
    _translationTextController.dispose();
    SoundController.getOrPut.onClose();
    Get.delete<SoundController>();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = !widget.word.isNew;
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
                          filled: isUpdating,
                          fillColor: isUpdating ? Colors.grey[300] : null,
                          suffixIcon: IconButton(
                            tooltip: 'Show niqqud reference',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.keyboard_outlined, size: 21),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.6),
                            onPressed: _toggleNiqqudCard,
                          ),
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (String? _) {
                          return _nativeTextController.text.trim().isEmpty
                              ? 'Please enter valid word'
                              : null;
                        },
                        enabled: !isUpdating,
                        style: TextStyle(
                          color: isUpdating ? Colors.grey : Colors.black,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _showNiqqudCard
                            ? NiqqudReferenceCard(
                                key: const ValueKey('niqqudCard'),
                                onClose: () =>
                                    setState(() => _showNiqqudCard = false),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
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
                      const SizedBox(height: 24),
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

  void _handleNativeTextChange() {
    if (!_showNiqqudCard) return;
    if (_nativeTextController.text != _nativeTextAtCardOpen) {
      setState(() => _showNiqqudCard = false);
    }
  }

  void _toggleNiqqudCard() {
    setState(() {
      if (_showNiqqudCard) {
        _showNiqqudCard = false;
      } else {
        _nativeTextAtCardOpen = _nativeTextController.text;
        _showNiqqudCard = true;
      }
    });
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
