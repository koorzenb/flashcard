import 'package:flutter/material.dart';

import 'app_config.dart';
import 'firebase_options_dev.dart';
import 'main_common.dart';

void main() async {
  try {
    await commonInit(DefaultFirebaseOptions.currentPlatform);

    final configuredApp = AppConfig(
      appDisplayName: 'FlashDev',
      appInternalId: 2,
      child: MyApp(),
    );

    runApp(configuredApp);
  } catch (e) {
    debugPrint('dev::exception - $e');
  }

  runApp(const MyApp());
}
