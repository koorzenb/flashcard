import 'package:flutter/material.dart';

/// Shared, stateless building block for the inputs on the word-details form.
///
/// Factors out the common [TextFormField] decoration (leading icon, hint/label
/// text, optional fill + enabled state and a trailing [suffixIcon]) so each
/// concrete input only declares what differs. This widget is presentation-only:
/// all behaviour that depends on `WordDetailsScreen` state is passed in.
class FlashcardInputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final String labelText;
  final String? Function(String?)? validator;
  final bool filled;
  final Color? fillColor;
  final bool enabled;
  final TextStyle? style;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const FlashcardInputField({
    required this.controller,
    required this.icon,
    required this.hintText,
    required this.labelText,
    this.validator,
    this.filled = false,
    this.fillColor,
    this.enabled = true,
    this.style,
    this.suffixIcon,
    this.keyboardType = TextInputType.name,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        icon: Icon(icon),
        hintText: hintText,
        labelText: labelText,
        filled: filled,
        fillColor: fillColor,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      enabled: enabled,
      style: style,
    );
  }
}
