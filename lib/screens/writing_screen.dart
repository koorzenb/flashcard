import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sound_controller.dart';
import '../controllers/writing_controller.dart';
import '../models/word.dart';
import 'word_details_screen.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SoundController.getOrPut;
  }

  @override
  void dispose() {
    SoundController.getOrPut.onClose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GetBuilder<WritingController>(builder: (writingController) {
          if (writingController.attemptsRemaining == 0) {
            _textController.text = writingController.currentWord.native;
          }

          return writingController.currentWord.native.isEmpty
              ? Center(child: Text('No words available'))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Score: ${writingController.score}',
                    ),
                    IconButton(
                      onPressed: () => SoundController.getOrPut.playAudio(writingController.currentWord.id),
                      icon: Icon(Icons.play_arrow),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: writingController.attemptsRemaining < 2 ? writingController.currentWord.native : 'Enter the word',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await writingController.onCheckWord(_textController.text);
                        setState(_textController.clear);
                      },
                      child: const Text('Check Word'),
                    ),
                    SizedBox(height: 20),
                    writingController.resultsIcon ?? Icon(Icons.check, color: Colors.transparent),
                    Text(writingController.resultTranslation),
                  ],
                );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await Get.to(() => WordDetailsScreen(
              title: 'Add Word',
              word: Word(
                native: '',
                pronunciation: '',
                translation: '',
                attributes: '',
                isNew: true,
              ),
            )),
        child: const Icon(Icons.add),
      ),
    );
  }
}
