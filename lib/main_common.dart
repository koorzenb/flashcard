import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/app_controller.dart';
import 'models/server_environment.dart';
import 'storage/auth_storage.dart';
import 'storage/main_app_storage.dart';
import 'styles/themes.dart';

Future<void> commonInit(
  FirebaseOptions currentPlatform,
  ServerEnvironment serverEnvironment,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeStorage();
  await _initializeFirebase(currentPlatform, serverEnvironment);
  await AppController.initialize();
}

Future<void> _initializeFirebase(
  FirebaseOptions currentPlatform,
  ServerEnvironment serverEnvironment,
) async {
  await Firebase.initializeApp(options: currentPlatform);
  FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
}

Future<void> _initializeStorage() async {
  await Hive.initFlutter();
  await MainAppStorage.init();
  await AuthStorage.init();
}

class MyApp extends StatelessWidget {
  final String displayName;

  MyApp({required this.displayName, super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'FlashCard',
      theme: Themes.primary,
      home: AppController.instance.home,
    );
  }
}
