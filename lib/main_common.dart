import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/flash_card_app_controller.dart';
import 'models/server_environment.dart';
import 'screens/home_screen.dart';
import 'services/flashcard_api_service.dart';
import 'storage/main_app_storage.dart';
import 'storage/word_storage.dart';
import 'styles/themes.dart';

Future<void> commonInit(FirebaseOptions currentPlatform, ServerEnvironment serverEnvironment) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeStorage();
  await _initializeFirebase(currentPlatform, serverEnvironment);
  _initializeControllers();
}

void _initializeControllers() {
  KardsAppController.getOrPut;
}

Future<void> _initializeFirebase(FirebaseOptions currentPlatform, ServerEnvironment serverEnvironment) async {
  KardsApiService.init(serverEnvironment);
  await Firebase.initializeApp(options: currentPlatform);
  FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
}

Future<void> _initializeStorage() async {
  await Hive.initFlutter();
  await WordStorage.init();
  // await WordStorage.box.erase();
  await MainAppStorage.init();
}

class MyApp extends StatelessWidget {
  final String displayName;

  MyApp({required this.displayName, super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        // debugShowCheckedModeBanner: false,
        title: 'Kards',
        theme: Themes.primary,
        home: _signInHandler(context, displayName));
  }

  Widget _signInHandler(BuildContext context, String displayName) {
    final homeScreen = HomeScreen();

    return firebase_auth.FirebaseAuth.instance.currentUser != null
        ? homeScreen
        : SignInScreen(
            // see documentation for more info
            // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/providers/email.md
            // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/README.md

            actions: [
              AuthStateChangeAction<SignedIn>((context, state) async {
                print('Signed in');

                await Get.to(() => homeScreen);
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
                await Get.to(() => homeScreen);
              }),
              AuthStateChangeAction<FetchingProvidersForEmail>((context, state) async {
                print('Fetching providers for email');
              }),
            ],
          );
  }
}
