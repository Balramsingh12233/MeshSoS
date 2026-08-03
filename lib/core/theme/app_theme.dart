import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// AppTheme manages the dark high-contrast Material 3 theme for MeshSOS.
/// 
/// Why this design matters for System Design & UI/UX:
/// - In disaster scenarios, apps must be clear, low-latency to render, and battery efficient.
/// - We override standard Material background colors with AppColors dark tokens
///   to ensure uniform dark styling across cards, dialogs, buttons, and app bars.
abstract class AppTheme {
  /// Dark Theme getter used as the primary theme in MaterialApp
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      
      // ColorScheme definition linking our custom AppColors tokens to Material components
      colorScheme: const ColorScheme.dark(
        primary: AppColors.sosAccent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),

      // Custom styling for top AppBar navigation
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // Card elevation and dark surface background
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Clean typography system with high-contrast text styling
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        labelSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
