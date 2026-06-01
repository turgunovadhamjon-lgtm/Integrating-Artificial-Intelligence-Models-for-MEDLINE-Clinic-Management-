// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;
  static const String _themeKey = 'is_dark_mode';

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true; // Default to dark
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
    notifyListeners();
  }

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF4DB6AC);
  static const Color darkBackground = Color(0xFF0A2D4A);
  static const Color darkSurface = Color(0xFF1E2746);
  static const Color darkCard = Color(0xFF1A1F36);

  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF00897B);
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;

  // Gradient Colors
  List<Color> get gradientColors => _isDarkMode
      ? [const Color(0xFF0A7075), const Color(0xFF083D56), const Color(0xFF0A2D4A), const Color(0xFF0F1E3C)]
      : [const Color(0xFF4DB6AC), const Color(0xFF26A69A), const Color(0xFF00897B), const Color(0xFF00796B)];

  // Text Colors
  Color get textPrimary => _isDarkMode ? Colors.white : Colors.black87;
  Color get textSecondary => _isDarkMode ? Colors.white70 : Colors.black54;
  Color get textHint => _isDarkMode ? Colors.white38 : Colors.black38;

  // Card Colors
  Color get cardBackground => _isDarkMode 
      ? Colors.white.withOpacity(0.08) 
      : Colors.white;
  Color get cardBorder => _isDarkMode 
      ? Colors.white.withOpacity(0.1) 
      : Colors.grey.withOpacity(0.2);

  // Input Colors
  Color get inputFill => _isDarkMode 
      ? Colors.black.withOpacity(0.2) 
      : Colors.grey.withOpacity(0.1);

  // Icon Colors
  Color get iconColor => _isDarkMode ? Colors.white70 : Colors.black54;

  // Surface Color
  Color get surfaceColor => _isDarkMode ? darkSurface : lightSurface;

  // Background Gradient
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: gradientColors,
  );

  // Glass Decoration
  BoxDecoration glassDecoration({double borderRadius = 20, bool hasShadow = true}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: cardBorder),
      boxShadow: hasShadow ? [
        BoxShadow(
          color: _isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ] : null,
    );
  }

  // Input Decoration
  InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textHint),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: iconColor, size: 22) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _isDarkMode ? darkPrimary : lightPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  // Dialog Background Color
  Color get dialogBackground => _isDarkMode ? darkSurface : lightSurface;

  // Floating Particle Color
  Color get particleColor => _isDarkMode 
      ? Colors.white.withOpacity(0.08) 
      : Colors.white.withOpacity(0.3);

  // AppBar style
  Color get appBarBackground => Colors.transparent;
  Color get appBarIconColor => _isDarkMode ? Colors.white : Colors.white;
  Color get appBarTitleColor => _isDarkMode ? Colors.white : Colors.white;

  // Button Colors
  Color get primaryButtonColor => _isDarkMode ? darkPrimary : lightPrimary;
  Color get buttonTextColor => Colors.white;

  // Status Colors (same for both themes)
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
}
