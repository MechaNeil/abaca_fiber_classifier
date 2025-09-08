import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/domain/entities/classification_result.dart';
import 'package:abaca_fiber_classifier/presentation/pages/classification_results_page.dart';

void main() {
  group('Non-Admin Grade Distribution Tests', () {
    late List<String> mockLabels;

    setUp(() {
      mockLabels = ['S1', 'S2', 'S3', 'G', 'C1', 'C2', 'C3', 'C4'];
    });

    Widget createTestWidget({required ClassificationResult result}) {
      return MaterialApp(
        home: ClassificationResultsPage(
          result: result,
          imagePath: 'test_path.jpg',
          labels: mockLabels,
          // Setting authViewModel to null simulates a non-admin user scenario,
          // as the actual logic checks for null or non-admin status (authViewModel?.loggedInUser?.isAdmin == true).
          authViewModel: null,
        ),
      );
    }

    testWidgets(
      'Non-admin user should see grade distribution with high confidence (>50%)',
      (WidgetTester tester) async {
        // Create high confidence result (75%)
        final result = ClassificationResult(
          predictedLabel: 'S1',
          confidence: 0.75,
          probabilities: [0.75, 0.10, 0.05, 0.03, 0.02, 0.02, 0.02, 0.01],
        );

        await tester.pumpWidget(createTestWidget(result: result));
        await tester.pumpAndSettle();

        // Verify grade distribution is shown for non-admin with high confidence
        expect(find.text('Grade Distribution'), findsOneWidget);
        expect(find.text('Show all'), findsOneWidget);

        // Verify confidence is shown
        expect(find.text('Confidence: 75%'), findsOneWidget);

        // Verify success state is shown
        expect(find.text('GRADE S1'), findsOneWidget);
      },
    );

    testWidgets(
      'Non-admin user should NOT see grade distribution with low confidence (≤50%)',
      (WidgetTester tester) async {
        // Create low confidence result (35%)
        final result = ClassificationResult(
          predictedLabel: 'S1',
          confidence: 0.35,
          probabilities: [0.35, 0.20, 0.15, 0.10, 0.08, 0.05, 0.04, 0.03],
        );

        await tester.pumpWidget(createTestWidget(result: result));
        await tester.pumpAndSettle();

        // Verify grade distribution is NOT shown for non-admin with low confidence
        expect(find.text('Grade Distribution'), findsNothing);
        expect(find.text('Possible Grade Distribution'), findsNothing);

        // Verify "Cannot be classified" message is shown
        expect(find.text('Cannot be classified'), findsOneWidget);
      },
    );

    testWidgets(
      'Non-admin user should NOT see grade distribution with exactly 50% confidence (boundary test)',
      (WidgetTester tester) async {
        // Create exactly 50% confidence result
        final result = ClassificationResult(
          predictedLabel: 'S1',
          confidence: 0.50,
          probabilities: [0.50, 0.15, 0.10, 0.08, 0.07, 0.05, 0.03, 0.02],
        );

        await tester.pumpWidget(createTestWidget(result: result));
        await tester.pumpAndSettle();

        // At exactly 50%, confidence <= 0.5 should show low confidence state
        // So grade distribution should NOT be shown for non-admin
        expect(find.text('Grade Distribution'), findsNothing);
        expect(find.text('Possible Grade Distribution'), findsNothing);

        // Verify "Cannot be classified" message is shown
        expect(find.text('Cannot be classified'), findsOneWidget);
      },
    );

    testWidgets(
      'Non-admin user should see grade distribution with 51% confidence (just above threshold)',
      (WidgetTester tester) async {
        // Create 51% confidence result (just above threshold)
        final result = ClassificationResult(
          predictedLabel: 'S1',
          confidence: 0.51,
          probabilities: [0.51, 0.15, 0.10, 0.08, 0.06, 0.05, 0.03, 0.02],
        );

        await tester.pumpWidget(createTestWidget(result: result));
        await tester.pumpAndSettle();

        // With 51% confidence (>50%), grade distribution should be shown
        expect(find.text('Grade Distribution'), findsOneWidget);
        expect(find.text('Show all'), findsOneWidget);

        // Verify success state is shown
        expect(find.text('GRADE S1'), findsOneWidget);
        expect(find.text('Confidence: 51%'), findsOneWidget);
      },
    );

    testWidgets(
      'Grade distribution section should be expandable for non-admin users with high confidence',
      (WidgetTester tester) async {
        // Create high confidence result
        final result = ClassificationResult(
          predictedLabel: 'S1',
          confidence: 0.80,
          probabilities: [0.80, 0.08, 0.04, 0.03, 0.02, 0.01, 0.01, 0.01],
        );

        await tester.pumpWidget(createTestWidget(result: result));
        await tester.pumpAndSettle();

        // Find and tap the grade distribution header to expand
        expect(find.text('Show all'), findsOneWidget);

        await tester.tap(find.text('Grade Distribution'));
        await tester.pumpAndSettle();

        // After expansion, should show "Show less"
        expect(find.text('Show less'), findsOneWidget);

        // Tap again to collapse
        await tester.tap(find.text('Grade Distribution'));
        await tester.pumpAndSettle();

        // Should show "Show all" again
        expect(find.text('Show all'), findsOneWidget);
      },
    );
  });
}
