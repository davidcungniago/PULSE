import 'package:flutter/material.dart';

abstract final class PulseTypography {
  static const mono =
      TextStyle(fontFamily: 'monospace', fontFamilyFallback: ['Courier New']);
  static const number = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      fontFamily: 'monospace',
      fontFamilyFallback: ['Courier New']);

  static TextTheme textTheme(Color text, Color muted) {
    final heading =
        TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: text);
    final body =
        TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: text);
    final label =
        TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text);
    final secondary =
        TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: muted);
    final caption =
        TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: muted);
    return TextTheme(
      displayLarge: heading,
      displayMedium: heading,
      displaySmall: heading,
      headlineLarge: heading,
      headlineMedium: heading,
      headlineSmall: heading,
      titleLarge: heading,
      titleMedium: body,
      titleSmall: label,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: secondary,
      labelLarge: label,
      labelMedium: secondary,
      labelSmall: caption,
    );
  }
}
