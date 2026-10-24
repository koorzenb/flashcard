import 'package:flutter/material.dart';

enum Gender {
  male,
  female,
  neutral,
}

extension GenderDisplay on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Masculine';
      case Gender.female:
        return 'Feminine';
      case Gender.neutral:
        return 'Neutral';
    }
  }

  String get symbol {
    switch (this) {
      case Gender.male:
        return '♂';
      case Gender.female:
        return '♀';
      case Gender.neutral:
        return '⚧';
    }
  }

  Color get color {
    switch (this) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      case Gender.neutral:
        return Colors.grey;
    }
  }
}
