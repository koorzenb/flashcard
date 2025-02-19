import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FlashcardSnackbar {
  static void showSnackBar(String message) => ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
}
