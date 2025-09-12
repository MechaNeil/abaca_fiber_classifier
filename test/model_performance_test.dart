import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/features/admin/data/export_repository_impl.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/usecases/record_model_performance_usecase.dart';
import 'package:abaca_fiber_classifier/domain/entities/classification_history.dart';
import 'package:abaca_fiber_classifier/data/repositories/history_repository_impl.dart';

void main() {
  group('Model Performance Tests', () {
    late ExportRepositoryImpl exportRepository;
    late RecordModelPerformanceUseCase recordModelPerformanceUseCase;
    late HistoryRepositoryImpl historyRepository;

    setUpAll(() async {
      exportRepository = ExportRepositoryImpl();
      recordModelPerformanceUseCase = RecordModelPerformanceUseCase(
        exportRepository,
      );
      historyRepository = HistoryRepositoryImpl();
    });

    test(
      'Should record model performance metrics with actual classification data',
      () async {
        // First, add some test classification history
        final testHistory = ClassificationHistory(
          imagePath: '/test/image.jpg',
          predictedLabel: 'Grade A',
          confidence: 0.95,
          probabilities: [0.95, 0.03, 0.02],
          timestamp: DateTime.now(),
          userId: 1,
          model: 'mobilenetv3small_b2.tflite',
        );

        // Save test history
        await historyRepository.saveHistory(testHistory);

        // Record model performance
        await recordModelPerformanceUseCase.recordPerformance(
          modelName: 'MobileNetV3 Small B2',
          modelPath: 'mobilenetv3small_b2.tflite',
        );

        // Verify that model performance metrics were recorded
        final allMetrics = await recordModelPerformanceUseCase.getAllMetrics();
        expect(allMetrics.isNotEmpty, true);

        final latestMetrics = await recordModelPerformanceUseCase
            .getLatestMetrics('mobilenetv3small_b2.tflite');
        expect(latestMetrics, isNotNull);
        expect(latestMetrics!.modelName, equals('MobileNetV3 Small B2'));
        expect(latestMetrics.totalClassifications, greaterThan(0));
      },
    );

    test('Should handle empty classification history gracefully', () async {
      // Try to record performance for a non-existent model
      await recordModelPerformanceUseCase.recordPerformance(
        modelName: 'Non-Existent Model',
        modelPath: 'non_existent_model.tflite',
      );

      // Should not throw an error - should handle gracefully
      expect(true, true); // Test passes if no exception is thrown
    });
  });
}
