import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:get/get.dart';

import '../app_settings.dart';
import '../controllers/word_controller.dart';
import '../screens/home_screen.dart';
import '../storage/word_storage.dart';
import '../utilities/utilities.dart';

class FlashcardAuthService {
  static String _userId = '';

  static String get userId => _userId;

  static SignInScreen signIn() {
    return SignInScreen(
      // see documentation for more info
      // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/providers/email.md
      // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/README.md

      actions: [
        AuthStateChangeAction<SignedIn>((context, state) async {
          print('Signed in');
          await _init();
          await Get.to(() => HomeScreen());
        }),
        AuthStateChangeAction<Uninitialized>((context, state) async {
          print('Uninitialized');
        }),
        AuthStateChangeAction<AuthFailed>((context, state) async {
          print('Auth failed');
        }),
        AuthStateChangeAction<AuthState>((context, state) async {
          print('Auth state');
        }),
        AuthStateChangeAction<SigningIn>((context, state) async {
          print('Signing in');
        }),
        AuthStateChangeAction<CredentialReceived>((context, state) async {
          print('Credential received');
        }),
        AuthStateChangeAction<CredentialLinked>((context, state) async {
          print('Credential linked');
        }),
        AuthStateChangeAction<UserCreated>((context, state) async {
          print('User created');
          await _init();
          await Get.to(() => HomeScreen());
        }),
        AuthStateChangeAction<FetchingProvidersForEmail>((context, state) async {
          print('Fetching providers for email');
        }),
      ],
    );
  }

  static void signOut() {
    Get.until((route) => route.isFirst);
    Get.to(() => signIn());
    FirebaseAuth.instance.signOut();
    _userId = '';
    clearAppData();
    print('Signed out');
  }

  static Future<void> _init() async {
    // TODO: move this to authController. Should not handle this here
    // AFter auth, then perform functions and update controller
    _userId = FirebaseAuth.instance.currentUser!.uid;
    await WordStorage.init(extractUsername(FirebaseAuth.instance.currentUser!.email!));
    WordController.create();
  }
}
