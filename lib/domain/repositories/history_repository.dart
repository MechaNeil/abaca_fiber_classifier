import '../entities/classification_history.dart';

/// Repository interface for classification history operations
///
/// This repository defines the contract for managing classification history
/// data persistence. It follows the repository pattern to decouple
/// business logic from data access logic.
abstract class HistoryRepository {
  /// Saves a classification history record
  ///
  /// Parameters:
  /// - [history]: The classification history to save
  ///
  /// Returns: The ID of the saved history record
  Future<int> saveHistory(ClassificationHistory history);

  /// Retrieves all classification history records
  ///
  /// Parameters:
  /// - [limit]: Optional limit for the number of records to retrieve
  /// - [offset]: Optional offset for pagination
  ///
  /// Returns: A list of classification history records
  Future<List<ClassificationHistory>> getAllHistory({int? limit, int? offset});

  /// Retrieves history records for a specific user
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
  });

  /// Retrieves recent classification history records
  ///
  /// Parameters:
  /// - [limit]: Number of recent records to retrieve (default: 10)
  ///
  /// Returns: A list of recent classification history records
  Future<List<ClassificationHistory>> getRecentHistory({int limit = 10});

  /// Retrieves classification history records for today
  ///
  /// Returns: A list of classification history records from today
  Future<List<ClassificationHistory>> getTodayHistory();

  /// Retrieves history records by grade/classification
  ///
  /// Parameters:
  /// - [grade]: The grade to filter by (e.g., 'GRADE_S2', 'GRADE_1')
  /// - [limit]: Optional limit for the number of records to retrieve
  ///
  /// Returns: A list of classification history records with the specified grade
  Future<List<ClassificationHistory>> getHistoryByGrade(
    String grade, {
    int? limit,
  });

  /// Deletes a specific history record
  ///
  /// Parameters:
  /// - [id]: The ID of the history record to delete
  ///
  /// Returns: True if the record was deleted successfully
  Future<bool> deleteHistory(int id);

  /// Deletes all history records for a specific user
  ///
  /// Parameters:
  /// - [userId]: The user ID whose history to delete
  ///
  /// Returns: The number of records deleted
  Future<int> deleteUserHistory(int userId);

  /// Clears all classification history
  ///
  /// Returns: The number of records deleted
  Future<int> clearAllHistory();

  /// Gets the total count of history records
  ///
  /// Returns: The total number of history records
  Future<int> getHistoryCount();

  /// Gets history statistics (count by grade)
  ///
  /// Returns: A map with grade as key and count as value
  Future<Map<String, int>> getHistoryStatistics();
}
