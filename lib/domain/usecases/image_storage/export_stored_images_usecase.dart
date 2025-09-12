import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';

import '../../repositories/image_storage_repository.dart';
import '../../../services/image_storage_service.dart';

/// Use case for exporting stored images organized by grade
class ExportStoredImagesUseCase {
  final ImageStorageRepository _repository;
  final ImageStorageService _storageService;

  ExportStoredImagesUseCase(this._repository, this._storageService);

  /// Exports all stored images in their grade folders as a ZIP file
  Future<String> exportAsZip({String? customFileName}) async {
    try {
      debugPrint('Starting export of stored images as ZIP...');

      // Get all stored images grouped by grade
      final imagesByGrade = await _repository.getStoredImagesGroupedByGrade();

      if (imagesByGrade.isEmpty) {
        throw Exception('No stored images found to export');
      }

      // Create archive
      final archive = Archive();
      int totalFilesAdded = 0;

      // Add images from each grade folder
      for (final entry in imagesByGrade.entries) {
        final grade = entry.key;
        final images = entry.value;

        debugPrint('Processing grade $grade with ${images.length} images');

        for (final storedImage in images) {
          try {
            final file = File(storedImage.storedImagePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();

              // Create archive file path: Grade/filename
              final archivePath = '$grade/${storedImage.fileName}';
              final archiveFile = ArchiveFile(archivePath, bytes.length, bytes);
              archive.addFile(archiveFile);
              totalFilesAdded++;
            } else {
              debugPrint(
                'Warning: File not found: ${storedImage.storedImagePath}',
              );
            }
          } catch (e) {
            debugPrint('Error adding file ${storedImage.fileName}: $e');
          }
        }
      }

      if (totalFilesAdded == 0) {
        throw Exception('No valid image files found to export');
      }

      // Create metadata file
      final metadata = await _createMetadataContent(imagesByGrade);
      final metadataFile = ArchiveFile(
        'export_metadata.txt',
        metadata.length,
        metadata.codeUnits,
      );
      archive.addFile(metadataFile);

      // Encode archive
      final zipData = ZipEncoder().encode(archive);

      // Save ZIP file
      final exportPath = await _storageService.getExportPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          customFileName ?? 'classified_images_export_$timestamp.zip';
      final zipFilePath = '$exportPath/$fileName';

      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipData);

      debugPrint(
        'Successfully exported $totalFilesAdded images to: $zipFilePath',
      );
      return zipFilePath;
    } catch (e) {
      debugPrint('Error exporting stored images as ZIP: $e');
      throw Exception('Failed to export stored images: ${e.toString()}');
    }
  }

  /// Exports images for a specific grade as a ZIP file
  Future<String> exportGradeAsZip(
    String grade, {
    String? customFileName,
  }) async {
    try {
      debugPrint('Starting export of grade $grade as ZIP...');

      final images = await _repository.getStoredImagesByGrade(grade);

      if (images.isEmpty) {
        throw Exception('No stored images found for grade $grade');
      }

      // Create archive
      final archive = Archive();
      int totalFilesAdded = 0;

      for (final storedImage in images) {
        try {
          final file = File(storedImage.storedImagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final archiveFile = ArchiveFile(
              storedImage.fileName,
              bytes.length,
              bytes,
            );
            archive.addFile(archiveFile);
            totalFilesAdded++;
          }
        } catch (e) {
          debugPrint('Error adding file ${storedImage.fileName}: $e');
        }
      }

      if (totalFilesAdded == 0) {
        throw Exception('No valid image files found for grade $grade');
      }

      // Create grade-specific metadata
      final metadata = await _createGradeMetadataContent(grade, images);
      final metadataFile = ArchiveFile(
        'grade_${grade}_metadata.txt',
        metadata.length,
        metadata.codeUnits,
      );
      archive.addFile(metadataFile);

      // Encode archive
      final zipData = ZipEncoder().encode(archive);

      // Save ZIP file
      final exportPath = await _storageService.getExportPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'grade_${grade}_export_$timestamp.zip';
      final zipFilePath = '$exportPath/$fileName';

      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipData);

      debugPrint(
        'Successfully exported $totalFilesAdded images for grade $grade to: $zipFilePath',
      );
      return zipFilePath;
    } catch (e) {
      debugPrint('Error exporting grade $grade as ZIP: $e');
      throw Exception('Failed to export grade $grade: ${e.toString()}');
    }
  }

  /// Copies all grade folders to a destination directory
  Future<String> exportToDirectory({String? customDirectoryName}) async {
    try {
      debugPrint('Starting export of stored images to directory...');

      final imagesByGrade = await _repository.getStoredImagesGroupedByGrade();

      if (imagesByGrade.isEmpty) {
        throw Exception('No stored images found to export');
      }

      // Create export directory
      final exportBasePath = await _storageService.getExportPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dirName =
          customDirectoryName ?? 'classified_images_export_$timestamp';
      final exportDirPath = '$exportBasePath/$dirName';
      final exportDir = Directory(exportDirPath);

      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      await exportDir.create(recursive: true);

      int totalFilesCopied = 0;

      // Copy images organized by grade
      for (final entry in imagesByGrade.entries) {
        final grade = entry.key;
        final images = entry.value;

        // Create grade subdirectory
        final gradeDir = Directory('$exportDirPath/$grade');
        await gradeDir.create(recursive: true);

        debugPrint('Copying ${images.length} images for grade $grade');

        for (final storedImage in images) {
          try {
            final sourceFile = File(storedImage.storedImagePath);
            if (await sourceFile.exists()) {
              final destPath = '${gradeDir.path}/${storedImage.fileName}';
              await sourceFile.copy(destPath);
              totalFilesCopied++;
            }
          } catch (e) {
            debugPrint('Error copying file ${storedImage.fileName}: $e');
          }
        }
      }

      if (totalFilesCopied == 0) {
        throw Exception('No valid image files found to export');
      }

      // Create metadata file
      final metadata = await _createMetadataContent(imagesByGrade);
      final metadataFile = File('$exportDirPath/export_metadata.txt');
      await metadataFile.writeAsString(metadata);

      debugPrint(
        'Successfully exported $totalFilesCopied images to: $exportDirPath',
      );
      return exportDirPath;
    } catch (e) {
      debugPrint('Error exporting stored images to directory: $e');
      throw Exception('Failed to export stored images: ${e.toString()}');
    }
  }

  /// Gets export preview information
  Future<Map<String, dynamic>> getExportPreview() async {
    try {
      final imagesByGrade = await _repository.getStoredImagesGroupedByGrade();

      final gradeInfo = <String, Map<String, dynamic>>{};
      int totalFiles = 0;
      int totalSize = 0;

      for (final entry in imagesByGrade.entries) {
        final grade = entry.key;
        final images = entry.value;

        int gradeSize = 0;
        for (final image in images) {
          gradeSize += image.fileSizeBytes;
        }

        gradeInfo[grade] = {
          'count': images.length,
          'sizeBytes': gradeSize,
          'sizeFormatted': _formatBytes(gradeSize),
        };

        totalFiles += images.length;
        totalSize += gradeSize;
      }

      return {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSize,
        'totalSizeFormatted': _formatBytes(totalSize),
        'gradeInfo': gradeInfo,
        'estimatedZipSize': _formatBytes(
          (totalSize * 0.7).round(),
        ), // Rough estimate
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get export preview: ${e.toString()}');
    }
  }

  /// Verifies export functionality by checking requirements
  Future<Map<String, dynamic>> verifyExportCapability() async {
    try {
      debugPrint('Verifying export functionality...');

      // Check if we have stored images
      final imagesByGrade = await _repository.getStoredImagesGroupedByGrade();
      final totalImages = imagesByGrade.values.fold(
        0,
        (sum, images) => sum + images.length,
      );

      // Check export path accessibility
      final exportPath = await _storageService.getExportPath();
      final exportDir = Directory(exportPath);
      final canWrite =
          await exportDir.exists() || await _canCreateDirectory(exportPath);

      // Check archive package availability
      bool archiveSupport = true;
      try {
        final testArchive = Archive();
        ZipEncoder().encode(testArchive); // Test if archive functions work
      } catch (e) {
        archiveSupport = false;
        debugPrint('Archive package test failed: $e');
      }

      final result = {
        'totalStoredImages': totalImages,
        'availableGrades': imagesByGrade.keys.toList(),
        'exportPathAccessible': canWrite,
        'exportPath': exportPath,
        'archiveSupport': archiveSupport,
        'readyForExport': totalImages > 0 && canWrite && archiveSupport,
      };

      debugPrint('Export verification result: $result');
      return result;
    } catch (e) {
      debugPrint('Export verification failed: $e');
      return {'error': e.toString(), 'readyForExport': false};
    }
  }

  /// Helper method to check if we can create a directory
  Future<bool> _canCreateDirectory(String path) async {
    try {
      final testDir = Directory(path);
      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('Cannot create directory $path: $e');
      return false;
    }
  }

  /// Creates metadata content for export
  Future<String> _createMetadataContent(
    Map<String, List<dynamic>> imagesByGrade,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('Abaca Fiber Classifier - Stored Images Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    int totalImages = 0;
    for (final entry in imagesByGrade.entries) {
      totalImages += entry.value.length;
    }

    buffer.writeln('Summary:');
    buffer.writeln('Total Images: $totalImages');
    buffer.writeln('Total Grades: ${imagesByGrade.length}');
    buffer.writeln('');

    buffer.writeln('Grade Distribution:');
    for (final entry in imagesByGrade.entries) {
      final grade = entry.key;
      final count = entry.value.length;
      buffer.writeln('  $grade: $count images');
    }
    buffer.writeln('');

    buffer.writeln('File Organization:');
    buffer.writeln(
      '  Each grade has its own folder containing classified images',
    );
    buffer.writeln(
      '  Filenames include original name, timestamp, and confidence percentage',
    );
    buffer.writeln('  Example: image_1234567890_85pct.jpg (85% confidence)');
    buffer.writeln('');

    buffer.writeln('Quality Information:');
    buffer.writeln(
      '  All exported images met the confidence threshold for storage',
    );
    buffer.writeln(
      '  Images are organized by their highest confidence prediction',
    );

    return buffer.toString();
  }

  /// Creates grade-specific metadata content
  Future<String> _createGradeMetadataContent(
    String grade,
    List<dynamic> images,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('Abaca Fiber Classifier - Grade $grade Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Grade: $grade');
    buffer.writeln('Total Images: ${images.length}');
    buffer.writeln('');

    if (images.isNotEmpty) {
      // Calculate statistics
      final confidences = images
          .map((img) => img.confidence as double)
          .toList();
      final avgConfidence =
          confidences.reduce((a, b) => a + b) / confidences.length;
      final maxConfidence = confidences.reduce((a, b) => a > b ? a : b);
      final minConfidence = confidences.reduce((a, b) => a < b ? a : b);

      buffer.writeln('Confidence Statistics:');
      buffer.writeln('  Average: ${(avgConfidence * 100).toStringAsFixed(1)}%');
      buffer.writeln('  Highest: ${(maxConfidence * 100).toStringAsFixed(1)}%');
      buffer.writeln('  Lowest: ${(minConfidence * 100).toStringAsFixed(1)}%');
    }

    return buffer.toString();
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
