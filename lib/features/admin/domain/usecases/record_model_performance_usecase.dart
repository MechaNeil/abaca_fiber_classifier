import '../repositories/export_repository.dart';
import '../entities/model_performance_metrics.dart';
import 'dart:io';

/// Use case for tracking and recording model performance metrics
class RecordModelPerformanceUseCase {
  final ExportRepository _exportRepository;

  RecordModelPerformanceUseCase(this._exportRepository);

  /// Record model performance metrics based on classification history
  Future<void> recordPerformance({
    required String modelName,
    required String modelPath,
    double? averageProcessingTimeMs,
  }) async {
    final history = await _exportRepository.getAllClassificationHistory();
    final modelHistory = history.where((h) => h.model == modelPath).toList();

    if (modelHistory.isEmpty) return;

    final totalClassifications = modelHistory.length;
    final successfulClassifications = modelHistory
        .where((h) => h.confidence >= 0.5) // Using 50% confidence threshold
        .length;

    final confidences = modelHistory.map((h) => h.confidence).toList();
    final averageConfidence = confidences.isNotEmpty
        ? confidences.reduce((a, b) => a + b) / confidences.length
        : 0.0;

    final highestConfidence = confidences.isNotEmpty
        ? confidences.reduce((a, b) => a > b ? a : b)
        : 0.0;

    final lowestConfidence = confidences.isNotEmpty
        ? confidences.reduce((a, b) => a < b ? a : b)
        : 0.0;

    // Calculate grade distribution
    final gradeDistribution = <String, int>{};
    final confidencePerGrade = <String, List<double>>{};

    for (final h in modelHistory) {
      gradeDistribution[h.predictedLabel] =
          (gradeDistribution[h.predictedLabel] ?? 0) + 1;

      if (confidencePerGrade[h.predictedLabel] == null) {
        confidencePerGrade[h.predictedLabel] = [];
      }
      confidencePerGrade[h.predictedLabel]!.add(h.confidence);
    }

    // Calculate average confidence per grade
    final averageConfidencePerGrade = <String, double>{};
    confidencePerGrade.forEach((grade, confidencesList) {
      averageConfidencePerGrade[grade] =
          confidencesList.reduce((a, b) => a + b) / confidencesList.length;
    });

    final deviceInfo = await _getDeviceInfo();

    final metrics = ModelPerformanceMetrics(
      modelName: modelName,
      modelPath: modelPath,
      recordedAt: DateTime.now(),
      totalClassifications: totalClassifications,
      successfulClassifications: successfulClassifications,
      averageConfidence: averageConfidence,
      highestConfidence: highestConfidence,
      lowestConfidence: lowestConfidence,
      gradeDistribution: gradeDistribution,
      averageConfidencePerGrade: averageConfidencePerGrade,
      processingTimeMs: averageProcessingTimeMs ?? 0.0,
      deviceInfo: deviceInfo,
    );

    await _exportRepository.recordModelPerformance(metrics);
  }

  /// Get all model performance metrics
  Future<List<ModelPerformanceMetrics>> getAllMetrics() async {
    return await _exportRepository.getAllModelPerformanceMetrics();
  }

  /// Get latest performance metrics for a specific model
  Future<ModelPerformanceMetrics?> getLatestMetrics(String modelPath) async {
    return await _exportRepository.getLatestModelPerformance(modelPath);
  }

  /// Get all performance metrics for a specific model
  Future<List<ModelPerformanceMetrics>> getMetricsByModel(
    String modelPath,
  ) async {
    return await _exportRepository.getModelPerformanceByModel(modelPath);
  }

  /// Get device information for performance tracking
  Future<String> _getDeviceInfo() async {
    try {
      final platform = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;
      return '$platform $version';
    } catch (e) {
      return 'Unknown Platform';
    }
  }
}
