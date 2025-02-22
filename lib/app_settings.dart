import 'package:flashcard/controllers/word_controller.dart';
import 'package:get/get.dart';

import 'logic/word_logic.dart';
import 'storage/word_storage.dart';

void clearAppData() {
  WordStorage.disposeBox();
  WordLogic.dispose();
  Get.delete<WordController>();
}
