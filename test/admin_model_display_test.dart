import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/presentation/pages/classification_results_page.dart';
import 'package:abaca_fiber_classifier/domain/entities/classification_result.dart';

void main() {
  group('Admin Model Display Tests', () {
    testWidgets('Should handle admin parameters without crashing', (
      WidgetTester tester,
    ) async {
      // Create a classification result
      final result = ClassificationResult(
        predictedLabel: 'G',
        confidence: 0.85,
        probabilities: [0.1, 0.85, 0.05], // Example probabilities
      );

      final widget = MaterialApp(
        home: ClassificationResultsPage(
          imagePath: 'test/path/image.jpg',
          result: result,
          labels: ['EF', 'G', 'H'],
          isError: false,
          // Test with null auth and classification view models
          authViewModel: null,
          classificationViewModel: null,
          onRetakePhoto: () {},
          onNewClassification: () {},
        ),
      );

      // Build the widget
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify the page loads successfully with new parameters
      expect(find.textContaining('GRADE G'), findsOneWidget);
      expect(find.textContaining('Confidence: 85%'), findsOneWidget);
      // Model name should not be displayed when auth is null
      expect(find.textContaining('Model:'), findsNothing);
    });

    testWidgets('Should display basic functionality without admin features', (
      WidgetTester tester,
    ) async {
      // Create a classification result
      final result = ClassificationResult(
        predictedLabel: 'H',
        confidence: 0.72,
        probabilities: [0.1, 0.2, 0.72, 0.05],
      );

      final widget = MaterialApp(
        home: ClassificationResultsPage(
          imagePath: 'test/path/image.jpg',
          result: result,
          labels: ['EF', 'G', 'H', 'I'],
          isError: false,
          onRetakePhoto: () {},
          onNewClassification: () {},
        ),
      );

      // Build the widget
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify the page works with the original functionality
      expect(find.textContaining('GRADE H'), findsOneWidget);
      expect(find.textContaining('Confidence: 72%'), findsOneWidget);
      expect(find.text('Grade Distribution'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Should handle error state correctly', (
      WidgetTester tester,
    ) async {
      final widget = MaterialApp(
        home: ClassificationResultsPage(
          imagePath: 'test/path/image.jpg',
          result: null,
          labels: ['EF', 'G', 'H'],
          isError: true,
          authViewModel: null,
          classificationViewModel: null,
          onRetakePhoto: () {},
        ),
      );

      // Build the widget
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify error state is displayed correctly
      expect(find.textContaining("We couldn't classify"), findsOneWidget);
      expect(find.text('View Guide'), findsOneWidget);
      expect(find.text('Retake Photo'), findsOneWidget);
      // Model name should not be displayed in error state
      expect(find.textContaining('Model:'), findsNothing);
    });
  });
}
