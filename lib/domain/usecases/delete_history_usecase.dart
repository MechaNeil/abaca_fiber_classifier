import '../repositories/history_repository.dart';

/// Use case for deleting classification history
///
/// This use case encapsulates the business logic for deleting
/// classification history records from the database.
class DeleteHistoryUseCase {
  final HistoryRepository _historyRepository;

  DeleteHistoryUseCase(this._historyRepository);

  /// Deletes a specific history record
  ///
  /// Parameters:
  /// - [id]: The ID of the history record to delete
  ///
  /// Returns: True if the record was deleted successfully
  ///
  /// Throws:
  /// - [Exception] if the delete operation fails
  Future<bool> deleteHistory(int id) async {
    try {
      if (id <= 0) {
        throw Exception('Invalid history ID');
      }

      return await _historyRepository.deleteHistory(id);
    } catch (e) {
      throw Exception('Failed to delete history record: ${e.toString()}');
    }
  }

  /// Deletes all history records for a specific user
  ///
  /// Parameters:
  /// - [userId]: The user ID whose history to delete
  ///
  /// Returns: The number of records deleted
  ///
  /// Throws:
  /// - [Exception] if the delete operation fails
  Future<int> deleteUserHistory(int userId) async {
    try {
      if (userId <= 0) {
        throw Exception('Invalid user ID');
      }

      return await _historyRepository.deleteUserHistory(userId);
    } catch (e) {
      throw Exception('Failed to delete user history: ${e.toString()}');
    }
  }

  /// Clears all classification history
  ///
  /// Returns: The number of records deleted
  ///
  /// Throws:
  /// - [Exception] if the clear operation fails
  Future<int> clearAllHistory() async {
    try {
      return await _historyRepository.clearAllHistory();
    } catch (e) {
      throw Exception('Failed to clear all history: ${e.toString()}');
    }
  }
}
