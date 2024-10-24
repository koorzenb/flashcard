import 'package:flutter/material.dart';

import 'app_config.dart';
import 'firebase_options_prod.dart';
import 'main_common.dart';

void main() async {
  try {
    await commonInit(DefaultFirebaseOptions.currentPlatform);

    final configuredApp = AppConfig(
      appDisplayName: 'FlashCard',
      appInternalId: 1,
      child: MyApp(),
    );

    runApp(configuredApp);
  } catch (e) {
    debugPrint('main::exception - $e');
  }

  runApp(const MyApp());
}
