import 'package:flutter/material.dart';

const appBackground = Color(0xFF101311);
const appSurface = Color(0xFF191E1B);
const appSurfaceRaised = Color(0xFF222925);
const appAccent = Color(0xFFC6F36A);
const appMuted = Color(0xFF9AA69E);
const historyPageSize = 14;

DateTime recentHistoryCutoff() =>
    DateTime.now().subtract(const Duration(days: 14));

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: appBackground,
  colorScheme: const ColorScheme.dark(
    primary: appAccent,
    onPrimary: appBackground,
    surface: appSurface,
    onSurface: Colors.white,
    secondary: appAccent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: appSurfaceRaised,
    hintStyle: const TextStyle(color: appMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: appAccent),
    ),
  ),
);
