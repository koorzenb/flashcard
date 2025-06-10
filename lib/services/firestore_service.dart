import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flashcard/app_constants.dart';
import 'package:flashcard/widgets/flashcard_snackbar.dart';
import 'package:path/path.dart' as path;

class FirestoreService {
  late String _userId;

  FirestoreService(String userId) {
    _userId = userId;
  }

  Future<String?> uploadAudioFile(File file) async {
    try {
      final audioId = path.basename(file.path);
      // Create a path that includes the user ID as a folder
      final storagePath = 'audio/${_userId}/$audioId.${AppConstants.audioFileExtension}';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      print('Uploading to path: $storagePath');

      // Upload the file
      await storageRef.putFile(file);

      // Get and return the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      print('File uploaded successfully. Download URL: $downloadUrl');

      return downloadUrl; // Return the URL so it can be saved with the word
    } catch (e) {
      print('Error uploading file: $e');
      FlashcardSnackbar.showSnackBar('Failed to upload audio file');
      return null;
    }
  }

  Future<void> deleteAudioFile(String audioId) async {
    try {
      // Create a path that includes the user ID as a folder
      final storagePath = 'audio/${_userId}/$audioId.${AppConstants.audioFileExtension}';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Delete the file
      await storageRef.delete();
      print('File deleted successfully');
    } catch (e) {
      print('Error deleting file: $e');
      FlashcardSnackbar.showSnackBar('Failed to delete audio file');
    }
  }
}
