import 'package:flutter/material.dart';

import 'app_config.dart';
import 'firebase_options_dev.dart';
import 'main_common.dart';
import 'models/server_environment.dart';

void main() async {
  try {
    await commonInit(DefaultFirebaseOptions.currentPlatform, ServerEnvironment.dev);
    final displayName = 'FlashDev';

    final configuredApp = AppConfig(
      appDisplayName: displayName,
      appInternalId: 2,
      child: MyApp(
        displayName: displayName,
      ),
    );

    runApp(configuredApp);
  } catch (e) {
    debugPrint('dev::exception - $e');
  }
}
