import 'package:flutter/material.dart';

import 'flashcard_input_field.dart';

/// Pronunciation input row: a [FlashcardInputField] for free-form phonetic
/// spelling, with a trailing [AudioInputController].
class PronunciationInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasAudio;
  final String audioId;
  final VoidCallback onPlay;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const PronunciationInputField({
    required this.controller,
    required this.hasAudio,
    required this.audioId,
    required this.onPlay,
    required this.onStartRecording,
    required this.onStopRecording,
    super.key,
  });

  String? _onValidate(String? _) =>
      (controller.text.trim().isEmpty && !hasAudio)
          ? 'Please enter valid pronunciation'
          : null;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FlashcardInputField(
              controller: controller,
              icon: Icons.record_voice_over,
              hintText: 'How would this word be pronounced phonetically?',
              labelText: 'Pronunciation',
              validator: _onValidate,
            ),
          ),
        ),
        AudioInputController(
          hasAudio: hasAudio,
          audioId: audioId,
          onPlay: onPlay,
          onStartRecording: onStartRecording,
          onStopRecording: onStopRecording,
        ),
      ],
    );
  }
}

/// Trailing audio affordance for the pronunciation field.
///
/// Renders a play icon when an audio asset exists or has just been recorded,
/// otherwise a long-press-to-record mic. The record/play behaviour lives in the
/// parent (`WordDetailsScreen`); this widget only wires gestures to the supplied
/// callbacks, so it is reusable and independently testable.
class AudioInputController extends StatelessWidget {
  final bool hasAudio;
  final String audioId;
  final VoidCallback onPlay;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const AudioInputController({
    required this.hasAudio,
    required this.audioId,
    required this.onPlay,
    required this.onStartRecording,
    required this.onStopRecording,
    super.key,
  });

  bool get _hasRecording => audioId.isNotEmpty || hasAudio;

  @override
  Widget build(BuildContext context) {
    if (_hasRecording) {
      return GestureDetector(
        onTap: onPlay,
        child: const Icon(Icons.play_arrow),
      );
    }
    return GestureDetector(
      onLongPressStart: (_) => onStartRecording(),
      onLongPressEnd: (_) => onStopRecording(),
      child: const Icon(Icons.mic),
    );
  }
}
