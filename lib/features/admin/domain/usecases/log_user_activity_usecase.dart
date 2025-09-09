import '../repositories/export_repository.dart';
import '../entities/user_activity_log.dart';

/// Use case for logging user activities
class LogUserActivityUseCase {
  final ExportRepository _exportRepository;

  LogUserActivityUseCase(this._exportRepository);

  /// Log a user activity
  Future<void> execute({
    int? userId,
    String? username,
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final activityLog = UserActivityLog(
      userId: userId,
      username: username,
      activityType: activityType,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    await _exportRepository.logUserActivity(activityLog);
  }

  /// Get all user activity logs
  Future<List<UserActivityLog>> getAllLogs() async {
    return await _exportRepository.getAllUserActivityLogs();
  }

  /// Get logs for a specific user
  Future<List<UserActivityLog>> getLogsByUser(int userId) async {
    return await _exportRepository.getUserActivityLogsByUser(userId);
  }

  /// Get logs by activity type
  Future<List<UserActivityLog>> getLogsByType(String activityType) async {
    return await _exportRepository.getUserActivityLogsByType(activityType);
  }
}
