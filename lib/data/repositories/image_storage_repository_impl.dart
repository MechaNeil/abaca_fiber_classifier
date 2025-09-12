import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/stored_image.dart';
import '../../domain/repositories/image_storage_repository.dart';
import '../../features/auth/data/database_service.dart';

/// Implementation of ImageStorageRepository for SQLite database
class ImageStorageRepositoryImpl implements ImageStorageRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  static const String _tableName = 'stored_images';

  /// Initialize the stored_images table
  static Future<void> initializeTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        originalImagePath TEXT NOT NULL,
        storedImagePath TEXT NOT NULL UNIQUE,
        grade TEXT NOT NULL,
        confidence REAL NOT NULL,
        probabilities TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        userId INTEGER,
        model TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileSizeBytes INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stored_images_grade ON $_tableName(grade)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stored_images_user ON $_tableName(userId)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stored_images_timestamp ON $_tableName(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stored_images_confidence ON $_tableName(confidence)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stored_images_model ON $_tableName(model)
    ''');
  }

  @override
  Future<int> saveStoredImage(StoredImage storedImage) async {
    try {
      final db = await _databaseService.database;
      debugPrint('Repository: Attempting to save image to database');
      debugPrint('Repository: StoredImage data: ${storedImage.toMap()}');

      final id = await db.insert(
        _tableName,
        storedImage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Repository: Saved stored image to database with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Repository: Error saving stored image: $e');
      debugPrint('Repository: Stack trace: ${StackTrace.current}');

      // Check if it's a table not found error
      if (e.toString().contains('no such table')) {
        debugPrint(
          'Repository: Table $_tableName does not exist, attempting to create it',
        );
        try {
          final db = await _databaseService.database;
          await initializeTable(db);
          debugPrint('Repository: Table created, retrying insert');
          final id = await db.insert(
            _tableName,
            storedImage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          debugPrint(
            'Repository: Saved stored image to database with ID: $id after table creation',
          );
          return id;
        } catch (retryError) {
          debugPrint(
            'Repository: Failed to create table and retry: $retryError',
          );
          throw Exception(
            'Failed to save stored image after table creation: ${retryError.toString()}',
          );
        }
      }

      throw Exception('Failed to save stored image: ${e.toString()}');
    }
  }

  @override
  Future<StoredImage?> getStoredImageById(int id) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return StoredImage.fromMap(maps.first);
    } catch (e) {
      debugPrint('Error getting stored image by ID: $e');
      return null;
    }
  }

  @override
  Future<List<StoredImage>> getAllStoredImages() async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(_tableName, orderBy: 'timestamp DESC');

      return maps.map((map) => StoredImage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting all stored images: $e');
      return [];
    }
  }

  @override
  Future<bool> updateStoredImage(StoredImage storedImage) async {
    try {
      if (storedImage.id == null) return false;

      final db = await _databaseService.database;
      final count = await db.update(
        _tableName,
        storedImage.toMap(),
        where: 'id = ?',
        whereArgs: [storedImage.id],
      );

      return count > 0;
    } catch (e) {
      debugPrint('Error updating stored image: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteStoredImage(int id) async {
    try {
      final db = await _databaseService.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      return count > 0;
    } catch (e) {
      debugPrint('Error deleting stored image: $e');
      return false;
    }
  }

  @override
  Future<List<StoredImage>> getStoredImagesByGrade(String grade) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        _tableName,
        where: 'grade = ?',
        whereArgs: [grade],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => StoredImage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting stored images by grade: $e');
      return [];
    }
  }

  @override
  Future<Map<String, int>> getImageCountByGrade() async {
    try {
      final db = await _databaseService.database;
      final maps = await db.rawQuery('''
        SELECT grade, COUNT(*) as count 
        FROM $_tableName 
        GROUP BY grade 
        ORDER BY grade
      ''');

      final result = <String, int>{};
      for (final map in maps) {
        result[map['grade'] as String] = map['count'] as int;
      }

      return result;
    } catch (e) {
      debugPrint('Error getting image count by grade: $e');
      return {};
    }
  }

  @override
  Future<List<StoredImage>> getStoredImagesByUser(int userId) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        _tableName,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => StoredImage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting stored images by user: $e');
      return [];
    }
  }

  @override
  Future<List<StoredImage>> getStoredImagesByModel(String model) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        _tableName,
        where: 'model = ?',
        whereArgs: [model],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => StoredImage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting stored images by model: $e');
      return [];
    }
  }

  @override
  Future<List<StoredImage>> getStoredImagesByConfidenceRange(
    double minConfidence,
    double maxConfidence,
  ) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        _tableName,
        where: 'confidence >= ? AND confidence <= ?',
        whereArgs: [minConfidence, maxConfidence],
        orderBy: 'confidence DESC, timestamp DESC',
      );

      return maps.map((map) => StoredImage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting stored images by confidence range: $e');
      return [];
    }
  }

  @override
  Future<List<StoredImage>> getStoredImagesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        _tableName,
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => StoredImage.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting stored images by date range: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getStorageStatistics() async {
    try {
      final db = await _databaseService.database;

      // Get total count
      final totalCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      final totalCount = totalCountResult.first['count'] as int;

      // Get total file size
      final totalSizeResult = await db.rawQuery(
        'SELECT SUM(fileSizeBytes) as totalSize FROM $_tableName',
      );
      final totalSize = (totalSizeResult.first['totalSize'] as int?) ?? 0;

      // Get count by grade
      final gradeCountResult = await db.rawQuery('''
        SELECT grade, COUNT(*) as count, SUM(fileSizeBytes) as size 
        FROM $_tableName 
        GROUP BY grade 
        ORDER BY grade
      ''');

      final gradeStats = <String, Map<String, dynamic>>{};
      for (final map in gradeCountResult) {
        gradeStats[map['grade'] as String] = {
          'count': map['count'] as int,
          'size': (map['size'] as int?) ?? 0,
        };
      }

      // Get recent activity (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count 
        FROM $_tableName 
        WHERE timestamp >= ?
      ''',
        [sevenDaysAgo.millisecondsSinceEpoch],
      );
      final recentCount = recentResult.first['count'] as int;

      return {
        'totalCount': totalCount,
        'totalSizeBytes': totalSize,
        'gradeStatistics': gradeStats,
        'recentActivity': recentCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting storage statistics: $e');
      return {
        'totalCount': 0,
        'totalSizeBytes': 0,
        'gradeStatistics': <String, Map<String, dynamic>>{},
        'recentActivity': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<int> getTotalStoredImagesCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('Error getting total stored images count: $e');
      return 0;
    }
  }

  @override
  Future<int> getTotalStorageSizeBytes() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT SUM(fileSizeBytes) as totalSize FROM $_tableName',
      );
      return (result.first['totalSize'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Error getting total storage size: $e');
      return 0;
    }
  }

  @override
  Future<int> deleteStoredImagesByGrade(String grade) async {
    try {
      final db = await _databaseService.database;
      return await db.delete(
        _tableName,
        where: 'grade = ?',
        whereArgs: [grade],
      );
    } catch (e) {
      debugPrint('Error deleting stored images by grade: $e');
      return 0;
    }
  }

  @override
  Future<int> deleteStoredImagesByUser(int userId) async {
    try {
      final db = await _databaseService.database;
      return await db.delete(
        _tableName,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Error deleting stored images by user: $e');
      return 0;
    }
  }

  @override
  Future<int> deleteStoredImagesByModel(String model) async {
    try {
      final db = await _databaseService.database;
      return await db.delete(
        _tableName,
        where: 'model = ?',
        whereArgs: [model],
      );
    } catch (e) {
      debugPrint('Error deleting stored images by model: $e');
      return 0;
    }
  }

  @override
  Future<int> deleteOldStoredImages(DateTime cutoffDate) async {
    try {
      final db = await _databaseService.database;
      return await db.delete(
        _tableName,
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.millisecondsSinceEpoch],
      );
    } catch (e) {
      debugPrint('Error deleting old stored images: $e');
      return 0;
    }
  }

  @override
  Future<int> deleteAllStoredImages() async {
    try {
      final db = await _databaseService.database;
      return await db.delete(_tableName);
    } catch (e) {
      debugPrint('Error deleting all stored images: $e');
      return 0;
    }
  }

  @override
  Future<bool> verifyStoredImageExists(int id) async {
    try {
      final storedImage = await getStoredImageById(id);
      if (storedImage == null) return false;

      final file = File(storedImage.storedImagePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error verifying stored image exists: $e');
      return false;
    }
  }

  @override
  Future<List<StoredImage>> findOrphanedDatabaseRecords() async {
    try {
      final allImages = await getAllStoredImages();
      final orphaned = <StoredImage>[];

      for (final image in allImages) {
        final file = File(image.storedImagePath);
        if (!await file.exists()) {
          orphaned.add(image);
        }
      }

      return orphaned;
    } catch (e) {
      debugPrint('Error finding orphaned database records: $e');
      return [];
    }
  }

  @override
  Future<int> cleanupOrphanedRecords() async {
    try {
      final orphaned = await findOrphanedDatabaseRecords();
      int deletedCount = 0;

      for (final image in orphaned) {
        if (image.id != null) {
          final deleted = await deleteStoredImage(image.id!);
          if (deleted) deletedCount++;
        }
      }

      debugPrint('Cleaned up $deletedCount orphaned database records');
      return deletedCount;
    } catch (e) {
      debugPrint('Error cleaning up orphaned records: $e');
      return 0;
    }
  }

  @override
  Future<List<StoredImage>> getStoredImagesForExport() async {
    try {
      return await getAllStoredImages();
    } catch (e) {
      debugPrint('Error getting stored images for export: $e');
      return [];
    }
  }

  @override
  Future<Map<String, List<StoredImage>>> getStoredImagesGroupedByGrade() async {
    try {
      final allImages = await getAllStoredImages();
      final grouped = <String, List<StoredImage>>{};

      for (final image in allImages) {
        if (!grouped.containsKey(image.grade)) {
          grouped[image.grade] = [];
        }
        grouped[image.grade]!.add(image);
      }

      // Sort each group by confidence (highest first)
      for (final grade in grouped.keys) {
        grouped[grade]!.sort((a, b) => b.confidence.compareTo(a.confidence));
      }

      return grouped;
    } catch (e) {
      debugPrint('Error grouping stored images by grade: $e');
      return {};
    }
  }
}
