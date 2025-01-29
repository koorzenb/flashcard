import 'package:flashcard/app_config.dart';
import 'package:flashcard/firebase_options_prod.dart';
import 'package:flutter/material.dart';

import 'main_common.dart';

void main() async {
  try {
    await commonInit(DefaultFirebaseOptions.currentPlatform);

    final configuredApp = AppConfig(
      appDisplayName: 'Kards',
      appInternalId: 1,
      child: MyApp(),
    );

    runApp(configuredApp);
  } catch (e) {
    debugPrint('main::exception - $e');
  }

  runApp(const MyApp());
}
