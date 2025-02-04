import 'package:flutter/material.dart';

class Themes {
  static final primary = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue.shade300),
    textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontFamily: 'Segeo UI',
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineLarge: TextStyle(
          fontSize: 48,
          color: Colors.black,
          fontFamily: 'Noto Sans Hebrew',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontFamily: 'Segeo UI',
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontFamily: 'Segeo UI',
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontFamily: 'Segeo UI',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontFamily: 'Segeo UI',
        )),
    useMaterial3: true,
  );
}
