import '../entities/model_entity.dart';

/// Repository interface for admin operations
abstract class AdminRepository {
  /// Get all imported models
  Future<List<ModelEntity>> getImportedModels();

  /// Import a new model
  Future<String> importModel(String sourcePath, String modelName);

  /// Set the current active model
  Future<void> setCurrentModel(String modelPath);

  /// Get the current active model path
  Future<String?> getCurrentModelPath();

  /// Get the current active model entity
  Future<ModelEntity?> getCurrentModel();

  /// Revert to default model
  Future<void> revertToDefaultModel();

  /// Delete an imported model
  Future<void> deleteImportedModel(String modelPath);

  /// Check if a model is currently active
  Future<bool> isModelActive(String modelPath);

  /// Get default model path
  String getDefaultModelPath();

  /// Export classification logs (placeholder for future implementation)
  Future<String> exportClassificationLogs();
}
