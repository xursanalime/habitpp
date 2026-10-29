import 'package:flutter/material.dart';

/// Design tokens: near-black base, one hot red→orange accent for pressure.
abstract final class Palette {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF13131B);
  static const surface2 = Color(0xFF1B1B26);
  static const border = Color(0xFF262635);
  static const text = Color(0xFFEDEDF3);
  static const muted = Color(0xFF8A8AA3);
  static const accent = Color(0xFFFF4D6D);
  static const accent2 = Color(0xFFFF8A4C);
  static const success = Color(0xFF22C55E);
  static const minimum = Color(0xFF84CC16);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  static const accentGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Icon and color per task id.
const taskStyle = <String, (IconData, Color)>{
  'reading': (Icons.menu_book_rounded, Color(0xFF4F8CFF)),
  'listening': (Icons.headphones_rounded, Color(0xFF22D3EE)),
  'mock': (Icons.quiz_rounded, Color(0xFFF59E0B)),
  'writing': (Icons.edit_note_rounded, Color(0xFFA78BFA)),
  'youtube': (Icons.smart_display_rounded, Color(0xFFF43F5E)),
  'speaking': (Icons.record_voice_over_rounded, Color(0xFF34D399)),
  'vocab_new': (Icons.auto_awesome_rounded, Color(0xFFFBBF24)),
  'vocab_review': (Icons.replay_rounded, Color(0xFF60A5FA)),
};

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Palette.accent, brightness: Brightness.dark).copyWith(
    primary: Palette.accent,
    secondary: Palette.accent2,
    surface: Palette.surface,
    error: Palette.danger,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.bg,
    textTheme: base.textTheme.apply(bodyColor: Palette.text, displayColor: Palette.text),
    dividerColor: Palette.border,
    dialogTheme: const DialogThemeData(
      backgroundColor: Palette.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.accent, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
