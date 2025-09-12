import '../repositories/export_repository.dart';

/// Use case for exporting comprehensive classification logs and data
class ExportLogsUseCase {
  final ExportRepository _exportRepository;

  ExportLogsUseCase(this._exportRepository);

  /// Export all data as CSV files
  Future<List<String>> exportAsCSV() async {
    final exportData = await _exportRepository.prepareExportData();

    final exportPaths = <String>[];

    // Export classification history
    final historyPath = await _exportRepository.exportToCSV(
      exportData,
      'classification_history',
    );
    exportPaths.add(historyPath);

    // Export user activity logs
    final activityPath = await _exportRepository.exportToCSV(
      exportData,
      'user_activity_logs',
    );
    exportPaths.add(activityPath);

    // Export model performance metrics
    final metricsPath = await _exportRepository.exportToCSV(
      exportData,
      'model_performance_metrics',
    );
    exportPaths.add(metricsPath);

    return exportPaths;
  }

  /// Export all data as JSON
  Future<String> exportAsJSON() async {
    final exportData = await _exportRepository.prepareExportData();
    return await _exportRepository.exportToJSON(exportData);
  }

  /// Export complete data package (JSON + CSV)
  Future<Map<String, dynamic>> exportComplete() async {
    final exportData = await _exportRepository.prepareExportData();

    final jsonPath = await _exportRepository.exportToJSON(exportData);
    final csvPaths = await exportAsCSV();

    return {
      'json_export': jsonPath,
      'csv_exports': csvPaths,
      'summary': exportData.getExportSummary(),
      'total_records': exportData.totalRecords,
    };
  }

  /// Get export preview/summary without creating files
  Future<Map<String, dynamic>> getExportPreview() async {
    final exportData = await _exportRepository.prepareExportData();
    return exportData.getExportSummary();
  }

  /// Check if storage permission is granted
  Future<bool> checkStoragePermission() async {
    return await _exportRepository.checkStoragePermission();
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    return await _exportRepository.requestStoragePermission();
  }

  /// Get export location description
  Future<String> getExportLocationDescription() async {
    return await _exportRepository.getExportLocationDescription();
  }
}
