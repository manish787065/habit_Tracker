import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color bodyColor) {
    return GoogleFonts.interTextTheme().apply(
      bodyColor: bodyColor,
      displayColor: bodyColor,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        background: AppColors.background,
        primary: AppColors.primaryAction,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.cardBackground,
        brightness: Brightness.light,
      ),

      // Typography
      textTheme: _buildTextTheme(AppColors.textPrimary),

      // Card Theme (Rounded & Flat)
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0, 
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAction, 
          foregroundColor: AppColors.textPrimary, // Dark text on light mint button
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Pill shape
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.primaryAccent,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        background: AppColors.backgroundDark,
        primary: AppColors.primaryAction,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.cardBackgroundDark, 
        brightness: Brightness.dark,
      ),

      // Typography
      textTheme: _buildTextTheme(AppColors.textPrimaryDark),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardBackgroundDark,
        elevation: 0,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: AppColors.textPrimary, // Dark text on mint button even in dark mode for contrast
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryDark,
      ),
    );
  }
}
