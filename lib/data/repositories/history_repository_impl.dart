import 'package:sqflite/sqflite.dart';
import '../../domain/entities/classification_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../../features/auth/data/database_service.dart';

/// Implementation of the HistoryRepository interface
///
/// This class provides concrete implementations for all history-related
/// database operations using SQLite through the sqflite package.
class HistoryRepositoryImpl implements HistoryRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  Future<int> saveHistory(ClassificationHistory history) async {
    try {
      final db = await _databaseService.database;
      return await db.insert(
        'classification_history',
        history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to save history: ${e.toString()}');
    }
  }

  @override
  Future<List<ClassificationHistory>> getAllHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'classification_history',
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => ClassificationHistory.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to retrieve history: ${e.toString()}');
    }
  }

  @override
  Future<List<ClassificationHistory>> getHistoryByUser(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'classification_history',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => ClassificationHistory.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to retrieve user history: ${e.toString()}');
    }
  }

  @override
  Future<List<ClassificationHistory>> getRecentHistory({int limit = 10}) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'classification_history',
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((map) => ClassificationHistory.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to retrieve recent history: ${e.toString()}');
    }
  }

  @override
  Future<List<ClassificationHistory>> getTodayHistory() async {
    try {
      final db = await _databaseService.database;

      // Get today's date in the format stored in the database
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        'classification_history',
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [
          todayStart.millisecondsSinceEpoch,
          todayEnd.millisecondsSinceEpoch,
        ],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => ClassificationHistory.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to retrieve today\'s history: ${e.toString()}');
    }
  }

  @override
  Future<List<ClassificationHistory>> getHistoryByGrade(
    String grade, {
    int? limit,
  }) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'classification_history',
        where: 'predictedLabel = ?',
        whereArgs: [grade],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((map) => ClassificationHistory.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to retrieve history by grade: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteHistory(int id) async {
    try {
      final db = await _databaseService.database;
      final result = await db.delete(
        'classification_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete history: ${e.toString()}');
    }
  }

  @override
  Future<int> deleteUserHistory(int userId) async {
    try {
      final db = await _databaseService.database;
      return await db.delete(
        'classification_history',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Failed to delete user history: ${e.toString()}');
    }
  }

  @override
  Future<int> clearAllHistory() async {
    try {
      final db = await _databaseService.database;
      return await db.delete('classification_history');
    } catch (e) {
      throw Exception('Failed to clear all history: ${e.toString()}');
    }
  }

  @override
  Future<int> getHistoryCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM classification_history',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get history count: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, int>> getHistoryStatistics() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('''
        SELECT predictedLabel, COUNT(*) as count 
        FROM classification_history 
        GROUP BY predictedLabel
        ORDER BY count DESC
      ''');

      final Map<String, int> statistics = {};
      for (final row in result) {
        statistics[row['predictedLabel'] as String] = row['count'] as int;
      }

      return statistics;
    } catch (e) {
      throw Exception('Failed to get history statistics: ${e.toString()}');
    }
  }
}
