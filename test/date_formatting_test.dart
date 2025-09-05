import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_prototype_v1/domain/entities/classification_history.dart';

void main() {
  group('ClassificationHistory Date Formatting Tests', () {
    test('formattedDate should show MM/DD/YYYY at HH:MM AM/PM format', () {
      // Create a classification history with a specific timestamp
      final testDate = DateTime(
        2025,
        9,
        4,
        14,
        30,
        0,
      ); // Sep 4, 2025 at 2:30 PM
      final history = ClassificationHistory(
        id: 1,
        imagePath: '/test/path.jpg',
        predictedLabel: 'S2',
        confidence: 0.95,
        probabilities: [0.95, 0.03, 0.02],
        timestamp: testDate,
        userId: 1,
      );

      // Test the formatted date
      final result = history.formattedDate;
      expect(result, equals('09/04/2025 at 2:30 PM'));
    });

    test('shortFormattedDate should show time for today', () {
      // Create a classification history for today
      final now = DateTime.now();
      final testDate = DateTime(now.year, now.month, now.day, 14, 30, 0);
      final history = ClassificationHistory(
        id: 1,
        imagePath: '/test/path.jpg',
        predictedLabel: 'S2',
        confidence: 0.95,
        probabilities: [0.95, 0.03, 0.02],
        timestamp: testDate,
        userId: 1,
      );

      // Test the short formatted date
      final result = history.shortFormattedDate;
      expect(result, equals('2:30 PM'));
    });

    test('shortFormattedDate should show MM/DD for other days', () {
      // Create a classification history for yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final testDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        14,
        30,
        0,
      );
      final history = ClassificationHistory(
        id: 1,
        imagePath: '/test/path.jpg',
        predictedLabel: 'S2',
        confidence: 0.95,
        probabilities: [0.95, 0.03, 0.02],
        timestamp: testDate,
        userId: 1,
      );

      // Test the short formatted date
      final result = history.shortFormattedDate;
      final expectedMonth = yesterday.month.toString().padLeft(2, '0');
      final expectedDay = yesterday.day.toString().padLeft(2, '0');
      expect(result, equals('$expectedMonth/$expectedDay'));
    });

    test('friendlyDate should show relative time for recent entries', () {
      // Create a classification history for 2 hours ago
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final history = ClassificationHistory(
        id: 1,
        imagePath: '/test/path.jpg',
        predictedLabel: 'S2',
        confidence: 0.95,
        probabilities: [0.95, 0.03, 0.02],
        timestamp: twoHoursAgo,
        userId: 1,
      );

      // Test the friendly date
      final result = history.friendlyDate;
      expect(result, equals('2h ago'));
    });

    test('friendlyDate should show "Yesterday at time" for yesterday', () {
      // Create a classification history for yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final testDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        14,
        30,
        0,
      );
      final history = ClassificationHistory(
        id: 1,
        imagePath: '/test/path.jpg',
        predictedLabel: 'S2',
        confidence: 0.95,
        probabilities: [0.95, 0.03, 0.02],
        timestamp: testDate,
        userId: 1,
      );

      // Test the friendly date
      final result = history.friendlyDate;
      expect(result, equals('Yesterday at 2:30 PM'));
    });
  });
}
