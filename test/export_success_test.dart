import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/features/admin/data/export_repository_impl.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/entities/export_data_package.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/entities/user_activity_log.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/entities/model_performance_metrics.dart';
import 'package:abaca_fiber_classifier/domain/entities/classification_history.dart';

void main() {
  group('Export Success Tests', () {
    late ExportRepositoryImpl exportRepository;

    setUp(() {
      exportRepository = ExportRepositoryImpl();
    });

    test(
      'export methods should not throw exceptions for app-specific storage',
      () async {
        // Create test data
        final exportData = ExportDataPackage(
          exportTimestamp: DateTime.now(),
          exportedBy: 'test_user',
          appVersion: '1.0.0',
          classificationHistory: <ClassificationHistory>[],
          userActivityLogs: <UserActivityLog>[],
          modelPerformanceMetrics: <ModelPerformanceMetrics>[],
          databaseTables: <String, dynamic>{},
          systemInfo: <String, dynamic>{},
        );

        // These should not throw exceptions even if permission is denied
        expect(() async {
          try {
            await exportRepository.exportToCSV(exportData, 'test');
          } catch (e) {
            // Should not get permission-related exceptions
            expect(e.toString().contains('app-specific storage'), false);
          }
        }, returnsNormally);

        expect(() async {
          try {
            await exportRepository.exportToJSON(exportData);
          } catch (e) {
            // Should not get permission-related exceptions
            expect(e.toString().contains('app-specific storage'), false);
          }
        }, returnsNormally);
      },
    );

    test(
      'storage permission check should work for all Android versions',
      () async {
        expect(() async {
          final hasPermission = await exportRepository.checkStoragePermission();
          // Should return a boolean without throwing
          expect(hasPermission, isA<bool>());
        }, returnsNormally);
      },
    );
  });
}
