import '../../../../domain/entities/classification_history.dart';
import 'user_activity_log.dart';
import 'model_performance_metrics.dart';

/// Entity representing complete export data package
///
/// This entity contains all the data types that can be exported
/// from the admin panel, organized into logical categories.
class ExportDataPackage {
  final DateTime exportTimestamp;
  final String exportedBy;
  final String appVersion;
  final List<ClassificationHistory> classificationHistory;
  final List<UserActivityLog> userActivityLogs;
  final List<ModelPerformanceMetrics> modelPerformanceMetrics;
  final Map<String, dynamic> databaseTables;
  final Map<String, dynamic> systemInfo;

  const ExportDataPackage({
    required this.exportTimestamp,
    required this.exportedBy,
    required this.appVersion,
    required this.classificationHistory,
    required this.userActivityLogs,
    required this.modelPerformanceMetrics,
    required this.databaseTables,
    required this.systemInfo,
  });

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'export_info': {
        'timestamp': exportTimestamp.toIso8601String(),
        'exported_by': exportedBy,
        'app_version': appVersion,
        'total_records': totalRecords,
      },
      'classification_history': classificationHistory
          .map((h) => h.toMap())
          .toList(),
      'user_activity_logs': userActivityLogs.map((log) => log.toMap()).toList(),
      'model_performance_metrics': modelPerformanceMetrics
          .map((m) => m.toMap())
          .toList(),
      'database_tables': databaseTables,
      'system_info': systemInfo,
    };
  }

  /// Convert classification history to CSV format
  List<List<dynamic>> classificationHistoryToCsv() {
    final headers = [
      'ID',
      'Image Path',
      'Predicted Label',
      'Confidence',
      'Probabilities',
      'Timestamp',
      'User ID',
      'Model',
      'Date',
      'Time',
      'Confidence %',
    ];

    final rows = classificationHistory.map((history) {
      return [
        history.id,
        history.imagePath,
        history.predictedLabel,
        history.confidence,
        history.probabilities.join(';'),
        history.timestamp.millisecondsSinceEpoch,
        history.userId,
        history.model,
        _formatDate(history.timestamp),
        _formatTime(history.timestamp),
        '${(history.confidence * 100).toStringAsFixed(2)}%',
      ];
    }).toList();

    return [headers, ...rows];
  }

  /// Convert user activity logs to CSV format
  List<List<dynamic>> userActivityLogsToCsv() {
    final headers = [
      'ID',
      'User ID',
      'Username',
      'Activity Type',
      'Description',
      'Timestamp',
      'Metadata',
      'Date',
      'Time',
    ];

    final rows = userActivityLogs.map((log) {
      return [
        log.id,
        log.userId,
        log.username,
        log.activityType,
        log.description,
        log.timestamp.millisecondsSinceEpoch,
        log.metadata?.toString() ?? '',
        _formatDate(log.timestamp),
        _formatTime(log.timestamp),
      ];
    }).toList();

    return [headers, ...rows];
  }

  /// Convert model performance metrics to CSV format
  List<List<dynamic>> modelPerformanceMetricsToCsv() {
    final headers = [
      'ID',
      'Model Name',
      'Model Path',
      'Recorded At',
      'Total Classifications',
      'Successful Classifications',
      'Success Rate %',
      'Average Confidence',
      'Highest Confidence',
      'Lowest Confidence',
      'Grade Distribution',
      'Average Confidence Per Grade',
      'Processing Time (ms)',
      'Device Info',
      'Most Classified Grade',
    ];

    final rows = modelPerformanceMetrics.map((metrics) {
      return [
        metrics.id,
        metrics.modelName,
        metrics.modelPath,
        metrics.recordedAt.millisecondsSinceEpoch,
        metrics.totalClassifications,
        metrics.successfulClassifications,
        '${metrics.successRate.toStringAsFixed(2)}%',
        '${(metrics.averageConfidence * 100).toStringAsFixed(2)}%',
        '${(metrics.highestConfidence * 100).toStringAsFixed(2)}%',
        '${(metrics.lowestConfidence * 100).toStringAsFixed(2)}%',
        metrics.gradeDistribution.entries
            .map((e) => '${e.key}:${e.value}')
            .join(';'),
        metrics.averageConfidencePerGrade.entries
            .map((e) => '${e.key}:${(e.value * 100).toStringAsFixed(2)}%')
            .join(';'),
        metrics.processingTimeMs.toStringAsFixed(2),
        metrics.deviceInfo,
        metrics.mostClassifiedGrade,
      ];
    }).toList();

    return [headers, ...rows];
  }

  /// Get export summary
  Map<String, dynamic> getExportSummary() {
    return {
      'export_timestamp': exportTimestamp.toIso8601String(),
      'exported_by': exportedBy,
      'app_version': appVersion,
      'total_records': totalRecords,
      'classification_history_count': classificationHistory.length,
      'user_activity_logs_count': userActivityLogs.length,
      'model_performance_metrics_count': modelPerformanceMetrics.length,
      'date_range': {
        'earliest_classification': classificationHistory.isNotEmpty
            ? classificationHistory
                  .map((h) => h.timestamp)
                  .reduce((a, b) => a.isBefore(b) ? a : b)
                  .toIso8601String()
            : null,
        'latest_classification': classificationHistory.isNotEmpty
            ? classificationHistory
                  .map((h) => h.timestamp)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
                  .toIso8601String()
            : null,
      },
      'statistics': {
        'total_classifications': classificationHistory.length,
        'unique_models': modelPerformanceMetrics
            .map((m) => m.modelName)
            .toSet()
            .length,
        'unique_users': classificationHistory
            .map((h) => h.userId)
            .where((id) => id != null)
            .toSet()
            .length,
        'grade_distribution': _calculateGradeDistribution(),
      },
    };
  }

  /// Calculate total records across all data types
  int get totalRecords {
    return classificationHistory.length +
        userActivityLogs.length +
        modelPerformanceMetrics.length;
  }

  /// Format date for CSV
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Format time for CSV
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Calculate grade distribution from classification history
  Map<String, int> _calculateGradeDistribution() {
    final distribution = <String, int>{};
    for (final history in classificationHistory) {
      distribution[history.predictedLabel] =
          (distribution[history.predictedLabel] ?? 0) + 1;
    }
    return distribution;
  }
}
