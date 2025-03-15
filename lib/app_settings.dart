import 'package:get/get.dart';

import 'controllers/word_controller.dart';
import 'logic/word_logic.dart';
import 'services/flashcard_auth_service.dart';
import 'storage/word_storage.dart';

void clearAppData() {
  WordStorage.disposeBox();
  WordLogic.dispose();
  Get.delete<WordController>();
  Get.until((route) => route.isFirst);
  Get.to(FlashcardAuthService.signIn);
}
