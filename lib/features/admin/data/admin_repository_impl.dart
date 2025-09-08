import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/repositories/admin_repository.dart';
import '../domain/entities/model_entity.dart';
import '../../auth/data/database_service.dart';

/// Implementation of [AdminRepository]
class AdminRepositoryImpl implements AdminRepository {
  static const String _currentModelKey = 'current_model_path';
  static const String _defaultModelPath = 'assets/mobilenetv3small_b2.tflite';

  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  Future<List<ModelEntity>> getImportedModels() async {
    final db = await _databaseService.database;

    // Create models table if it doesn't exist
    await _createModelsTableIfNotExists(db);

    final result = await db.query(
      'imported_models',
      orderBy: 'importedAt DESC',
    );

    final models = result.map((map) => ModelEntity.fromMap(map)).toList();

    // Always include the default model
    final defaultModel = ModelEntity(
      name: 'Default Model (MobileNetV3)',
      path: _defaultModelPath,
      importedAt: DateTime(2024, 1, 1), // Static date for default model
      isDefault: true,
      description: 'Original model included with the app',
    );

    // Check if default model is already in the list
    final hasDefault = models.any((model) => model.isDefault);
    if (!hasDefault) {
      models.insert(0, defaultModel);
    }

    return models;
  }

  @override
  Future<String> importModel(String sourcePath, String modelName) async {
    // Get app documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDocDir.path}/models');

    // Create models directory if it doesn't exist
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        '${modelName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$timestamp.tflite';
    final destinationPath = '${modelsDir.path}/$fileName';

    // Copy the file
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    await sourceFile.copy(destinationPath);

    // Save model info to database
    final db = await _databaseService.database;
    await _createModelsTableIfNotExists(db);

    final modelEntity = ModelEntity(
      name: modelName,
      path: destinationPath,
      importedAt: DateTime.now(),
      isDefault: false,
      description: 'Imported from: $sourcePath',
    );

    await db.insert('imported_models', modelEntity.toMap());

    return destinationPath;
  }

  @override
  Future<void> setCurrentModel(String modelPath) async {
    // Validate the model path before setting it
    if (!modelPath.startsWith('assets/')) {
      final modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        throw Exception('Model file does not exist: $modelPath');
      }

      // Check if it's a .tflite file
      if (!modelPath.toLowerCase().endsWith('.tflite')) {
        throw Exception(
          'Invalid model file type. Expected .tflite file: $modelPath',
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentModelKey, modelPath);
  }

  @override
  Future<String?> getCurrentModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentModelKey) ?? _defaultModelPath;
  }

  @override
  Future<ModelEntity?> getCurrentModel() async {
    final currentPath = await getCurrentModelPath();
    if (currentPath == null) return null;

    final models = await getImportedModels();
    try {
      return models.firstWhere((model) => model.path == currentPath);
    } catch (e) {
      // If current model not found, return default
      return models.firstWhere((model) => model.isDefault);
    }
  }

  @override
  Future<void> revertToDefaultModel() async {
    await setCurrentModel(_defaultModelPath);
  }

  @override
  Future<void> deleteImportedModel(String modelPath) async {
    // Don't allow deleting the default model
    if (modelPath == _defaultModelPath) {
      throw Exception('Cannot delete the default model');
    }

    // Delete from database
    final db = await _databaseService.database;
    await db.delete(
      'imported_models',
      where: 'path = ?',
      whereArgs: [modelPath],
    );

    // Delete physical file
    final file = File(modelPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> isModelActive(String modelPath) async {
    final currentPath = await getCurrentModelPath();
    return currentPath == modelPath;
  }

  @override
  String getDefaultModelPath() {
    return _defaultModelPath;
  }

  @override
  Future<String> exportClassificationLogs() async {
    // Placeholder implementation for future development
    throw UnimplementedError(
      'Export classification logs feature will be implemented in a future update',
    );
  }

  /// Creates the imported_models table if it doesn't exist
  Future<void> _createModelsTableIfNotExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS imported_models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL UNIQUE,
        importedAt INTEGER NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        description TEXT
      )
    ''');
  }
}
