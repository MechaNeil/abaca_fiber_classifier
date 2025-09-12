import 'package:flutter/foundation.dart';

import '../../domain/entities/stored_image.dart';
import '../../domain/entities/classification_result.dart';
import '../../domain/usecases/image_storage/store_classified_image_usecase.dart';
import '../../domain/usecases/image_storage/get_stored_images_by_grade_usecase.dart';
import '../../domain/usecases/image_storage/get_storage_statistics_usecase.dart';
import '../../domain/usecases/image_storage/export_stored_images_usecase.dart';

/// ViewModel for managing image storage functionality
class ImageStorageViewModel extends ChangeNotifier {
  final StoreClassifiedImageUseCase _storeImageUseCase;
  final GetStoredImagesByGradeUseCase _getImagesByGradeUseCase;
  final GetStorageStatisticsUseCase _getStatisticsUseCase;
  final ExportStoredImagesUseCase _exportImagesUseCase;

  ImageStorageViewModel({
    required StoreClassifiedImageUseCase storeImageUseCase,
    required GetStoredImagesByGradeUseCase getImagesByGradeUseCase,
    required GetStorageStatisticsUseCase getStatisticsUseCase,
    required ExportStoredImagesUseCase exportImagesUseCase,
  }) : _storeImageUseCase = storeImageUseCase,
       _getImagesByGradeUseCase = getImagesByGradeUseCase,
       _getStatisticsUseCase = getStatisticsUseCase,
       _exportImagesUseCase = exportImagesUseCase;

  // State variables
  bool _isLoading = false;
  bool _isStoring = false;
  bool _isExporting = false;
  String? _error;
  String? _successMessage;

  // Storage data
  Map<String, List<StoredImage>> _imagesByGrade = {};
  Map<String, dynamic> _storageStatistics = {};
  Map<String, dynamic> _exportPreview = {};

  // Settings
  double _confidenceThreshold = 0.1; // Lowered for testing
  bool _autoStoreEnabled = true;

  // Getters
  bool get isLoading => _isLoading;
  bool get isStoring => _isStoring;
  bool get isExporting => _isExporting;
  String? get error => _error;
  String? get successMessage => _successMessage;
  Map<String, List<StoredImage>> get imagesByGrade => _imagesByGrade;
  Map<String, dynamic> get storageStatistics => _storageStatistics;
  Map<String, dynamic> get exportPreview => _exportPreview;
  double get confidenceThreshold => _confidenceThreshold;
  bool get autoStoreEnabled => _autoStoreEnabled;

  // Computed getters
  int get totalStoredImages {
    return _imagesByGrade.values.fold(0, (sum, images) => sum + images.length);
  }

  List<String> get availableGrades {
    return _imagesByGrade.keys.toList()..sort();
  }

  bool get hasStoredImages => totalStoredImages > 0;

  /// Stores a classified image if it meets the threshold
  Future<bool> storeClassifiedImage({
    required String originalImagePath,
    required ClassificationResult result,
    int? userId,
    required String model,
    bool forceStore = false,
  }) async {
    if (_isStoring) return false;

    _setStoring(true);
    _clearMessages();

    try {
      debugPrint(
        'ViewModel: Starting image storage for ${result.predictedLabel}, confidence: ${result.confidence}',
      );

      final storedImage = await _storeImageUseCase.execute(
        originalImagePath: originalImagePath,
        result: result,
        userId: userId,
        model: model,
        confidenceThreshold: _confidenceThreshold,
        forceStore: forceStore,
      );

      if (storedImage != null) {
        debugPrint(
          'ViewModel: Image stored successfully with ID ${storedImage.id}',
        );
        _setSuccessMessage(
          'Image stored successfully in grade ${result.predictedLabel}',
        );
        // Refresh the stored images for this grade
        await _loadImagesForGrade(result.predictedLabel);
        await _loadStorageStatistics();
        return true;
      } else {
        debugPrint(
          'ViewModel: Image not stored due to low confidence: ${result.confidence}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('ViewModel: Error storing image: $e');
      _setError('Failed to store image: ${e.toString()}');
      return false;
    } finally {
      _setStoring(false);
    }
  }

  /// Loads stored images for a specific grade
  Future<void> loadImagesForGrade(String grade) async {
    await _loadImagesForGrade(grade);
  }

  Future<void> _loadImagesForGrade(String grade) async {
    try {
      final images = await _getImagesByGradeUseCase.execute(grade);
      _imagesByGrade[grade] = images;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading images for grade $grade: $e');
    }
  }

  /// Loads stored images for all grades
  Future<void> loadAllStoredImages() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearMessages();

    try {
      _imagesByGrade = await _getImagesByGradeUseCase.executeGroupedByGrade();
      await _loadStorageStatistics();
    } catch (e) {
      _setError('Failed to load stored images: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads storage statistics
  Future<void> loadStorageStatistics() async {
    await _loadStorageStatistics();
  }

  Future<void> _loadStorageStatistics() async {
    try {
      _storageStatistics = await _getStatisticsUseCase.getStorageInsights();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading storage statistics: $e');
    }
  }

  /// Loads export preview
  Future<void> loadExportPreview() async {
    try {
      _exportPreview = await _exportImagesUseCase.getExportPreview();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load export preview: ${e.toString()}');
    }
  }

  /// Exports all stored images as ZIP
  Future<String?> exportAllImagesAsZip({String? customFileName}) async {
    if (_isExporting) return null;

    _setExporting(true);
    _clearMessages();

    try {
      debugPrint('ViewModel: Starting export all images as ZIP');
      final filePath = await _exportImagesUseCase.exportAsZip(
        customFileName: customFileName,
      );
      debugPrint('ViewModel: Export ZIP completed successfully: $filePath');
      _setSuccessMessage('Successfully exported all images to ZIP file');
      return filePath;
    } catch (e) {
      debugPrint('ViewModel: Export ZIP failed: $e');
      _setError('Failed to export images: ${e.toString()}');
      return null;
    } finally {
      _setExporting(false);
    }
  }

  /// Exports a specific grade as ZIP
  Future<String?> exportGradeAsZip(
    String grade, {
    String? customFileName,
  }) async {
    if (_isExporting) return null;

    _setExporting(true);
    _clearMessages();

    try {
      final filePath = await _exportImagesUseCase.exportGradeAsZip(
        grade,
        customFileName: customFileName,
      );
      _setSuccessMessage('Successfully exported grade $grade to ZIP file');
      return filePath;
    } catch (e) {
      _setError('Failed to export grade $grade: ${e.toString()}');
      return null;
    } finally {
      _setExporting(false);
    }
  }

  /// Exports all stored images to directory structure
  Future<String?> exportToDirectory({String? customDirectoryName}) async {
    if (_isExporting) return null;

    _setExporting(true);
    _clearMessages();

    try {
      debugPrint('ViewModel: Starting export all images to directory');
      final dirPath = await _exportImagesUseCase.exportToDirectory(
        customDirectoryName: customDirectoryName,
      );
      debugPrint(
        'ViewModel: Export to directory completed successfully: $dirPath',
      );
      _setSuccessMessage('Successfully exported images to directory');
      return dirPath;
    } catch (e) {
      debugPrint('ViewModel: Export to directory failed: $e');
      _setError('Failed to export to directory: ${e.toString()}');
      return null;
    } finally {
      _setExporting(false);
    }
  }

  /// Updates confidence threshold for auto-storage
  void setConfidenceThreshold(double threshold) {
    if (threshold < 0.0 || threshold > 1.0) return;
    _confidenceThreshold = threshold;
    notifyListeners();
  }

  /// Toggles auto-storage feature
  void setAutoStoreEnabled(bool enabled) {
    _autoStoreEnabled = enabled;
    notifyListeners();
  }

  /// Checks if an image should be auto-stored based on current settings
  bool shouldAutoStore(double confidence) {
    return _autoStoreEnabled && confidence > _confidenceThreshold;
  }

  /// Gets storage location description
  Future<String> getStorageLocationDescription() async {
    try {
      // This would need to be implemented in the service
      return 'External Storage/ClassifiedImages/';
    } catch (e) {
      return 'Local Storage';
    }
  }

  /// Refreshes all data
  Future<void> refresh() async {
    await loadAllStoredImages();
    await loadExportPreview();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setStoring(bool storing) {
    _isStoring = storing;
    notifyListeners();
  }

  void _setExporting(bool exporting) {
    _isExporting = exporting;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    _error = null;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _successMessage = null;
  }

  /// Clears error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clears success message
  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }
}
