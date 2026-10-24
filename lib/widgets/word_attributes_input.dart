import 'package:flutter/material.dart';

import '../models/gender.dart';
import '../models/word_attributes.dart';

/// Input control for a word's grammatical attributes.
///
/// Presents gender and number (singular/plural) as two icon-led
/// [SegmentedButton]s. Defaults come from [WordAttributes.blank]
/// (neutral + singular) when the parent seeds it with a blank value.
class WordAttributesInput extends StatelessWidget {
  final WordAttributes attributes;
  final ValueChanged<WordAttributes> onChanged;

  const WordAttributesInput({
    required this.attributes,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Left-justify the controls and inset them by the width of the leading
    // icon used in the surrounding TextFormFields. For a non-filled
    // TextFormField, InputDecorator places the icon at the field's origin and
    // lays the entered text out starting at the icon's width, so matching
    // that offset keeps these controls visually under the input text rather
    // than flush against the screen edge.
    final double leadingIconSize = IconTheme.of(context).size ?? 24.0;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 16, start: leadingIconSize),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<Gender>(
            segments: [
              for (final gender in Gender.values)
                ButtonSegment(
                  value: gender,
                  icon: Text(
                    gender.symbol,
                    style: const TextStyle(fontSize: 16),
                  ),
                  label: Text(gender.label),
                ),
            ],
            selected: {attributes.gender},
            onSelectionChanged: (selection) => onChanged(WordAttributes(
              gender: selection.first,
              isPlural: attributes.isPlural,
            )),
          ),
          SegmentedButton<bool>(
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
          ),
        ],
      ),
    );
  }
}
