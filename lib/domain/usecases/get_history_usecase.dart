import '../entities/classification_history.dart';
import '../repositories/history_repository.dart';

/// Use case for retrieving classification history
///
/// This use case encapsulates the business logic for retrieving
/// classification history records from the database.
class GetHistoryUseCase {
  final HistoryRepository _historyRepository;

  GetHistoryUseCase(this._historyRepository);

  /// Gets all classification history records
  ///
  /// Parameters:
  /// - [limit]: Optional limit for the number of records to retrieve
  /// - [offset]: Optional offset for pagination
  ///
  /// Returns: A list of classification history records
  Future<List<ClassificationHistory>> getAllHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      return await _historyRepository.getAllHistory(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to retrieve history: ${e.toString()}');
    }
  }

  /// Gets recent classification history records
  ///
  /// Parameters:
  /// - [limit]: Number of recent records to retrieve (default: 10)
  ///
  /// Returns: A list of recent classification history records
  Future<List<ClassificationHistory>> getRecentHistory({int limit = 10}) async {
    try {
      if (limit <= 0) {
        throw Exception('Limit must be greater than 0');
      }

      return await _historyRepository.getRecentHistory(limit: limit);
    } catch (e) {
      throw Exception('Failed to retrieve recent history: ${e.toString()}');
    }
  }

  /// Gets history records for a specific user
  ///
  /// Parameters:
  /// - [userId]: The user ID to filter by
  /// - [limit]: Optional limit for the number of records to retrieve
  /// - [offset]: Optional offset for pagination
  ///
  /// Returns: A list of classification history records for the user
  Future<List<ClassificationHistory>> getHistoryByUser(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      return await _historyRepository.getHistoryByUser(
        userId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to retrieve user history: ${e.toString()}');
    }
  }

  /// Gets history records by grade/classification
  ///
  /// Parameters:
  /// - [grade]: The grade to filter by (e.g., 'GRADE_S2', 'GRADE_1')
  /// - [limit]: Optional limit for the number of records to retrieve
  ///
  /// Returns: A list of classification history records with the specified grade
  Future<List<ClassificationHistory>> getHistoryByGrade(
    String grade, {
    int? limit,
  }) async {
    try {
      if (grade.trim().isEmpty) {
        throw Exception('Grade cannot be empty');
      }

      return await _historyRepository.getHistoryByGrade(grade, limit: limit);
    } catch (e) {
      throw Exception('Failed to retrieve history by grade: ${e.toString()}');
    }
  }

  /// Gets history statistics (count by grade)
  ///
  /// Returns: A map with grade as key and count as value
  Future<Map<String, int>> getHistoryStatistics() async {
    try {
      return await _historyRepository.getHistoryStatistics();
    } catch (e) {
      throw Exception('Failed to retrieve history statistics: ${e.toString()}');
    }
  }

  /// Gets the total count of history records
  ///
  /// Returns: The total number of history records
  Future<int> getHistoryCount() async {
    try {
      return await _historyRepository.getHistoryCount();
    } catch (e) {
      throw Exception('Failed to retrieve history count: ${e.toString()}');
    }
  }
}
