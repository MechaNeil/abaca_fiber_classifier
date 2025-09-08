import '../repositories/admin_repository.dart';

/// Use case for importing a new model
class ImportModelUseCase {
  final AdminRepository _adminRepository;

  ImportModelUseCase(this._adminRepository);

  /// Executes the model import process
  ///
  /// Parameters:
  /// - [sourcePath]: The path to the source model file
  /// - [modelName]: The name to give the imported model
  ///
  /// Returns: The path where the model was imported
  ///
  /// Throws: [Exception] if import fails
  Future<String> execute({
    required String sourcePath,
    required String modelName,
  }) async {
    // Validate input
    if (sourcePath.trim().isEmpty) {
      throw Exception('Source path cannot be empty');
    }
    if (modelName.trim().isEmpty) {
      throw Exception('Model name cannot be empty');
    }
    if (!sourcePath.toLowerCase().endsWith('.tflite')) {
      throw Exception('Only .tflite files are supported');
    }

    // Import the model
    return await _adminRepository.importModel(sourcePath, modelName);
  }
}
