import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FlashcardSnackbar {
  static void showSnackBar(String message, [int durationMs = 2000]) => ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(milliseconds: durationMs),
        ),
      );
}
