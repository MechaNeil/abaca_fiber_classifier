import '../entities/user_activity_log.dart';
import '../entities/model_performance_metrics.dart';
import '../entities/export_data_package.dart';
import '../../../../domain/entities/classification_history.dart';

/// Repository interface for export and logging operations
abstract class ExportRepository {
  // User Activity Logs
  Future<void> logUserActivity(UserActivityLog activityLog);
  Future<List<UserActivityLog>> getAllUserActivityLogs();
  Future<List<UserActivityLog>> getUserActivityLogsByUser(int userId);
  Future<List<UserActivityLog>> getUserActivityLogsByType(String activityType);

  // Model Performance Metrics
  Future<void> recordModelPerformance(ModelPerformanceMetrics metrics);
  Future<List<ModelPerformanceMetrics>> getAllModelPerformanceMetrics();
  Future<ModelPerformanceMetrics?> getLatestModelPerformance(String modelPath);
  Future<List<ModelPerformanceMetrics>> getModelPerformanceByModel(
    String modelPath,
  );

  // Export Operations
  Future<ExportDataPackage> prepareExportData();
  Future<String> exportToCSV(ExportDataPackage data, String exportType);
  Future<String> exportToJSON(ExportDataPackage data);
  Future<List<Map<String, dynamic>>> getAllDatabaseTables();

  // Classification History (extended interface)
  Future<List<ClassificationHistory>> getAllClassificationHistory();

  // System Information
  Future<Map<String, dynamic>> getSystemInfo();

  // Permission and Storage
  Future<bool> checkStoragePermission();
  Future<bool> requestStoragePermission();

  // Export Location Information
  Future<String> getExportLocationDescription();
}
