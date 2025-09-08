import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/list_extensions.dart' as list_ext;
import '../domain/entities/classification_result.dart';
import '../domain/entities/model_info.dart';
import 'model_service.dart';

class MLService {
  Interpreter? _interpreter;

  Future<ModelInfo> loadModel() async {
    try {
      // Get the current model path from admin settings
      final modelPath = await ModelService.getCurrentModelPath();
      debugPrint('Loading model from path: $modelPath');

      // Load the model based on whether it's an asset or file
      if (modelPath.startsWith('assets/')) {
        debugPrint('Loading asset model: $modelPath');
        _interpreter = await Interpreter.fromAsset(modelPath);
      } else {
        // Check if the file exists
        final modelFile = File(modelPath);
        if (!await modelFile.exists()) {
          debugPrint('Model file not found: $modelPath, reverting to default');
          // Fall back to default model if the file doesn't exist
          await ModelService.revertToDefault();
          _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
        } else {
          debugPrint('Loading file model: $modelPath');
          _interpreter = Interpreter.fromFile(modelFile);
        }
      }

      _interpreter!.allocateTensors();

      final inTensor = _interpreter!.getInputTensor(0);
      final outTensor = _interpreter!.getOutputTensor(0);
      final inputShape = inTensor.shape;
      final outputShape = outTensor.shape;
      final inputType = inTensor.type.toString();
      final outputType = outTensor.type.toString();

      final inputInfo =
          'shape=${ImageUtils.formatShape(inputShape)} type=$inputType';
      final outputInfo =
          'shape=${ImageUtils.formatShape(outputShape)} type=$outputType';

      // Validate input tensor
      if (inputShape.length != 4) {
        throw StateError(
          'Expected 4D input tensor [1,H,W,3], got ${ImageUtils.formatShape(inputShape)}',
        );
      }
      if (inputShape[0] != 1) {
        throw StateError('Expected batch=1, got batch=${inputShape[0]}');
      }
      if (inputShape[3] != 3) {
        throw StateError(
          'Expected 3-channel RGB, got channels=${inputShape[3]}',
        );
      }

      debugPrint(
        'Model loaded successfully with input: $inputInfo, output: $outputInfo',
      );

      return ModelInfo(
        inputInfo: inputInfo,
        outputInfo: outputInfo,
        inputShape: inputShape,
        outputShape: outputShape,
        inputType: inputType,
        outputType: outputType,
      );
    } catch (e) {
      debugPrint('Error loading model: $e');

      // Provide specific error messages for common TensorFlow Lite issues
      String errorMessage;
      if (e.toString().contains('FULLY_CONNECTED') ||
          e.toString().contains('builtin opcode')) {
        errorMessage =
            'Model compatibility error: This model uses operators not supported by the current TensorFlow Lite runtime. Please use a model compatible with TensorFlow Lite v2.x';
      } else if (e.toString().contains('Unable to create interpreter')) {
        errorMessage =
            'Failed to create TensorFlow Lite interpreter: The model file may be corrupted or incompatible';
      } else if (e.toString().contains('Invalid model file')) {
        errorMessage =
            'Invalid model file: Please ensure you selected a valid .tflite model file';
      } else {
        errorMessage = 'Model loading failed: ${e.toString()}';
      }

      // Clean up on error
      dispose();
      throw Exception(errorMessage);
    }
  }

  Future<ClassificationResult> predict(
    String imagePath,
    List<String> labels,
  ) async {
    if (_interpreter == null) {
      throw StateError('Model not loaded');
    }

    // Read and decode image
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Unable to decode image');
    }

    final inputTensor = _interpreter!.getInputTensor(0);
    final inputShape = inputTensor.shape;
    final targetH = inputShape[1];
    final targetW = inputShape[2];

    // Resize image with letterboxing
    final bool alreadyTarget =
        decoded.width == targetW && decoded.height == targetH;
    final double scale = alreadyTarget
        ? 1.0
        : math.min(targetW / decoded.width, targetH / decoded.height);
    final int newW = (decoded.width * scale).round();
    final int newH = (decoded.height * scale).round();
    final int dx = (targetW - newW) ~/ 2;
    final int dy = (targetH - newH) ~/ 2;

    final img.Image? resizedNoDistort = alreadyTarget
        ? null
        : img.copyResize(
            decoded,
            width: newW,
            height: newH,
            interpolation: img.Interpolation.nearest,
          );

    // Prepare input tensor
    final inputTypeStr = inputTensor.type.toString().toLowerCase();
    final bool isQuantized =
        inputTypeStr.contains('uint8') || inputTypeStr.contains('int8');

    final dynamic input = isQuantized
        ? List.generate(
            1,
            (_) => List.generate(
              targetH,
              (_) => List.generate(targetW, (_) => List<int>.filled(3, 0)),
            ),
          )
        : List.generate(
            1,
            (_) => List.generate(
              targetH,
              (_) => List.generate(targetW, (_) => List<double>.filled(3, 0.0)),
            ),
          );

    // Fill input with pixel values
    for (int y = 0; y < targetH; y++) {
      for (int x = 0; x < targetW; x++) {
        int r = 0, g = 0, b = 0;

        if (alreadyTarget) {
          final sp = decoded.getPixel(x, y);
          r = sp.r.toInt();
          g = sp.g.toInt();
          b = sp.b.toInt();
        } else {
          final int rx = x - dx;
          final int ry = y - dy;
          if (rx >= 0 && ry >= 0 && rx < newW && ry < newH) {
            final sp = resizedNoDistort!.getPixel(rx, ry);
            r = sp.r.toInt();
            g = sp.g.toInt();
            b = sp.b.toInt();
          }
        }

        if (isQuantized) {
          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
        } else {
          input[0][y][x][0] = r.toDouble();
          input[0][y][x][1] = g.toDouble();
          input[0][y][x][2] = b.toDouble();
        }
      }
    }

    // Prepare output
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final outputLen = outputShape.reduce((a, b) => a * b);
    final outputFlat = List<double>.filled(outputLen, 0.0);
    final output = list_ext.ListExtensions(outputFlat).reshape(outputShape);

    // Run inference
    _interpreter!.run(input, output);

    // Process results
    final List<double> probs = List<double>.from(
      (output[0] as List).map((e) => (e as num).toDouble()),
    );

    // Apply softmax if needed
    if (!ImageUtils.isProbabilityDistribution(probs)) {
      final softmaxed = ImageUtils.softmax(probs);
      for (var i = 0; i < probs.length; i++) {
        probs[i] = softmaxed[i];
      }
    }

    // Find best prediction
    final maxIdx = ImageUtils.findMaxIndex(probs);
    final predictedLabel = (maxIdx < labels.length)
        ? labels[maxIdx]
        : 'Class $maxIdx';
    final confidence = probs[maxIdx];

    return ClassificationResult(
      predictedLabel: predictedLabel,
      confidence: confidence,
      probabilities: probs,
    );
  }

  /// Get the current model name being used
  Future<String> getCurrentModelName() async {
    return await ModelService.getCurrentModelName();
  }

  /// Force reload the model (used when switching models)
  Future<ModelInfo> reloadModel() async {
    // Get the target model path first to validate it
    final targetModelPath = await ModelService.getCurrentModelPath();

    // Validate the target model before disposing current interpreter
    if (!targetModelPath.startsWith('assets/')) {
      final modelFile = File(targetModelPath);
      if (!await modelFile.exists()) {
        // Revert to default model if the target file doesn't exist
        await ModelService.revertToDefault();
        debugPrint(
          'Target model file not found, reverted to default: $targetModelPath',
        );
        throw Exception(
          'Model file not found: $targetModelPath. Reverted to default model.',
        );
      }
    }

    // Dispose of the current interpreter
    dispose();

    try {
      // Load the new model
      return await loadModel();
    } catch (e) {
      debugPrint(
        'Error during model reload, attempting fallback to default: $e',
      );

      // If loading fails, try to revert to default and load again
      try {
        await ModelService.revertToDefault();
        // Try loading the default model
        final defaultModelInfo = await loadModel();
        // Return the default model info if successful
        return defaultModelInfo;
      } catch (fallbackError) {
        debugPrint('Fallback to default model also failed: $fallbackError');
        throw Exception(
          'Target model failed to load: ${e.toString()}. Default model also failed: ${fallbackError.toString()}',
        );
      }
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
