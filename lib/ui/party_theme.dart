import 'package:flutter/material.dart';

abstract final class PartyColors {
  static const background = Color(0xFF171321);
  static const surface = Color(0xFF262033);
  static const outline = Color(0xFF857492);
  static const text = Color(0xFFFBF7FF);
  static const muted = Color(0xFFC6BDD2);
  static const purple = Color(0xFF6842D9);
  static const lime = Color(0xFFD6F76B);
  static const coral = Color(0xFFFFAB91);
}

ThemeData buildPartyTheme() {
  const outline = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
    borderSide: BorderSide(color: PartyColors.outline),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PartyColors.background,
    colorScheme: const ColorScheme.dark(
      primary: PartyColors.lime,
      onPrimary: PartyColors.background,
      secondary: PartyColors.purple,
      onSecondary: PartyColors.text,
      surface: PartyColors.surface,
      onSurface: PartyColors.text,
      onSurfaceVariant: PartyColors.muted,
      outline: PartyColors.outline,
      error: PartyColors.coral,
      onError: PartyColors.background,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w800,
        color: PartyColors.text,
      ),
      bodyLarge: const TextStyle(fontSize: 17, height: 1.45),
      bodyMedium: const TextStyle(fontSize: 16, height: 1.45),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: PartyColors.surface,
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: PartyColors.lime, width: 2),
      ),
      contentPadding: EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 56),
        padding: const EdgeInsets.all(16),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PartyColors.text,
        minimumSize: const Size(56, 56),
        padding: const EdgeInsets.all(16),
        side: const BorderSide(color: PartyColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}
