import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import '../app_settings.dart';
import '../logic/migrations/word_migration_bootstrap.dart';
import 'sound_controller.dart';
import 'word_controller.dart';
import 'writing_controller.dart';
import '../screens/home_screen.dart';
import '../services/flashcard_auth_service.dart';
import '../storage/auth_storage.dart';
import '../storage/word_storage.dart';
import '../utilities/utilities.dart';
import 'package:flutter/widgets.dart';

import '../storage/main_app_storage.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/welcome_message.dart';

class AppController {
  // TODO: rename this file

  // Singleton instance
  static AppController? _instance;
  static AppController get instance {
    if (_instance == null) {
      throw StateError(
          'AppController not initialized. Call AppController.initialize() first.');
    }
    return _instance!;
  }

  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitializing = false;

  AppController._internal();

  void dispose() {
    _authSubscription?.cancel();
  }

  static Future<void> initialize() async {
    if (_instance != null) {
      return; // Already initialized
    }

    final controller = AppController._internal();
    controller._currentUser = FirebaseAuth.instance.currentUser;

    // Listen to auth state changes to handle sign-in and sign-out events
    controller._authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      controller._currentUser = user;
      if (user != null &&
          !WordStorage.isInitialized &&
          !controller._isInitializing) {
        // User signed in and app data not initialized yet. This is safety check to ensure that we don't initialize app data multiple times if the auth state changes while the app is running.
        // Note: _init is async but we don't await here since this is a stream listener
        // The _isInitializing flag prevents concurrent initialization attempts
        controller._init(user);
      } else if (user == null && WordStorage.isInitialized) {
        // User signed out, clean up app data
        clearAppData();
      }
    });

    // If user is already logged in, initialize app data before making the instance available
    if (controller._currentUser != null) {
      await controller._init(controller._currentUser!);
    }

    // Instance is now fully initialized and ready to use
    _instance = controller;
  }

  Widget get home {
    if (FirebaseAuth.instance.currentUser == null) {
      return FlashcardAuthService.getOrPut.signIn();
    } else {
      return HomeScreen();
    }
  }

  Future<void> showWelcomeScreen() async {
    await CustomDialog.showWelcomeMessage(content: WelcomeMessageContent());
    MainAppStorage.box.displayedWelcomeScreen = true;
  }

  Future<void> _init(User user) async {
    if (_isInitializing) {
      return; // Prevent concurrent initialization
    }

    _isInitializing = true;
    try {
      // Use persisted username if available, otherwise extract from email
      String username = AuthStorage.box.username;
      if (username.isEmpty && user.email != null) {
        username = extractUsername(user.email!);
        AuthStorage.box.username = username;
      }

      await WordStorage.init(username.isEmpty ? user.uid : username);

      // Run the data migrations for this user's word box BEFORE the word
      // list is read into the controller. Otherwise the controller would read
      // un-migrated data into `_words` and write it back, re-contaminating
      // the box.
      await WordMigrationBootstrap.run();

      WordController.create();
      WritingController.create();
      await SoundController.init();
    } finally {
      _isInitializing = false;
    }
  }
}
