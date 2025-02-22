import 'package:get/get.dart';

import '../storage/main_app_storage.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/welcome_message.dart';

class FlashcardAppController extends GetxController {
  static FlashcardAppController get getOrPut {
    try {
      return Get.find<FlashcardAppController>();
    } catch (e) {
      return Get.put(FlashcardAppController._());
    }
  }

  FlashcardAppController._() {}

  Future<void> showWelcomeScreen() async {
    await CustomDialog.showWelcomeMessage(content: WelcomeMessageContent());
    MainAppStorage.box.displayedWelcomeScreen = true;
    update();
  }
}
