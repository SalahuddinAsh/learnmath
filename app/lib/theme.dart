import 'package:flutter/material.dart';

/// Colors lifted from ../style.css so the native app reads as the same product.
class AppColors {
  AppColors._();

  static const purple = Color(0xFF7C5CFF);
  static const purpleLight = Color(0xFFA18CFF);
  static const sky = Color(0xFF5EC8F8);

  static const bgGradient = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [purpleLight, purple, sky],
    stops: [0.0, 0.45, 1.0],
  );

  static const text = Color(0xFF2D2A45);
  static const textMid = Color(0xFF4A4570);
  static const heading = Color(0xFF6B6790);
  static const muted = Color(0xFF9A95C0);
  static const faint = Color(0xFFC5C0E8);

  static const chipBg = Color(0xFFF9F8FF);
  static const chipBorder = Color(0xFFE3DEFC);
  static const softBg = Color(0xFFF6F4FF);
  static const secondaryBg = Color(0xFFF0EDFF);
  static const answerBg = Color(0xFFF4F2FF);
  static const answerBorder = Color(0xFFC9BEFC);

  static const good = Color(0xFF3DDC84);
  static const goodDark = Color(0xFF1DA75C);
  static const goodBg = Color(0xFFE2FBE9);
  static const warn = Color(0xFFFFC542);
  static const bad = Color(0xFFFF5C72);
  static const badDark = Color(0xFFE0284A);
  static const badBg = Color(0xFFFFE6EA);
  static const missedBg = Color(0xFFFFF7F8);
  static const missedBorder = Color(0xFFFFDBE1);
  static const record = Color(0xFFE07B1D);
  static const backKey = Color(0xFFFFE9D6);

  static const bigBtnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9F43), Color(0xFFFF6B81)],
  );

  static const shadow = Color(0x40281464); // rgba(40, 20, 100, .25)
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.purple,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    primary: AppColors.purple,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
);
