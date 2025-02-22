import 'package:get/get.dart';

class FlashcardAuthController extends GetxController {
  static FlashcardAuthController get getOrPut {
    try {
      return Get.find<FlashcardAuthController>();
    } catch (e) {
      return Get.put(FlashcardAuthController._());
    }
  }

  FlashcardAuthController._();
}
