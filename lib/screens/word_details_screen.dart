import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sound_controller.dart';
import '../controllers/word_controller.dart';
import '../controllers/writing_controller.dart';
import '../models/word.dart';
import '../models/word_attributes.dart';
import '../widgets/flashcard_snackbar.dart';
import '../widgets/native_word_input.dart';
import '../widgets/pronunciation_input.dart';
import '../widgets/translation_input.dart';
import '../widgets/word_attributes_input.dart';

/// Form screen for creating or editing a [Word].
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
            icon: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
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
        child: Form(
          key: _form,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildForm(isUpdating),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isUpdating) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NativeWordInputField(
          controller: _nativeTextController,
          isUpdating: isUpdating,
          showNiqqudCard: _showNiqqudCard,
          onToggleNiqqudCard: _toggleNiqqudCard,
          onNiqqudClosed: () => setState(() => _showNiqqudCard = false),
        ),
        PronunciationInputField(
          controller: _pronunciationTextController,
          hasAudio: _hasAudio,
          audioId: widget.word.audioId,
          onPlay: _playAudio,
          onStartRecording: _startRecording,
          onStopRecording: _stopRecording,
        ),
        TranslationInputField(controller: _translationTextController),
        WordAttributesInput(
          attributes: _attributes,
          onChanged: (value) => setState(() => _attributes = value),
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
        ),
      ],
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

  Future<void> _playAudio() async {
    await SoundController.getOrPut.playAudio(
      widget.word.audioId.isNotEmpty
          ? widget.word.audioId
          : _nativeTextController.text,
    );
  }

  void _startRecording() {
    if (_nativeTextController.text.isEmpty) {
      FlashcardSnackbar.showSnackBar(
        'Please enter a word before recording audio',
      );
      return;
    }
    _tempAudioId = _nativeTextController.text;
    SoundController.getOrPut.startRecordAudio(_tempAudioId);
  }

  void _stopRecording() {
    if (_nativeTextController.text.isEmpty) return;
    SoundController.getOrPut.stopRecordAudio(_tempAudioId);
    setState(() => _hasAudio = true);
  }

  Future<void> _saveWord() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await WordController.instance.saveWord(
      Word(
        id: widget.word.id,
        native: _nativeTextController.text,
        pronunciation: _pronunciationTextController.text,
        translation: _translationTextController.text,
        attributes: _attributes,
        isNew: widget.word.isNew,
        audioId: _hasAudio ? _tempAudioId : '',
      ),
    );
    WritingController.instance.updateCurrentWord(WordController.instance.words);
    setState(() => _isLoading = false);
    Get.back();
  }
}
