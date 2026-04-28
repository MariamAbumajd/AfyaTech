import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors (الافتراضي)
  static const Color background = Color(0xFFF7F8FA);
  static const Color primaryTeal = Color(0xFF0A8E9C);
  static const Color primaryCyan = Color(0xFF4DBFD8);
  static const Color textDarkTeal = Color(0xFF088F8F);
  static const Color accentOrange = Color(0xFFF4A261);
  static const Color lightBlue = Color(0xFFC6E4F2);
  static const Color emergencyRed = Color(0xFFFF4444);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF333333);
  static const Color secondaryDarkCyan = Color(0xFF0A5E6C);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkPrimaryTeal = Color(0xFF4DBFD8);
  static const Color darkAccentOrange = Color(0xFFFFA726);

  // دالة للحصول على الألوان حسب الوضع
  static Color getBackground(bool isDarkMode) {
    return isDarkMode ? darkBackground : background;
  }

  static Color getSurface(bool isDarkMode) {
    return isDarkMode ? darkSurface : white;
  }

  static Color getCard(bool isDarkMode) {
    return isDarkMode ? darkCard : white;
  }

  static Color getText(bool isDarkMode) {
    return isDarkMode ? darkText : textDark;
  }

  static Color getTextSecondary(bool isDarkMode) {
    return isDarkMode ? darkTextSecondary : Colors.grey;
  }

  static Color getPrimary(bool isDarkMode) {
    return isDarkMode ? darkPrimaryTeal : primaryTeal;
  }

  static Color getAccent(bool isDarkMode) {
    return isDarkMode ? darkAccentOrange : accentOrange;
  }

  static Color getTextDarkTeal(bool isDarkMode) {
    return isDarkMode ? darkPrimaryTeal : textDarkTeal;
  }
}