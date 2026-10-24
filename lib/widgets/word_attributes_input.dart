import 'package:flutter/material.dart';

import '../models/gender.dart';
import '../models/word_attributes.dart';

/// Input control for a word's grammatical attributes.
///
/// Presents gender and number (singular/plural) as two icon-led
/// [SegmentedButton]s. Defaults come from [WordAttributes.blank]
/// (neutral + singular) when the parent seeds it with a blank value.
class WordAttributesInput extends StatelessWidget {
  /// The leading icon size applied by the surrounding [TextFormField]s.
  ///
  /// For a non-filled [TextFormField], [InputDecorator] starts the entered
  /// text at the icon's width, so this is also the inset that lines these
  /// controls up with the input text. Falls back to Material's default icon
  /// size when no [IconTheme] is in scope.
  static const double _defaultIconSize = 24.0;

  // Layout values shared with the rest of the details form.
  static const double _sectionTopPadding = 16.0;
  static const double _wrapSpacing = 16.0;
  static const double _wrapRunSpacing = 8.0;
  static const double _genderSymbolFontSize = 16.0;

  final WordAttributes attributes;
  final ValueChanged<WordAttributes> onChanged;

  const WordAttributesInput({
    required this.attributes,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Left-justify the controls and inset them by the leading icon's width so
    // they sit under the TextFormField text instead of the screen edge.
    final double leadingIconSize =
        IconTheme.of(context).size ?? _defaultIconSize;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: _sectionTopPadding,
        start: leadingIconSize,
      ),
      child: Wrap(
        spacing: _wrapSpacing,
        runSpacing: _wrapRunSpacing,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _genderButton(),
          _numberButton(),
        ],
      ),
    );
  }

  /// Gender picker: Masculine, Feminine, Neutral.
  SegmentedButton<Gender> _genderButton() {
    return SegmentedButton<Gender>(
      segments: [
        for (final gender in Gender.values)
          ButtonSegment(
            value: gender,
            icon: Text(
              gender.symbol,
              style: const TextStyle(fontSize: _genderSymbolFontSize),
            ),
            label: Text(gender.label),
          ),
      ],
      selected: {attributes.gender},
      onSelectionChanged: (selection) => onChanged(WordAttributes(
        gender: selection.first,
        isPlural: attributes.isPlural,
      )),
    );
  }

  /// Number picker: Singular, Plural.
  SegmentedButton<bool> _numberButton() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.looks_one),
          label: Text('Singular'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.looks_two),
          label: Text('Plural'),
        ),
      ],
      selected: {attributes.isPlural},
      onSelectionChanged: (selection) => onChanged(WordAttributes(
        gender: attributes.gender,
        isPlural: selection.first,
      )),
    );
  }
}
