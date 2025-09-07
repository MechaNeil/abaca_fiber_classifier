import 'package:flutter/material.dart';
import '../../domain/entities/classification_result.dart';
import '../../domain/entities/model_info.dart';
import '../../domain/usecases/initialize_model_usecase.dart';
import '../../domain/usecases/pick_image_usecase.dart';
import '../../domain/usecases/classify_image_usecase.dart';
import '../../domain/usecases/get_current_model_usecase.dart';
import '../../core/utils/image_utils.dart';

class ClassificationViewModel extends ChangeNotifier {
  final InitializeModelUseCase _initializeModelUseCase;
  final PickImageUseCase _pickImageUseCase;
  final ClassifyImageUseCase _classifyImageUseCase;
  final GetCurrentModelUseCase _getCurrentModelUseCase;

  ClassificationViewModel({
    required InitializeModelUseCase initializeModelUseCase,
    required PickImageUseCase pickImageUseCase,
    required ClassifyImageUseCase classifyImageUseCase,
    required GetCurrentModelUseCase getCurrentModelUseCase,
  }) : _initializeModelUseCase = initializeModelUseCase,
       _pickImageUseCase = pickImageUseCase,
       _classifyImageUseCase = classifyImageUseCase,
       _getCurrentModelUseCase = getCurrentModelUseCase;

  // State variables
  bool _isLoading = false;
  bool _isModelInitialized = false;
  String? _error;
  String? _imagePath;
  ModelInfo? _modelInfo;
  List<String> _labels = [];
  ClassificationResult? _classificationResult;
  String? _pythonStyleOutput;

  // Getters
  bool get isLoading => _isLoading;
  bool get isModelInitialized => _isModelInitialized;
  bool get canPredict => _isModelInitialized && !_isLoading;
  String? get error => _error;
  String? get imagePath => _imagePath;
  ModelInfo? get modelInfo => _modelInfo;
  List<String> get labels => _labels;
  ClassificationResult? get classificationResult => _classificationResult;
  String? get pythonStyleOutput => _pythonStyleOutput;

  // Computed properties
  String? get predictedClass => _classificationResult?.predictedLabel;
  double? get confidence => _classificationResult?.confidence;
  List<double>? get probabilities => _classificationResult?.probabilities;

  Future<void> initializeModel() async {
    _setLoading(true);
    _clearError();

    try {
      final (modelInfo, labels) = await _initializeModelUseCase();
      _modelInfo = modelInfo;
      _labels = labels;
      _isModelInitialized = true;

      debugPrint('Model initialized successfully');
      debugPrint('Input: ${modelInfo.inputInfo}');
      debugPrint('Output: ${modelInfo.outputInfo}');

      if (modelInfo.isQuantized) {
        debugPrint(
          '[Warning] Detected quantized input tensor (${modelInfo.inputType})',
        );
      }
    } catch (e) {
      _setError('Failed to initialize model: $e');
      debugPrint('Model initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndClassifyImage() async {
    if (!_isModelInitialized) {
      _setError('Model not initialized');
      return;
    }

    _setLoading(true);
    _clearError();
    _clearResults();

    try {
      // Pick image
      final imagePath = await _pickImageUseCase();
      if (imagePath == null) {
        _setLoading(false);
        return; // User cancelled
      }

      _imagePath = imagePath;
      notifyListeners();

      // Classify image
      final result = await _classifyImageUseCase(imagePath, _labels);
      _classificationResult = result;

      // Generate Python-style output for debugging
      _pythonStyleOutput = ImageUtils.formatPythonTuple(
        result.predictedLabel,
        result.confidence,
        result.probabilities,
      );

      // Print to console for verification
      debugPrint(_pythonStyleOutput);
    } catch (e) {
      _setError('Classification failed: $e');
      debugPrint('Classification error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> classifyImageFromPath(String imagePath) async {
    if (!_isModelInitialized) {
      _setError('Model not initialized');
      return;
    }

    _setLoading(true);
    _clearError();
    _clearResults();

    try {
      _imagePath = imagePath;
      notifyListeners();

      // Classify image
      final result = await _classifyImageUseCase(imagePath, _labels);
      _classificationResult = result;

      // Generate Python-style output for debugging
      _pythonStyleOutput = ImageUtils.formatPythonTuple(
        result.predictedLabel,
        result.confidence,
        result.probabilities,
      );

      // Print to console for verification
      debugPrint(_pythonStyleOutput);
    } catch (e) {
      _setError('Classification failed: $e');
      debugPrint('Classification error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _clearResults() {
    _imagePath = null;
    _classificationResult = null;
    _pythonStyleOutput = null;
  }

  /// Gets the current model name being used
  Future<String> getCurrentModelName() async {
    try {
      return await _getCurrentModelUseCase.execute();
    } catch (e) {
      // Return default if error occurs
      return 'mobilenetv3small_b2.tflite';
    }
  }

  @override
  void dispose() {
    // Repository disposal is handled in the main app
    super.dispose();
  }
}
