import '../repositories/admin_repository.dart';

/// Use case for exporting classification logs
class ExportLogsUseCase {
  final AdminRepository _adminRepository;

  ExportLogsUseCase(this._adminRepository);

  /// Executes the logs export process
  ///
  /// Returns: The path where the logs were exported
  ///
  /// Throws: [Exception] if export fails
  Future<String> execute() async {
    return await _adminRepository.exportClassificationLogs();
  }
}
