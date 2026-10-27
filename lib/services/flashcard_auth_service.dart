import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../screens/home_screen.dart';
import '../storage/auth_storage.dart';
import '../utilities/utilities.dart';

class FlashcardAuthService extends GetxController {
  static FlashcardAuthService get getOrPut {
    try {
      return Get.find<FlashcardAuthService>();
    } catch (e) {
      return Get.put(FlashcardAuthService._());
    }
  }

  FlashcardAuthService._() {
    // Initialize userId from persisted Firebase Auth session
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId.value = currentUser.uid;
    }
  }

  final userId = ''.obs;

  SignInScreen signIn() {
    return SignInScreen(
      // see documentation for more info
      // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/providers/email.md
      // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/README.md
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) async {
          debugPrint('Signed in');
          final currentUser = FirebaseAuth.instance.currentUser!;
          userId.value = currentUser.uid;

          // Save to persistent storage
          AuthStorage.box.userId = currentUser.uid;
          AuthStorage.box.username = extractUsername(currentUser.email!);

          debugPrint('User ID: ${userId.value}');
          await Get.to(() => HomeScreen());
        }),
        AuthStateChangeAction<Uninitialized>((context, state) async {
          debugPrint('Uninitialized');
        }),
        AuthStateChangeAction<AuthFailed>((context, state) async {
          debugPrint('Auth failed');
        }),
        AuthStateChangeAction<AuthState>((context, state) async {
          debugPrint('Auth state');
        }),
        AuthStateChangeAction<SigningIn>((context, state) async {
          debugPrint('Signing in');
        }),
        AuthStateChangeAction<CredentialReceived>((context, state) async {
          debugPrint('Credential received');
        }),
        AuthStateChangeAction<CredentialLinked>((context, state) async {
          debugPrint('Credential linked');
        }),
        AuthStateChangeAction<UserCreated>((context, state) async {
          debugPrint('User created');
          final currentUser = FirebaseAuth.instance.currentUser!;
          userId.value = currentUser.uid;

          // Save to persistent storage
          AuthStorage.box.userId = currentUser.uid;
          AuthStorage.box.username = extractUsername(currentUser.email!);

          await Get.to(() => HomeScreen());
        }),
      ],
    );
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
    userId.value = '';
    debugPrint('Signed out');
  }
}
