import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_prototype_v1/domain/entities/classification_result.dart';

void main() {
  group('Confidence Validation Tests', () {
    test(
      'Classification result should correctly identify low confidence (≤50%)',
      () {
        // Test case 1: Low confidence (30%)
        final lowConfidenceResult = ClassificationResult(
          predictedLabel: 'G',
          confidence: 0.30,
          probabilities: [0.1, 0.3, 0.15, 0.12, 0.08, 0.1, 0.1, 0.05],
        );

        expect(lowConfidenceResult.confidence <= 0.5, true);
        expect(lowConfidenceResult.confidence, 0.30);

        // Test case 2: Exactly 50% confidence
        final fiftyPercentResult = ClassificationResult(
          predictedLabel: 'H',
          confidence: 0.50,
          probabilities: [0.1, 0.2, 0.5, 0.05, 0.05, 0.05, 0.03, 0.02],
        );

        expect(fiftyPercentResult.confidence <= 0.5, true);
        expect(fiftyPercentResult.confidence, 0.50);

        // Test case 3: High confidence (85%)
        final highConfidenceResult = ClassificationResult(
          predictedLabel: 'G',
          confidence: 0.85,
          probabilities: [0.05, 0.85, 0.03, 0.02, 0.02, 0.01, 0.01, 0.01],
        );

        expect(highConfidenceResult.confidence <= 0.5, false);
        expect(highConfidenceResult.confidence, 0.85);
      },
    );

    test(
      'Classification result should correctly format confidence percentage',
      () {
        final result = ClassificationResult(
          predictedLabel: 'G',
          confidence: 0.35, // 35%
          probabilities: [0.1, 0.35, 0.2, 0.15, 0.1, 0.05, 0.03, 0.02],
        );

        // Test the toString formatting
        expect(result.toString(), contains('35.00%'));

        // Test percentage calculation
        final percentageAsInt = (result.confidence * 100).toInt();
        expect(percentageAsInt, 35);
      },
    );

    test('Low confidence validation logic works correctly', () {
      // Create test cases with different confidence levels
      final testCases = [
        {
          'confidence': 0.10,
          'shouldShowError': true,
        }, // 10% - should show error
        {
          'confidence': 0.25,
          'shouldShowError': true,
        }, // 25% - should show error
        {
          'confidence': 0.45,
          'shouldShowError': true,
        }, // 45% - should show error
        {
          'confidence': 0.50,
          'shouldShowError': true,
        }, // 50% - should show error (≤50%)
        {
          'confidence': 0.51,
          'shouldShowError': false,
        }, // 51% - should show success
        {
          'confidence': 0.75,
          'shouldShowError': false,
        }, // 75% - should show success
        {
          'confidence': 0.90,
          'shouldShowError': false,
        }, // 90% - should show success
      ];

      for (final testCase in testCases) {
        final confidence = testCase['confidence'] as double;
        final shouldShowError = testCase['shouldShowError'] as bool;

        final result = ClassificationResult(
          predictedLabel: 'G',
          confidence: confidence,
          probabilities: [0.1, confidence, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
        );

        // Test the validation logic: confidence ≤ 0.5 should trigger error state
        final isLowConfidence = result.confidence <= 0.5;
        expect(
          isLowConfidence,
          shouldShowError,
          reason:
              'Confidence ${(confidence * 100).toInt()}% should ${shouldShowError ? "trigger" : "not trigger"} error state',
        );
      }
    });

    test('Probabilities should sum approximately to 1.0', () {
      final result = ClassificationResult(
        predictedLabel: 'G',
        confidence: 0.35,
        probabilities: [
          0.1,
          0.35,
          0.2,
          0.15,
          0.1,
          0.05,
          0.03,
          0.02,
        ], // Sum = 1.00
      );

      final sum = result.probabilities.fold<double>(
        0.0,
        (sum, value) => sum + value,
      );
      expect(sum, closeTo(1.0, 0.01)); // Allow small floating point errors
    });

    test('Predicted label should match highest probability', () {
      // Create a result where 'H' has the highest probability
      final result = ClassificationResult(
        predictedLabel: 'H',
        confidence: 0.45, // This is the confidence for the predicted class
        probabilities: [0.1, 0.2, 0.45, 0.1, 0.05, 0.05, 0.03, 0.02],
        //                EF   G    H    I   JK   M1   S2   S3
      );

      // Find the index of the maximum probability
      double maxProb = result.probabilities[0];
      int maxIndex = 0;
      for (int i = 1; i < result.probabilities.length; i++) {
        if (result.probabilities[i] > maxProb) {
          maxProb = result.probabilities[i];
          maxIndex = i;
        }
      }

      // The confidence should match the maximum probability
      expect(result.confidence, maxProb);
      expect(
        maxIndex,
        2,
      ); // 'H' should be at index 2 in ['EF', 'G', 'H', 'I', 'JK', 'M1', 'S2', 'S3']
    });
  });
}
