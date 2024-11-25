import 'package:flashcard/models/server_environment.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'firebase_options_prod.dart';
import 'main_common.dart';

void main() async {
  try {
    await commonInit(DefaultFirebaseOptions.currentPlatform, ServerEnvironment.prod);
    final displayName = 'FlashCard';

    final configuredApp = AppConfig(
      appDisplayName: displayName,
      appInternalId: 1,
      child: MyApp(
        displayName: displayName,
      ),
    );

    runApp(configuredApp);
  } catch (e) {
    debugPrint('prod::exception - $e');
  }
}
