import 'package:flutter/foundation.dart';
import '../../entities/stored_image.dart';
import '../../entities/classification_result.dart';
import '../../repositories/image_storage_repository.dart';
import '../../../services/image_storage_service.dart';

/// Use case for storing classified images in organized grade folders
class StoreClassifiedImageUseCase {
  final ImageStorageRepository _repository;
  final ImageStorageService _storageService;

  StoreClassifiedImageUseCase(this._repository, this._storageService);

  /// Stores a classified image if it meets the confidence threshold
  ///
  /// Returns the StoredImage if successful, null if not stored (low confidence)
  /// Throws Exception if storage fails
  Future<StoredImage?> execute({
    required String originalImagePath,
    required ClassificationResult result,
    int? userId,
    required String model,
    double? confidenceThreshold,
    bool forceStore = false,
  }) async {
    try {
      debugPrint(
        'UseCase: Starting image storage for ${result.predictedLabel}',
      );
      debugPrint('UseCase: Original path: $originalImagePath');
      debugPrint(
        'UseCase: Confidence: ${result.confidence}, threshold: $confidenceThreshold',
      );

      // Validate inputs
      if (originalImagePath.trim().isEmpty) {
        throw ArgumentError('Original image path cannot be empty');
      }

      if (result.predictedLabel.trim().isEmpty) {
        throw ArgumentError('Predicted label cannot be empty');
      }

      if (model.trim().isEmpty) {
        throw ArgumentError('Model name cannot be empty');
      }

      // Check confidence threshold unless force storing
      final shouldStore = _storageService.shouldStoreImage(
        result.confidence,
        customThreshold: confidenceThreshold,
      );

      debugPrint(
        'UseCase: Should store image: $shouldStore (forceStore: $forceStore)',
      );

      if (!forceStore && !shouldStore) {
        debugPrint('UseCase: Image rejected due to low confidence');
        return null; // Don't store low confidence images
      }

      // Store the image file to organized folders
      debugPrint('UseCase: Calling storage service to store image');
      final storedImage = await _storageService.storeClassifiedImage(
        originalImagePath: originalImagePath,
        result: result,
        userId: userId,
        model: model,
        confidenceThreshold: confidenceThreshold,
      );

      if (storedImage == null) {
        debugPrint('UseCase: Storage service returned null');
        return null; // Service decided not to store
      }

      debugPrint(
        'UseCase: Image stored to ${storedImage.storedImagePath}, saving to database',
      );

      // Save metadata to database
      final id = await _repository.saveStoredImage(storedImage);

      debugPrint('UseCase: Image metadata saved to database with ID: $id');

      return storedImage.copyWith(id: id);
    } catch (e) {
      debugPrint('UseCase: Error storing image: $e');
      throw Exception('Failed to store classified image: ${e.toString()}');
    }
  }
}
