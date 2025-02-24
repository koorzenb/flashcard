import 'package:flutter/material.dart';

class RecordAudioPage extends StatefulWidget {
  @override
  _RecordAudioPageState createState() => _RecordAudioPageState();
}

class _RecordAudioPageState extends State<RecordAudioPage> {
  // FlutterSoundRecorder _recorder;
  // bool _isRecording = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _recorder = FlutterSoundRecorder();
  //   _initRecorder();
  // }

  // Future<void> _initRecorder() async {
  //   await _recorder.openAudioSession();
  //   var status = await Permission.microphone.request();
  //   if (status != PermissionStatus.granted) {
  //     throw RecordingPermissionException('Microphone permission not granted');
  //   }
  // }

  // Future<void> _startRecording() async {
  //   setState(() {
  //     _isRecording = true;
  //   });
  //   await _recorder.startRecorder(
  //     toFile: 'audio_clip.aac',
  //   );

  //   // Monitor audio input for silence
  //   _recorder.onProgress.listen((event) {
  //     if (_isSilent(event)) {
  //       _stopRecording();
  //     }
  //   });
  // }

  // Future<void> _stopRecording() async {
  //   if (_isRecording) {
  //     await _recorder.stopRecorder();
  //     setState(() {
  //       _isRecording = false;
  //     });
  //   }
  // }

  // bool _isSilent(RecordingDisposition event) {
  //   // Check if the audio input is silent for more than 1 second
  //   return event.decibels < -50;
  // }

  // @override
  // void dispose() {
  //   _recorder.closeAudioSession();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Audio'),
      ),
      //     body: Center(
      //       child: _isRecording
      //           ? Text('Recording...')
      //           : ElevatedButton(
      //               onPressed: _startRecording,
      //               child: Text('Start Recording'),
      //             ),
      // ),
    );
  }
}
