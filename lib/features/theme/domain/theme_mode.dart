/// Enum representing the available theme modes
enum AppThemeMode { light, dark }

/// Extension to provide utility methods for AppThemeMode
extension AppThemeModeExtension on AppThemeMode {
  /// Get the display name for the theme mode
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Get the icon data for the theme mode
  String get iconName {
    switch (this) {
      case AppThemeMode.light:
        return 'wb_sunny';
      case AppThemeMode.dark:
        return 'nights_stay';
    }
  }

  /// Convert to string for storage
  String toStorageString() {
    return name;
  }

  /// Create from string storage
  static AppThemeMode fromStorageString(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.light; // Default fallback
    }
  }
}
