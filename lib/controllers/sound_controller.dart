import 'dart:io';

import 'package:flashcard/widgets/flashcard_snackbar.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SoundController extends GetxController {
  late FlutterSoundRecorder _recorder;
  late FlutterSoundPlayer _player;
  static late String _directoryPath;

  static SoundController get getOrPut {
    try {
      return Get.find<SoundController>();
    } catch (e) {
      return Get.put(SoundController._());
    }
  }

  static Future<void> init() async {
    final dirPath = (await getApplicationDocumentsDirectory()).path;
    _directoryPath = path.join(dirPath, 'audio-clips');
  }

  SoundController._() {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
  }

  Future<void> _init() async {
    await _recorder.openRecorder();
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted'); // TODO: Handle this error
    }

    await _player.openPlayer();
  }

  @override
  void onClose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.onClose();
  }

  Future<void> startRecordAudio(String id) async {
    final codec = Codec.aacADTS;

    if (!await _recorder.isEncoderSupported(codec)) {
      print('codec not supported');
      return;
    }

    try {
      print('Start recording');

      // to see files on device:
      // - adb devices
      // - adb shell
      // - run-as com.example.flashcard
      // - cd app_flutter
      // - ls -lh

      await _recorder.startRecorder(
        toFile: path.join(_directoryPath, '$id.aac'),
        codec: codec,
        bitRate: 16000, // Low quality bitrate
        sampleRate: 16000, // Low quality sample rate
      );
    } catch (e) {
      print('some error occured: $e');
      return;
    }
  }

  Future<void> stopRecordAudio(String id) async {
    await _recorder.stopRecorder();
    FlashcardSnackbar.showSnackBar('Finished recording');
    await Future.delayed(const Duration(seconds: 1));
    // TODO: update icon to play icon

    await playAudio(id);
    // TODO: dispose player
  }

  Future<void> playAudio(String id) async {
    // check if file exists
    if (!await File(path.join(_directoryPath, '$id.aac')).exists()) {
      FlashcardSnackbar.showSnackBar('No audio record found');
      return;
    }

    // Implement SQLLite for relationship between word and audio

    await _player.startPlayer(
      fromURI: path.join(_directoryPath, '$id.aac'),
      codec: Codec.aacADTS,
    );
    print('Playing sound');
  }
}
