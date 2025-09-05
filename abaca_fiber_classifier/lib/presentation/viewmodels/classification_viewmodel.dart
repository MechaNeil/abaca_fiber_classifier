import 'package:flutter/foundation.dart';
import '../../domain/entities/classification_result.dart';
import '../../domain/entities/model_info.dart';
import '../../domain/usecases/initialize_model_usecase.dart';
import '../../domain/usecases/pick_image_usecase.dart';
import '../../domain/usecases/classify_image_usecase.dart';
import '../../core/utils/image_utils.dart';

class ClassificationViewModel extends ChangeNotifier {
  final InitializeModelUseCase _initializeModelUseCase;
  final PickImageUseCase _pickImageUseCase;
  final ClassifyImageUseCase _classifyImageUseCase;

  ClassificationViewModel({
    required InitializeModelUseCase initializeModelUseCase,
    required PickImageUseCase pickImageUseCase,
    required ClassifyImageUseCase classifyImageUseCase,
  }) : _initializeModelUseCase = initializeModelUseCase,
       _pickImageUseCase = pickImageUseCase,
       _classifyImageUseCase = classifyImageUseCase;

  // State variables
  bool _isLoading = false;
  bool _isModelReady = false;
  ModelInfo? _modelInfo;
  List<String> _labels = [];
  String? _imagePath;
  ClassificationResult? _classificationResult;
  String? _error;
  String? _pyStyleOutput;

  // Getters
  bool get isLoading => _isLoading;
  bool get isModelReady => _isModelReady;
  bool get canPredict => _isModelReady && !_isLoading;
  ModelInfo? get modelInfo => _modelInfo;
  List<String> get labels => _labels;
  String? get imagePath => _imagePath;
  ClassificationResult? get classificationResult => _classificationResult;
  String? get error => _error;
  String? get pyStyleOutput => _pyStyleOutput;

  // Methods
  Future<void> initializeModel() async {
    _setLoading(true);
    _clearError();

    try {
      final (modelInfo, labels) = await _initializeModelUseCase();
      _modelInfo = modelInfo;
      _labels = labels;
      _isModelReady = true;

      // Warn if quantized model
      if (modelInfo.isQuantized) {
        debugPrint(
          '[Warning] Detected quantized input tensor (${modelInfo.inputType}). '
          'The current preprocessing uses float [-1,1].',
        );
      }
    } catch (e) {
      _setError('Failed to load model/labels: $e');
      _isModelReady = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndPredictImage() async {
    if (!_isModelReady) {
      _setError('Model not ready');
      return;
    }

    _setLoading(true);
    _clearError();
    _clearPrediction();

    try {
      final imagePath = await _pickImageUseCase();
      if (imagePath == null) {
        _setLoading(false);
        return;
      }

      _imagePath = imagePath;
      notifyListeners();

      final result = await _classifyImageUseCase(imagePath, _labels);
      _classificationResult = result;

      // Generate Python-style output for debugging
      _pyStyleOutput = ImageUtils.formatPythonTuple(
        result.predictedLabel,
        result.confidence,
        result.probabilities,
      );

      // Print to console for verification
      debugPrint(_pyStyleOutput);
    } catch (e) {
      _setError('Prediction failed: $e');
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

  void _clearPrediction() {
    _classificationResult = null;
    _pyStyleOutput = null;
  }

  @override
  void dispose() {
    // Repository disposal is handled by the repository itself
    super.dispose();
  }
}
