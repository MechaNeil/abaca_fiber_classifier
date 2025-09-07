import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/model_entity.dart';
import '../../domain/usecases/import_model_usecase.dart';
import '../../domain/usecases/manage_models_usecase.dart';
import '../../domain/usecases/export_logs_usecase.dart';
import '../../../../presentation/viewmodels/classification_view_model.dart';

/// ViewModel for handling admin operations and state
class AdminViewModel extends ChangeNotifier {
  final ImportModelUseCase _importModelUseCase;
  final ManageModelsUseCase _manageModelsUseCase;
  final ExportLogsUseCase _exportLogsUseCase;
  final ClassificationViewModel? _classificationViewModel;

  AdminViewModel({
    required ImportModelUseCase importModelUseCase,
    required ManageModelsUseCase manageModelsUseCase,
    required ExportLogsUseCase exportLogsUseCase,
    ClassificationViewModel? classificationViewModel,
  }) : _importModelUseCase = importModelUseCase,
       _manageModelsUseCase = manageModelsUseCase,
       _exportLogsUseCase = exportLogsUseCase,
       _classificationViewModel = classificationViewModel;

  // Loading states
  bool _isImporting = false;
  bool _isLoadingModels = false;
  bool _isSwitchingModel = false;
  bool _isExporting = false;

  // Data states
  List<ModelEntity> _availableModels = [];
  ModelEntity? _currentModel;

  // Error states
  String? _error;
  String? _successMessage;

  // Getters
  bool get isImporting => _isImporting;
  bool get isLoadingModels => _isLoadingModels;
  bool get isSwitchingModel => _isSwitchingModel;
  bool get isExporting => _isExporting;
  List<ModelEntity> get availableModels => _availableModels;
  ModelEntity? get currentModel => _currentModel;
  String? get error => _error;
  String? get successMessage => _successMessage;

  bool get hasAnyOperation =>
      _isImporting || _isLoadingModels || _isSwitchingModel || _isExporting;

  /// Initialize the admin view model
  Future<void> initialize() async {
    await loadModels();
  }

  /// Load all available models
  Future<void> loadModels() async {
    _isLoadingModels = true;
    _error = null;
    notifyListeners();

    try {
      _availableModels = await _manageModelsUseCase.getAvailableModels();
      _currentModel = await _manageModelsUseCase.getCurrentModel();
    } catch (e) {
      _error =
          'Unable to load available models. Please check your device storage and try restarting the app.';
    }

    _isLoadingModels = false;
    notifyListeners();
  }

  /// Import a new model from file picker
  Future<void> importModelFromPicker() async {
    try {
      FilePickerResult? result;

      // Try with custom file type first
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['tflite'],
          dialogTitle: 'Select TensorFlow Lite Model',
        );
      } catch (platformException) {
        // If custom type fails, fallback to any file type
        debugPrint(
          'Custom file picker failed, falling back to any type: $platformException',
        );
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: 'Select TensorFlow Lite Model (.tflite)',
        );
      }

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Validate file extension manually if using FileType.any
        if (!fileName.toLowerCase().endsWith('.tflite')) {
          _error =
              'Invalid file type selected. Please choose a TensorFlow Lite model file (.tflite)';
          notifyListeners();
          return;
        }

        // Extract model name from filename (remove extension)
        final modelName = fileName
            .replaceAll('.tflite', '')
            .replaceAll('.TFLITE', '');

        await importModel(filePath, modelName);
      }
    } catch (e) {
      _error = 'Unable to access the selected file. Please try again.';
      notifyListeners();
    }
  }

  /// Import a model from a specific path
  Future<void> importModel(String sourcePath, String modelName) async {
    _isImporting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _importModelUseCase.execute(
        sourcePath: sourcePath,
        modelName: modelName,
      );

      _successMessage =
          'Model "$modelName" has been successfully imported and is ready to use';

      // Reload models to include the new one
      await loadModels();
    } catch (e) {
      _error =
          'Unable to import the model. Please ensure the file is a valid TensorFlow Lite model and try again.';
    }

    _isImporting = false;
    notifyListeners();
  }

  /// Switch to a different model
  Future<void> switchToModel(ModelEntity model) async {
    _isSwitchingModel = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    // Save the current model in case we need to revert
    final previousModel = _currentModel;
    final previousModelPath = previousModel?.path;

    try {
      await _manageModelsUseCase.setActiveModel(model.path);

      // Trigger model reload in classification view model
      if (_classificationViewModel != null) {
        try {
          await _classificationViewModel.reloadModel();
          debugPrint('Model reloaded in classification system');

          // Only update UI state if model reload was successful
          _currentModel = model;
          _successMessage =
              'Successfully switched to "${model.name}". The new model is now active for all classifications.';
        } catch (reloadError) {
          debugPrint('Model reload failed: $reloadError');

          // Model reload failed, so we need to revert both the model service and UI state
          if (previousModelPath != null) {
            try {
              // Revert the model path in ModelService
              await _manageModelsUseCase.setActiveModel(previousModelPath);
              // Try to reload the previous model
              await _classificationViewModel.reloadModel();

              // Keep the UI showing the previous model since that's what's actually active
              _currentModel = previousModel;

              // Provide detailed error message based on the type of error
              if (reloadError.toString().contains('FULLY_CONNECTED') ||
                  reloadError.toString().contains('builtin opcode')) {
                _error =
                    'The model "${model.name}" is not compatible with this app version. Please use a different model. Your previous model has been restored.';
              } else if (reloadError.toString().contains(
                'Unable to create interpreter',
              )) {
                _error =
                    'The model "${model.name}" could not be loaded - it may be corrupted. Please try a different model file. Your previous model has been restored.';
              } else {
                _error =
                    'Unable to switch to "${model.name}". Your previous model has been restored and will continue to work normally.';
              }
            } catch (revertError) {
              _currentModel = previousModel; // Keep UI consistent
              _error =
                  'Unable to switch to "${model.name}" and could not restore the previous model. Please restart the app to fix this issue.';
            }
          } else {
            // No previous model to revert to
            _error =
                'Unable to load the selected model "${model.name}". Please try a different model or restart the app.';
          }
        }
      } else {
        // No classification view model available, just update the path
        _currentModel = model;
        _successMessage =
            'Model updated to "${model.name}". Please restart the app to begin using the new model.';
      }
    } catch (e) {
      // Failed to set active model in the first place
      _error =
          'Unable to switch to the selected model. Please try again or choose a different model.';
      _currentModel = previousModel; // Restore previous model reference
    }

    _isSwitchingModel = false;
    notifyListeners();
  }

  /// Revert to default model
  Future<void> revertToDefaultModel() async {
    _isSwitchingModel = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _manageModelsUseCase.revertToDefault();

      // Trigger model reload in classification view model
      if (_classificationViewModel != null) {
        try {
          await _classificationViewModel.reloadModel();
          debugPrint('Model reloaded in classification system after reverting');

          // Update UI state only after successful reload
          _currentModel = await _manageModelsUseCase.getCurrentModel();
          _successMessage =
              'Successfully restored the default model. You can now use the app normally.';
        } catch (reloadError) {
          debugPrint('Failed to reload default model: $reloadError');
          _error =
              'The default model has been restored but needs an app restart to take effect. Please close and reopen the app.';
        }
      } else {
        _currentModel = await _manageModelsUseCase.getCurrentModel();
        _successMessage = 'Default model has been restored successfully';
      }
    } catch (e) {
      _error =
          'Unable to restore the default model. Please restart the app or contact support.';
    }

    _isSwitchingModel = false;
    notifyListeners();
  }

  /// Delete an imported model
  Future<void> deleteModel(ModelEntity model) async {
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _manageModelsUseCase.deleteModel(model.path);
      _successMessage =
          'Model "${model.name}" has been successfully removed from your device';

      // Reload models to reflect the deletion
      await loadModels();
    } catch (e) {
      _error =
          'Unable to remove the model. Please try again or restart the app.';
      notifyListeners();
    }
  }

  /// Export classification logs (placeholder)
  Future<void> exportLogs() async {
    _isExporting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _exportLogsUseCase.execute();
      _successMessage =
          'Your data has been successfully exported to your device';
    } catch (e) {
      if (e is UnimplementedError) {
        _error =
            'The export feature is coming soon! This functionality will be available in a future update.';
      } else {
        _error =
            'Unable to export your data. Please check your device storage and try again.';
      }
    }

    _isExporting = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Clear success message
  void clearSuccessMessage() {
    if (_successMessage != null) {
      _successMessage = null;
      notifyListeners();
    }
  }

  /// Clear all messages
  void clearMessages() {
    bool shouldNotify = false;

    if (_error != null) {
      _error = null;
      shouldNotify = true;
    }

    if (_successMessage != null) {
      _successMessage = null;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Check if a model is the default model
  bool isDefaultModel(ModelEntity model) {
    return model.isDefault;
  }

  /// Check if a model is currently active
  bool isCurrentModel(ModelEntity model) {
    return _currentModel?.path == model.path;
  }
}
