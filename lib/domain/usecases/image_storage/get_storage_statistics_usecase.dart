import '../../repositories/image_storage_repository.dart';

/// Use case for getting storage statistics and insights
class GetStorageStatisticsUseCase {
  final ImageStorageRepository _repository;

  GetStorageStatisticsUseCase(this._repository);

  /// Gets comprehensive storage statistics
  Future<Map<String, dynamic>> execute() async {
    try {
      return await _repository.getStorageStatistics();
    } catch (e) {
      throw Exception('Failed to get storage statistics: ${e.toString()}');
    }
  }

  /// Gets image count by grade
  Future<Map<String, int>> getImageCountByGrade() async {
    try {
      return await _repository.getImageCountByGrade();
    } catch (e) {
      throw Exception('Failed to get image count by grade: ${e.toString()}');
    }
  }

  /// Gets total stored images count
  Future<int> getTotalCount() async {
    try {
      return await _repository.getTotalStoredImagesCount();
    } catch (e) {
      throw Exception(
        'Failed to get total stored images count: ${e.toString()}',
      );
    }
  }

  /// Gets total storage size in bytes
  Future<int> getTotalSizeBytes() async {
    try {
      return await _repository.getTotalStorageSizeBytes();
    } catch (e) {
      throw Exception('Failed to get total storage size: ${e.toString()}');
    }
  }

  /// Gets human-readable storage size
  Future<String> getTotalSizeFormatted() async {
    try {
      final bytes = await getTotalSizeBytes();
      return _formatBytes(bytes);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Gets recent activity (images stored in last N days)
  Future<int> getRecentActivity({int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final now = DateTime.now();

      final recentImages = await _repository.getStoredImagesByDateRange(
        cutoffDate,
        now,
      );

      return recentImages.length;
    } catch (e) {
      throw Exception('Failed to get recent activity: ${e.toString()}');
    }
  }

  /// Gets storage insights with recommendations
  Future<Map<String, dynamic>> getStorageInsights() async {
    try {
      final stats = await execute();
      final totalCount = stats['totalCount'] as int;
      final totalSize = stats['totalSizeBytes'] as int;
      final gradeStats =
          stats['gradeStatistics'] as Map<String, Map<String, dynamic>>;

      // Calculate average file size
      final avgFileSize = totalCount > 0 ? totalSize / totalCount : 0;

      // Find most and least common grades
      String? mostCommonGrade;
      String? leastCommonGrade;
      int maxCount = 0;
      int minCount = 999999;

      for (final entry in gradeStats.entries) {
        final count = entry.value['count'] as int;
        if (count > maxCount) {
          maxCount = count;
          mostCommonGrade = entry.key;
        }
        if (count < minCount && count > 0) {
          minCount = count;
          leastCommonGrade = entry.key;
        }
      }

      // Generate recommendations
      final recommendations = <String>[];

      if (totalSize > 100 * 1024 * 1024) {
        // > 100MB
        recommendations.add('Consider cleaning up old images to free space');
      }

      if (totalCount > 1000) {
        recommendations.add(
          'Large number of stored images - consider archiving older ones',
        );
      }

      if (avgFileSize > 5 * 1024 * 1024) {
        // > 5MB average
        recommendations.add(
          'Images are quite large - consider image compression',
        );
      }

      return {
        'totalCount': totalCount,
        'totalSizeBytes': totalSize,
        'totalSizeFormatted': _formatBytes(totalSize),
        'averageFileSize': avgFileSize,
        'averageFileSizeFormatted': _formatBytes(avgFileSize.round()),
        'mostCommonGrade': mostCommonGrade,
        'leastCommonGrade': leastCommonGrade,
        'gradeDistribution': gradeStats,
        'recommendations': recommendations,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get storage insights: ${e.toString()}');
    }
  }

  /// Formats bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
