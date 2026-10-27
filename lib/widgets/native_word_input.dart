import 'package:flutter/material.dart';

import 'flashcard_input_field.dart';
import 'niqqud_reference_card.dart';

/// Native-word input: a [FlashcardInputField] plus an inline niqqud reference.
///
/// Tapping the keyboard [IconButton] opens the reference card. The card lives
/// here (below the field) and is dismissed by the parent when the field text
/// changes (via [onNiqqudClosed]) or by the card's own close button. The field
/// itself stays interactive, so the parent's text-change listener can fire and
/// auto-dismiss the card the moment the user starts typing.
class NativeWordInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isUpdating;
  final bool showNiqqudCard;
  final VoidCallback onToggleNiqqudCard;
  final VoidCallback onNiqqudClosed;

  const NativeWordInputField({
    required this.controller,
    required this.isUpdating,
    required this.showNiqqudCard,
    required this.onToggleNiqqudCard,
    required this.onNiqqudClosed,
    super.key,
  });

  String? _onValidate(String? _) =>
      controller.text.trim().isEmpty ? 'Please enter valid word' : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlashcardInputField(
          controller: controller,
          icon: Icons.translate,
          hintText: 'What is the native word?',
          labelText: 'Native word',
          validator: _onValidate,
          filled: isUpdating,
          fillColor: isUpdating ? Colors.grey[300] : null,
          enabled: !isUpdating,
          style: TextStyle(color: isUpdating ? Colors.grey : Colors.black),
          suffixIcon: IconButton(
            tooltip: 'Show niqqud reference',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.keyboard_outlined, size: 21),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            onPressed: onToggleNiqqudCard,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child:
              showNiqqudCard
                  ? NiqqudReferenceCard(
                    key: const ValueKey('niqqudCard'),
                    onClose: onNiqqudClosed,
                  )
                  : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}
