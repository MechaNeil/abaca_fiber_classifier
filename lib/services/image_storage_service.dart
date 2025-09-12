import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/stored_image.dart';
import '../../domain/entities/classification_result.dart';

/// Service for managing classified image storage organized by grade
///
/// This service handles saving classified images to folders organized
/// by their predicted grade (EF, G, H, I, JK, M1, S2, S3) and provides
/// functionality to export these organized folders.
class ImageStorageService {
  static const double _defaultConfidenceThreshold = 0.5;
  static const List<String> _supportedFormats = ['.jpg', '.jpeg', '.png'];

  /// All possible grades that can be classified
  static const List<String> _allGrades = [
    'EF',
    'G',
    'H',
    'I',
    'JK',
    'M1',
    'S2',
    'S3',
  ];

  /// Gets the base directory for storing organized images
  Future<Directory> getStorageBaseDirectory() async {
    try {
      // Try to use external storage first (for easier access)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final baseDir = Directory('${externalDir.path}/ClassifiedImages');
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
        return baseDir;
      }
    } catch (e) {
      debugPrint('Failed to access external storage: $e');
    }

    // Fallback to app documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${appDocDir.path}/ClassifiedImages');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  /// Gets the directory for a specific grade
  Future<Directory> getGradeDirectory(String grade) async {
    final baseDir = await getStorageBaseDirectory();
    final gradeDir = Directory('${baseDir.path}/$grade');
    if (!await gradeDir.exists()) {
      await gradeDir.create(recursive: true);
    }
    return gradeDir;
  }

  /// Creates all grade directories if they don't exist
  Future<void> initializeGradeDirectories() async {
    debugPrint('Initializing grade directories...');
    for (final grade in _allGrades) {
      await getGradeDirectory(grade);
      debugPrint('Created/verified directory for grade: $grade');
    }
  }

  /// Checks if an image should be stored based on confidence threshold
  bool shouldStoreImage(double confidence, {double? customThreshold}) {
    final threshold = customThreshold ?? _defaultConfidenceThreshold;
    return confidence > threshold;
  }

  /// Stores a classified image in the appropriate grade folder
  Future<StoredImage?> storeClassifiedImage({
    required String originalImagePath,
    required ClassificationResult result,
    int? userId,
    required String model,
    double? confidenceThreshold,
  }) async {
    try {
      debugPrint(
        'Service: Starting image storage for ${result.predictedLabel}',
      );
      debugPrint(
        'Service: Confidence: ${result.confidence}, threshold: $confidenceThreshold',
      );

      // Check if image should be stored based on confidence
      final shouldStore = shouldStoreImage(
        result.confidence,
        customThreshold: confidenceThreshold,
      );
      debugPrint('Service: Should store image: $shouldStore');

      if (!shouldStore) {
        debugPrint(
          'Service: Image not stored: confidence ${result.confidence} below threshold',
        );
        return null;
      }

      // Validate image file exists
      final originalFile = File(originalImagePath);
      debugPrint(
        'Service: Checking if original file exists: $originalImagePath',
      );

      if (!await originalFile.exists()) {
        debugPrint(
          'Service: Original image file does not exist: $originalImagePath',
        );
        throw Exception(
          'Original image file does not exist: $originalImagePath',
        );
      }

      // Validate image format
      final originalExtension = path.extension(originalImagePath).toLowerCase();
      debugPrint('Service: Image extension: $originalExtension');

      if (!_supportedFormats.contains(originalExtension)) {
        debugPrint('Service: Unsupported image format: $originalExtension');
        throw Exception('Unsupported image format: $originalExtension');
      }

      // Get grade directory
      debugPrint(
        'Service: Getting grade directory for ${result.predictedLabel}',
      );
      final gradeDir = await getGradeDirectory(result.predictedLabel);
      debugPrint('Service: Grade directory: ${gradeDir.path}');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = path.basenameWithoutExtension(originalImagePath);
      final fileName =
          '${originalName}_${timestamp}_${(result.confidence * 100).toInt()}pct$originalExtension';
      final storedPath = '${gradeDir.path}/$fileName';
      debugPrint('Service: Target file path: $storedPath');

      // Copy the image file
      debugPrint('Service: Copying image file...');
      await originalFile.copy(storedPath);

      // Verify file was copied and get size
      final storedFile = File(storedPath);
      if (!await storedFile.exists()) {
        debugPrint('Service: Failed to copy image to storage location');
        throw Exception('Failed to copy image to storage location');
      }

      final fileSize = await storedFile.length();
      debugPrint(
        'Service: Successfully stored image: $fileName in grade ${result.predictedLabel}, size: $fileSize bytes',
      );

      // Create StoredImage entity
      return StoredImage(
        originalImagePath: originalImagePath,
        storedImagePath: storedPath,
        grade: result.predictedLabel,
        confidence: result.confidence,
        probabilities: result.probabilities,
        timestamp: DateTime.now(),
        userId: userId,
        model: model,
        fileName: fileName,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      debugPrint('Error storing classified image: $e');
      throw Exception('Failed to store classified image: ${e.toString()}');
    }
  }

  /// Gets all images stored for a specific grade
  Future<List<File>> getImagesForGrade(String grade) async {
    try {
      final gradeDir = await getGradeDirectory(grade);
      if (!await gradeDir.exists()) {
        return [];
      }

      final files = <File>[];
      await for (final entity in gradeDir.list()) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (_supportedFormats.contains(extension)) {
            files.add(entity);
          }
        }
      }

      // Sort by modification time (newest first)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      return files;
    } catch (e) {
      debugPrint('Error getting images for grade $grade: $e');
      return [];
    }
  }

  /// Gets storage statistics for all grades
  Future<Map<String, int>> getStorageStatistics() async {
    final stats = <String, int>{};

    for (final grade in _allGrades) {
      final images = await getImagesForGrade(grade);
      stats[grade] = images.length;
    }

    return stats;
  }

  /// Gets total storage space used by all stored images
  Future<int> getTotalStorageUsed() async {
    int totalBytes = 0;

    for (final grade in _allGrades) {
      final images = await getImagesForGrade(grade);
      for (final image in images) {
        try {
          totalBytes += await image.length();
        } catch (e) {
          debugPrint('Error getting file size for ${image.path}: $e');
        }
      }
    }

    return totalBytes;
  }

  /// Deletes a stored image file
  Future<bool> deleteStoredImage(String storedImagePath) async {
    try {
      final file = File(storedImagePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted stored image: $storedImagePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting stored image: $e');
      return false;
    }
  }

  /// Clears all images for a specific grade
  Future<int> clearGradeImages(String grade) async {
    try {
      final images = await getImagesForGrade(grade);
      int deletedCount = 0;

      for (final image in images) {
        try {
          await image.delete();
          deletedCount++;
        } catch (e) {
          debugPrint('Failed to delete image ${image.path}: $e');
        }
      }

      debugPrint('Cleared $deletedCount images from grade $grade');
      return deletedCount;
    } catch (e) {
      debugPrint('Error clearing grade images: $e');
      return 0;
    }
  }

  /// Clears all stored images from all grades
  Future<int> clearAllStoredImages() async {
    int totalDeleted = 0;

    for (final grade in _allGrades) {
      totalDeleted += await clearGradeImages(grade);
    }

    return totalDeleted;
  }

  /// Gets the path where exports will be saved
  /// Uses same export directory logic as admin exports (AbacaFiberExports)
  Future<String> getExportPath() async {
    final exportDir = await _getExportDirectory();
    return exportDir.path;
  }

  /// Gets the appropriate export directory - prioritizes Downloads folder
  /// Always tries Downloads folder first, regardless of Android version
  Future<Directory> _getExportDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Always try Downloads directory first on Android
        final downloadsDir = await _getDownloadsDirectory();
        if (downloadsDir != null) {
          debugPrint(
            'Image exports using Downloads directory: ${downloadsDir.path}',
          );
          return downloadsDir;
        }

        // Fallback to external storage if Downloads not accessible
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final exportDir = Directory('${externalDir.path}/AbacaFiberExports');
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }
          debugPrint(
            'Image exports using external storage fallback: ${exportDir.path}',
          );
          return exportDir;
        }
      }

      // Non-Android platforms or final fallback
      final appDocDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${appDocDir.path}/AbacaFiberExports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      debugPrint(
        'Image exports using app documents directory: ${exportDir.path}',
      );
      return exportDir;
    } catch (e) {
      debugPrint('Error getting export directory: $e');

      // Final fallback to app documents
      final appDocDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${appDocDir.path}/AbacaFiberExports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir;
    }
  }

  /// Attempt to get Downloads directory - tries all Android versions
  /// More aggressive approach to access Downloads folder
  Future<Directory?> _getDownloadsDirectory() async {
    if (!Platform.isAndroid) return null;

    try {
      // Try common Downloads folder paths
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
        '/storage/self/primary/Download',
        '/storage/emulated/0/Downloads', // Also try with 's'
        '/sdcard/Downloads',
      ];

      for (final path in commonPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          final exportDir = Directory('$path/AbacaFiberExports');
          try {
            if (!await exportDir.exists()) {
              await exportDir.create(recursive: true);
            }
            // Test write access
            final testFile = File('${exportDir.path}/.test_write');
            await testFile.writeAsString('test');
            await testFile.delete();

            debugPrint(
              'Successfully accessed Downloads directory: ${exportDir.path}',
            );
            return exportDir;
          } catch (e) {
            debugPrint(
              'Downloads directory exists but not writable: $path - $e',
            );
            continue;
          }
        }
      }

      debugPrint('No accessible Downloads directory found');
      return null;
    } catch (e) {
      debugPrint('Failed to access Downloads directory: $e');
      return null;
    }
  }

  /// Gets a human-readable description of the storage and export locations
  Future<String> getStorageLocationDescription() async {
    final baseDir = await getStorageBaseDirectory();
    final exportDir = await _getExportDirectory();
    final storagePath = baseDir.path;
    final exportPath = exportDir.path;

    if (Platform.isAndroid) {
      String storageDesc;
      String exportDesc;

      if (storagePath.contains('external')) {
        storageDesc =
            'External Storage/ClassifiedImages/\n(Accessible via file manager)';
      } else {
        storageDesc = 'App Documents/ClassifiedImages/\n(Internal app storage)';
      }

      if (exportPath.contains('Download')) {
        exportDesc = 'Downloads/AbacaFiberExports/\n(Downloads folder)';
      } else if (exportPath.contains('external')) {
        exportDesc = 'External Storage/AbacaFiberExports/\n(Fallback location)';
      } else {
        exportDesc = 'App Documents/AbacaFiberExports/\n(Fallback location)';
      }

      return 'Images: $storageDesc\nExports: $exportDesc';
    } else if (Platform.isIOS) {
      return 'Images: App Documents/ClassifiedImages/\nExports: App Documents/AbacaFiberExports/';
    }

    return 'Images: Local Storage/ClassifiedImages/\nExports: Local Storage/AbacaFiberExports/';
  }

  /// Validates that all required directories exist and are accessible
  Future<bool> validateStorageSetup() async {
    try {
      await initializeGradeDirectories();
      final baseDir = await getStorageBaseDirectory();
      return await baseDir.exists();
    } catch (e) {
      debugPrint('Storage validation failed: $e');
      return false;
    }
  }
}
