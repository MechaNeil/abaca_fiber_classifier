import '../../../services/image_storage_service.dart';
import '../../repositories/image_storage_repository.dart';

/// Use case for clearing stored images
class ClearStoredImagesUseCase {
  final ImageStorageService _imageStorageService;
  final ImageStorageRepository _imageStorageRepository;

  ClearStoredImagesUseCase({
    required ImageStorageService imageStorageService,
    required ImageStorageRepository imageStorageRepository,
  }) : _imageStorageService = imageStorageService,
       _imageStorageRepository = imageStorageRepository;

  /// Clears all stored images from all grades
  /// Returns the number of images deleted from file system
  Future<int> clearAllImages() async {
    // Clear files from file system
    final filesDeleted = await _imageStorageService.clearAllStoredImages();

    // Clear database records
    await _imageStorageRepository.deleteAllStoredImages();

    return filesDeleted;
  }

  /// Clears images for a specific grade
  /// Returns the number of images deleted from file system
  Future<int> clearGradeImages(String grade) async {
    // Clear files from file system
    final filesDeleted = await _imageStorageService.clearGradeImages(grade);

    // Clear database records for the grade
    await _imageStorageRepository.deleteStoredImagesByGrade(grade);

    return filesDeleted;
  }
}
