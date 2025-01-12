import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flashcard/controllers/word_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/flash_card_app_controller.dart';
import 'screens/home_screen.dart';
import 'storage/main_app_storage.dart';
import 'storage/word_storage.dart';

Future<void> commonInit(FirebaseOptions currentPlatform) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeStorage();
  await _initializeFirebase(currentPlatform);
  _initializeControllers();
}

void _initializeControllers() {
  WordController.getOrPut;
  FlashCardAppController.getOrPut;
}

Future<void> _initializeFirebase(FirebaseOptions currentPlatform) async {
  await Firebase.initializeApp(options: currentPlatform);
  FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
}
// got this working
//  continue at "Using Screen" at https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/providers/email.md

Future<void> _initializeStorage() async {
  await Hive.initFlutter();
  await WordStorage.init();
  // await WordStorage.box.erase();
  await MainAppStorage.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO:  use TutorialCoachMark to show tutorial
    return GetMaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'FlashCard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue.shade300),
        textTheme: TextTheme(
            titleLarge: TextStyle(
              color: Colors.white,
              fontFamily: 'Segeo UI',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            headlineLarge: TextStyle(
              fontSize: 48,
              color: Colors.black,
              fontFamily: 'Noto Sans Hebrew',
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontFamily: 'Segeo UI',
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontFamily: 'Segeo UI',
            ),
            bodySmall: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Segeo UI')),
        useMaterial3: true,
      ),
      home: SignInScreen(
        actions: [
          AuthStateChangeAction<SignedIn>((context, state) async {
            print(state);
            print(state.user!);
            print(state.user!.emailVerified);
            if (!state.user!.emailVerified) {
              await Get.to(() => const RegisterScreen());
            } else {
              await Get.to(() => const HomeScreen(
                    title: 'FlashCard',
                  ));
            }
          }),
        ],
      ),
      // title: String.fromEnvironment('FLAVOR') == 'dev' ? 'FlashDev' : 'FlashCard',
    );
  }
}
