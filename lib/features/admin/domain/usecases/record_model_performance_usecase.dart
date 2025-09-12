import '../repositories/export_repository.dart';
import '../entities/model_performance_metrics.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

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
    debugPrint(
      'RECORD PERFORMANCE: Starting for model: $modelName, path: $modelPath',
    );

    final history = await _exportRepository.getAllClassificationHistory();
    debugPrint('RECORD PERFORMANCE: Total history records: ${history.length}');

    // Debug: Print some sample history records to see what model paths are stored
    for (int i = 0; i < math.min(3, history.length); i++) {
      debugPrint(
        'RECORD PERFORMANCE: Sample history[$i] model: "${history[i].model}"',
      );
    }

    final modelHistory = history.where((h) => h.model == modelPath).toList();
    debugPrint(
      'RECORD PERFORMANCE: Matching model history records: ${modelHistory.length}',
    );

    if (modelHistory.isEmpty) {
      debugPrint(
        'RECORD PERFORMANCE: No history found for model path: $modelPath',
      );
      debugPrint('RECORD PERFORMANCE: Available model paths in history:');
      final uniqueModels = history.map((h) => h.model).toSet();
      for (final model in uniqueModels) {
        debugPrint('  - "$model"');
      }
      return;
    }

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

    debugPrint('RECORD PERFORMANCE: Recording metrics for $modelName:');
    debugPrint('  - Total classifications: $totalClassifications');
    debugPrint('  - Successful classifications: $successfulClassifications');
    debugPrint(
      '  - Average confidence: ${(averageConfidence * 100).toStringAsFixed(1)}%',
    );

    await _exportRepository.recordModelPerformance(metrics);
    debugPrint(
      'RECORD PERFORMANCE: Successfully recorded model performance metrics',
    );
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
