import 'package:get/get.dart';

import '../storage/main_app_storage.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/welcome_message.dart';

class KardsAppController extends GetxController {
  static KardsAppController get getOrPut {
    try {
      return Get.find<KardsAppController>();
    } catch (e) {
      return Get.put(KardsAppController._());
    }
  }

  KardsAppController._() {}

  Future<void> showWelcomeScreen() async {
    if (!MainAppStorage.box.displayedWelcomeScreen) {
      await CustomDialog.showWelcomeMessage(content: WelcomeMessageContent());
      MainAppStorage.box.displayedWelcomeScreen = true;
      update();
    }
  }
}
