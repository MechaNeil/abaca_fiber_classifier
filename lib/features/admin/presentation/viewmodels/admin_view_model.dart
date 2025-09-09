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
      _error = 'Failed to load models: ${e.toString()}';
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
          _error = 'Please select a valid TensorFlow Lite model file (.tflite)';
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
      _error = 'Failed to pick file: ${e.toString()}';
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

      _successMessage = 'Model "$modelName" imported successfully';

      // Reload models to include the new one
      await loadModels();
    } catch (e) {
      _error = 'Failed to import model: ${e.toString()}';
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
          _successMessage = 'Successfully switched to model: ${model.name}';
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

              // Provide user-friendly error message
              _error = _formatUserFriendlyError(reloadError, model.name, true);
            } catch (revertError) {
              _currentModel = previousModel; // Keep UI consistent
              _error = _formatCriticalError(model.name, revertError);
            }
          } else {
            // No previous model to revert to
            _error = _formatUserFriendlyError(reloadError, model.name, false);
          }
        }
      } else {
        // No classification view model available, just update the path
        _currentModel = model;
        _successMessage =
            'Model path updated to: ${model.name}. Restart the app to use the new model.';
      }
    } catch (e) {
      // Failed to set active model in the first place
      _error = 'Failed to switch model: ${e.toString()}';
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
          _successMessage = 'Successfully reverted to default model';
        } catch (reloadError) {
          debugPrint('Failed to reload default model: $reloadError');
          _error = _formatUserFriendlyError(
            reloadError,
            'default model',
            false,
          );
        }
      } else {
        _currentModel = await _manageModelsUseCase.getCurrentModel();
        _successMessage = 'Reverted to default model';
      }
    } catch (e) {
      _error = 'Failed to revert to default model: ${e.toString()}';
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
      _successMessage = 'Model "${model.name}" deleted successfully';

      // Reload models to reflect the deletion
      await loadModels();
    } catch (e) {
      _error = 'Failed to delete model: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Export classification logs and comprehensive data
  Future<void> exportLogs() async {
    _isExporting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Check and request storage permission first
      final hasPermission = await _exportLogsUseCase.checkStoragePermission();
      if (!hasPermission) {
        final permissionGranted = await _exportLogsUseCase
            .requestStoragePermission();
        if (!permissionGranted) {
          _successMessage =
              'Permission denied. Files will be saved to app storage instead.';
          notifyListeners();
          // Continue with export to app storage
        }
      }

      final result = await _exportLogsUseCase.exportComplete();
      final jsonPath = result['json_export'] as String;
      final csvPaths = result['csv_exports'] as List<String>;
      final totalRecords = result['total_records'] as int;

      _successMessage =
          'Export completed successfully!\n'
          '• Total records: $totalRecords\n'
          '• JSON file: ${_getFileName(jsonPath)}\n'
          '• CSV files: ${csvPaths.length}\n'
          'Files saved to: ${_getLocationDescription(jsonPath)}';
    } catch (e) {
      if (e is UnimplementedError) {
        _error = 'Export feature will be available in a future update';
      } else {
        _error = 'Failed to export logs: ${e.toString()}';
      }
    }

    _isExporting = false;
    notifyListeners();
  }

  /// Extract filename from full path for user-friendly display
  String _getFileName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  /// Extract directory name from full path for user-friendly display
  String _getDirectoryName(String path) {
    final parts = path.split('/');
    if (parts.length > 1) {
      // Return the last two parts of the path for context
      final directoryParts = parts.sublist(0, parts.length - 1);
      if (directoryParts.isNotEmpty) {
        return directoryParts.join('/');
      }
    }
    return path;
  }

  /// Get user-friendly location description
  String _getLocationDescription(String path) {
    if (path.contains('Download') || path.contains('download')) {
      return 'Downloads folder\n${_getDirectoryName(path)}';
    } else if (path.contains('documents') || path.contains('Documents')) {
      return 'App documents folder\n${_getDirectoryName(path)}';
    } else if (path.contains('AbacaFiberExports')) {
      return 'External storage\n${_getDirectoryName(path)}';
    } else {
      return _getDirectoryName(path);
    }
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

  /// Format user-friendly error messages for model loading failures
  String _formatUserFriendlyError(
    dynamic error,
    String modelName,
    bool hasReverted,
  ) {
    final errorString = error.toString();

    // Handle critical errors where both models failed
    if (errorString.contains(
      'Both target model and default model failed to load',
    )) {
      return 'Unable to load any model files\n\n'
          'The app encountered a serious issue and cannot load either the selected model or the default backup model. '
          'This usually means:\n\n'
          '• Model files may be corrupted or missing\n'
          '• Device storage may be full or corrupted\n'
          '• App permissions may be restricted\n\n'
          '💡 Solution: Please restart the app or reinstall if the problem persists.';
    }

    // Handle TensorFlow Lite interpreter creation errors
    if (errorString.contains('Failed to create TensorFlow Lite interpreter')) {
      return hasReverted
          ? '❌ Model incompatible with device\n\n'
                'The model "$modelName" cannot run on this device because:\n\n'
                '• The model format is incompatible\n'
                '• The model uses unsupported features\n'
                '• The model file may be corrupted\n\n'
                '✅ Automatically switched back to the previous working model.'
          : '❌ Model incompatible with device\n\n'
                'The model "$modelName" cannot run on this device because the model format is incompatible or corrupted.\n\n'
                '💡 Try using a different TensorFlow Lite model file.';
    }

    // Handle compatibility errors
    if (errorString.contains('FULLY_CONNECTED') ||
        errorString.contains('builtin opcode') ||
        errorString.contains('Didn\'t find op for builtin opcode')) {
      return hasReverted
          ? '❌ Model not compatible\n\n'
                'The model "$modelName" uses advanced features that are not supported by this app version.\n\n'
                '💡 Please use a standard TensorFlow Lite v2.x model.\n\n'
                '✅ Automatically switched back to the previous working model.'
          : '❌ Model not compatible\n\n'
                'The model "$modelName" uses advanced features that are not supported by this app version.\n\n'
                '💡 Please use a standard TensorFlow Lite v2.x model.';
    }

    // Handle file not found errors
    if (errorString.contains('Model file not found') ||
        errorString.contains('No such file or directory')) {
      return hasReverted
          ? '❌ Model file missing\n\n'
                'The model "$modelName" file could not be found on the device. It may have been moved or deleted.\n\n'
                '✅ Automatically switched back to the previous working model.'
          : '❌ Model file missing\n\n'
                'The model "$modelName" file could not be found on the device. It may have been moved or deleted.\n\n'
                '💡 Try importing the model again.';
    }

    // Handle generic Unable to create interpreter errors
    if (errorString.contains('Unable to create interpreter')) {
      return hasReverted
          ? '❌ Cannot load model\n\n'
                'The model "$modelName" appears to be corrupted or incompatible with this device.\n\n'
                '✅ Automatically switched back to the previous working model.'
          : '❌ Cannot load model\n\n'
                'The model "$modelName" appears to be corrupted or incompatible with this device.\n\n'
                '💡 Try using a different model file.';
    }

    // Default fallback error message
    return hasReverted
        ? '❌ Failed to switch models\n\n'
              'Could not load "$modelName". The error was:\n$errorString\n\n'
              '✅ Automatically switched back to the previous working model.'
        : '❌ Failed to load model\n\n'
              'Could not load "$modelName". The error was:\n$errorString\n\n'
              '💡 Please try a different model file.';
  }

  /// Format critical error messages when reverting also fails
  String _formatCriticalError(String modelName, dynamic revertError) {
    return '🚨 Critical Error\n\n'
        'Failed to switch to "$modelName" and could not restore the previous model.\n\n'
        'The app is now in an unstable state. Please restart the app to restore normal functionality.\n\n'
        'Error details: ${revertError.toString()}';
  }
}
