import '../repositories/admin_repository.dart';
import '../entities/model_entity.dart';

/// Use case for managing model selection and activation
class ManageModelsUseCase {
  final AdminRepository _adminRepository;

  ManageModelsUseCase(this._adminRepository);

  /// Get all available models
  Future<List<ModelEntity>> getAvailableModels() async {
    return await _adminRepository.getImportedModels();
  }

  /// Set a model as the current active model
  Future<void> setActiveModel(String modelPath) async {
    if (modelPath.trim().isEmpty) {
      throw Exception('Model path cannot be empty');
    }

    await _adminRepository.setCurrentModel(modelPath);
  }

  /// Get the currently active model
  Future<ModelEntity?> getCurrentModel() async {
    return await _adminRepository.getCurrentModel();
  }

  /// Revert to the default model
  Future<void> revertToDefault() async {
    await _adminRepository.revertToDefaultModel();
  }

  /// Delete an imported model
  Future<void> deleteModel(String modelPath) async {
    if (modelPath.trim().isEmpty) {
      throw Exception('Model path cannot be empty');
    }

    // Check if the model is currently active
    final isActive = await _adminRepository.isModelActive(modelPath);
    if (isActive) {
      throw Exception(
        'Cannot delete the currently active model. Please switch to another model first.',
      );
    }

    await _adminRepository.deleteImportedModel(modelPath);
  }

  /// Check if a model is the default model
  bool isDefaultModel(String modelPath) {
    return modelPath == _adminRepository.getDefaultModelPath();
  }
}
