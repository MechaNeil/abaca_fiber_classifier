import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/theme_mode.dart';
import '../../data/app_themes.dart';

/// View model for managing app theme state and persistence
class ThemeViewModel extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  AppThemeMode _currentThemeMode = AppThemeMode.light;
  bool _isInitialized = false;

  /// Get the current theme mode
  AppThemeMode get currentThemeMode => _currentThemeMode;

  /// Check if the theme is dark mode
  bool get isDarkMode => _currentThemeMode == AppThemeMode.dark;

  /// Check if the theme is light mode
  bool get isLightMode => _currentThemeMode == AppThemeMode.light;

  /// Check if the view model has been initialized
  bool get isInitialized => _isInitialized;

  /// Get the current theme data based on the selected mode
  ThemeData get currentTheme {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return AppThemes.lightTheme;
      case AppThemeMode.dark:
        return AppThemes.darkTheme;
    }
  }

  /// Initialize the theme from stored preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTheme = prefs.getString(_themeKey);

      if (storedTheme != null) {
        _currentThemeMode = AppThemeModeExtension.fromStorageString(
          storedTheme,
        );
      } else {
        // Default to light mode if no preference is stored
        _currentThemeMode = AppThemeMode.light;
        await _saveThemePreference();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      // Fallback to light mode on error
      _currentThemeMode = AppThemeMode.light;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Switch to a specific theme mode
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    if (_currentThemeMode == themeMode) return;

    _currentThemeMode = themeMode;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    final newTheme = _currentThemeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;

    await setThemeMode(newTheme);
  }

  /// Save the current theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _currentThemeMode.toStorageString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Clear all theme preferences (useful for testing or reset)
  Future<void> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      _currentThemeMode = AppThemeMode.light;
      _isInitialized = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing theme preferences: $e');
    }
  }

  /// Get theme mode display information
  String get currentThemeDisplayName => _currentThemeMode.displayName;

  /// Get the appropriate icon for the current theme
  IconData get currentThemeIcon {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return Icons.wb_sunny_outlined;
      case AppThemeMode.dark:
        return Icons.nights_stay_outlined;
    }
  }

  /// Get the icon for the opposite theme (useful for toggle buttons)
  IconData get oppositeThemeIcon {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return Icons.nights_stay_outlined;
      case AppThemeMode.dark:
        return Icons.wb_sunny_outlined;
    }
  }
}
