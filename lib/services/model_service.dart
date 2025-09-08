import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart';

/// Service for managing model paths and current model selection
class ModelService {
  static const String _currentModelKey = 'current_model_path';
  static const String _defaultModelPath = 'assets/mobilenetv3small_b2.tflite';

  /// Get the current active model path
  static Future<String> getCurrentModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentModelKey) ?? _defaultModelPath;
  }

  /// Get the current active model name (filename only)
  static Future<String> getCurrentModelName() async {
    final currentPath = await getCurrentModelPath();
    // Extract filename from path (handles both assets/ and file paths)
    return currentPath.split('/').last;
  }

  /// Set the current active model path
  static Future<void> setCurrentModelPath(String modelPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentModelKey, modelPath);
  }

  /// Get the default model path
  static String getDefaultModelPath() {
    return _defaultModelPath;
  }

  /// Check if current model is an asset or file
  static Future<bool> isCurrentModelAsset() async {
    final currentPath = await getCurrentModelPath();
    return currentPath.startsWith('assets/');
  }

  /// Check if a model file exists
  static Future<bool> modelExists(String modelPath) async {
    if (modelPath.startsWith('assets/')) {
      // For asset models, verify existence using rootBundle.loadString (lighter operation)
      try {
        await rootBundle.loadString(modelPath);
        return true;
      } catch (e) {
        return false;
      }
    } else {
      // For file models, check if file exists
      final file = File(modelPath);
      return await file.exists();
    }
  }

  /// Revert to default model
  static Future<void> revertToDefault() async {
    await setCurrentModelPath(_defaultModelPath);
  }
}
