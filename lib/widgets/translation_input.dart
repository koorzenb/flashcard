import 'package:flutter/material.dart';

import 'flashcard_input_field.dart';

/// English translation input.
///
/// Translation is intentionally not validated on its own (matching the
/// original behaviour, where the field was optional); pass a `validator` to
/// require it.
class TranslationInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const TranslationInputField({
    required this.controller,
    this.validator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FlashcardInputField(
      controller: controller,
      icon: Icons.abc_rounded,
      hintText: 'What does this word translate to in English?',
      labelText: 'English',
      validator: validator,
    );
  }
}
