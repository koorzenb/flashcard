import 'package:flutter/material.dart';

import 'app_config.dart';
import 'firebase_options_prod.dart';
import 'main_common.dart';
import 'models/server_environment.dart';

void main() async {
  try {
    await commonInit(
        DefaultFirebaseOptions.currentPlatform, ServerEnvironment.prod);
    final displayName = 'Kards';

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
