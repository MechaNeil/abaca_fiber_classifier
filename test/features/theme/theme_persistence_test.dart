import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abaca_fiber_classifier/features/theme/presentation/viewmodels/theme_view_model.dart';
import 'package:abaca_fiber_classifier/features/theme/domain/theme_mode.dart';

/// Test file to demonstrate theme persistence functionality
void main() {
  group('Theme Persistence Tests', () {
    late ThemeViewModel themeViewModel;

    setUp(() async {
      // Clear any existing preferences
      SharedPreferences.setMockInitialValues({});
      themeViewModel = ThemeViewModel();
    });

    testWidgets('Theme initializes with light mode by default', (tester) async {
      await themeViewModel.initialize();

      expect(themeViewModel.currentThemeMode, AppThemeMode.light);
      expect(themeViewModel.isLightMode, true);
      expect(themeViewModel.isDarkMode, false);
    });

    testWidgets('Theme toggle switches between light and dark', (tester) async {
      await themeViewModel.initialize();

      // Start with light mode
      expect(themeViewModel.isLightMode, true);

      // Toggle to dark mode
      await themeViewModel.toggleTheme();
      expect(themeViewModel.isDarkMode, true);

      // Toggle back to light mode
      await themeViewModel.toggleTheme();
      expect(themeViewModel.isLightMode, true);
    });

    testWidgets('Theme preference is persisted across app restarts', (
      tester,
    ) async {
      // Initialize and set to dark mode
      await themeViewModel.initialize();
      await themeViewModel.setThemeMode(AppThemeMode.dark);
      expect(themeViewModel.isDarkMode, true);

      // Create a new view model instance (simulating app restart)
      final newThemeViewModel = ThemeViewModel();
      await newThemeViewModel.initialize();

      // Should remember dark mode preference
      expect(newThemeViewModel.isDarkMode, true);
      expect(newThemeViewModel.currentThemeMode, AppThemeMode.dark);
    });

    testWidgets('Theme change notifications work correctly', (tester) async {
      await themeViewModel.initialize();

      bool notificationReceived = false;
      themeViewModel.addListener(() {
        notificationReceived = true;
      });

      // Change theme and verify notification
      await themeViewModel.toggleTheme();
      expect(notificationReceived, true);
    });

    testWidgets('Error handling works when SharedPreferences fails', (
      tester,
    ) async {
      // This test would require mocking SharedPreferences to throw an error
      // For now, we just verify that the view model handles initialization gracefully
      await themeViewModel.initialize();
      expect(themeViewModel.isInitialized, true);
    });
  });
}
