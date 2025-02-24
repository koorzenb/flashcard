import 'package:flashcard/widgets/record_audio_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final TextEditingController _textController = TextEditingController();
  final FlutterSoundPlayer _playerModule = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _playerModule.closePlayer();
    await _playerModule.openPlayer();
    await _playerModule.setSubscriptionDuration(const Duration(milliseconds: 10));
  }

  @override
  Future<void> dispose() async {
    _textController.dispose();
    await _playerModule.closePlayer();
    super.dispose();
  }

  Future<void> _playAudio() async {
    // Replace with your audio file URL or asset path
    const audioUrl = 'https://www.example.com/audio.mp3';
    await _playerModule.startPlayer(fromURI: audioUrl);
  }

  void _checkWord() {
    final enteredText = _textController.text;
    // Add your logic to check the word here
    print('Entered text: $enteredText');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _playAudio,
              child: const Text('Play Audio'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter the word',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkWord,
              child: const Text('Check Word'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => RecordAudioPage());
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
