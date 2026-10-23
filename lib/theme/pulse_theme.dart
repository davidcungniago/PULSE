import 'package:flutter/material.dart';
import '../widgets/status_badge.dart';
import 'pulse_colors.dart';
import 'pulse_dimensions.dart';
import 'pulse_typography.dart';

ThemeData buildPulseTheme(Brightness brightness) {
  final c = PulseColors(brightness);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(PulseDimensions.cardRadius),
    side: BorderSide(color: c.line),
  );
  final buttons = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PulseDimensions.tileRadius),
    )),
  );
  final scheme =
      ColorScheme.fromSeed(seedColor: c.textMuted, brightness: brightness)
          .copyWith(
    primary: c.text,
    onPrimary: c.bg,
    primaryContainer: c.surfaceTrace,
    onPrimaryContainer: c.text,
    secondary: c.textMuted,
    onSecondary: c.bg,
    secondaryContainer: c.surfaceTrace,
    onSecondaryContainer: c.text,
    surface: c.surface,
    onSurface: c.text,
    onSurfaceVariant: c.textMuted,
    surfaceContainerHighest: c.surfaceTrace,
    surfaceContainer: c.surface,
    outline: c.textMuted,
    outlineVariant: c.line,
    error: c.riskText(RiskStatus.critical),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    textTheme: PulseTypography.textTheme(c.text, c.textMuted),
    appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: c.transparent),
    cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        surfaceTintColor: c.transparent,
        shape: shape,
        margin: EdgeInsets.zero),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(style: buttons),
    textButtonTheme: TextButtonThemeData(style: buttons),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttons),
    iconButtonTheme: IconButtonThemeData(style: buttons),
    segmentedButtonTheme: SegmentedButtonThemeData(style: buttons),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.text,
        foregroundColor: c.bg,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: c.transparent,
        elevation: 0,
        constraints: const BoxConstraints(maxWidth: PulseDimensions.maxWidth)),
    dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: c.transparent,
        shape: shape),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceTrace,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.line)),
    ),
  );
}
