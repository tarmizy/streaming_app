import 'package:flutter/material.dart';

class AppTheme {
  // Warna biru pink gradient
  static const Color primaryColor = Color(0xFF6B5CE7); // Purple blue
  static const Color secondaryColor = Color(0xFF8B7CF7); // Light purple
  static const Color accentColor = Color(0xFFE966A0); // Pink
  static const Color pinkLight = Color(0xFFF49AC1); // Light pink

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: accentColor,
      tertiary: pinkLight,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: Colors.white24,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12);
        }
        return const TextStyle(color: Colors.white70, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.white);
        }
        return const IconThemeData(color: Colors.white70);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      thumbColor: accentColor,
      inactiveTrackColor: pinkLight.withOpacity(0.3),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(pinkLight.withOpacity(0.15)),
    ),
    chipTheme: ChipThemeData(
      selectedColor: primaryColor.withOpacity(0.2),
      checkmarkColor: primaryColor,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: secondaryColor,
      secondary: accentColor,
      tertiary: pinkLight,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.grey[900],
      foregroundColor: secondaryColor,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: secondaryColor.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              color: secondaryColor, fontWeight: FontWeight.w600, fontSize: 12);
        }
        return TextStyle(color: Colors.grey[400], fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: secondaryColor);
        }
        return IconThemeData(color: Colors.grey[400]);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: secondaryColor,
      thumbColor: accentColor,
      inactiveTrackColor: Colors.grey[700],
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: secondaryColor,
    ),
  );
}
