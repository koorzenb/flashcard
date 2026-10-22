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
    return Wrap(
      spacing: 16,
      runSpacing: 8,
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
    );
  }
}
