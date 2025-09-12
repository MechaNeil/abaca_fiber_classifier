import '../entities/stored_image.dart';

/// Repository interface for managing stored classified images
///
/// This repository handles database operations for tracking
/// stored images and their metadata.
abstract class ImageStorageRepository {
  // Basic CRUD operations
  Future<int> saveStoredImage(StoredImage storedImage);
  Future<StoredImage?> getStoredImageById(int id);
  Future<List<StoredImage>> getAllStoredImages();
  Future<bool> updateStoredImage(StoredImage storedImage);
  Future<bool> deleteStoredImage(int id);

  // Query operations by grade
  Future<List<StoredImage>> getStoredImagesByGrade(String grade);
  Future<Map<String, int>> getImageCountByGrade();

  // Query operations by user
  Future<List<StoredImage>> getStoredImagesByUser(int userId);

  // Query operations by model
  Future<List<StoredImage>> getStoredImagesByModel(String model);

  // Query operations by confidence
  Future<List<StoredImage>> getStoredImagesByConfidenceRange(
    double minConfidence,
    double maxConfidence,
  );

  // Query operations by date range
  Future<List<StoredImage>> getStoredImagesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  // Storage statistics
  Future<Map<String, dynamic>> getStorageStatistics();
  Future<int> getTotalStoredImagesCount();
  Future<int> getTotalStorageSizeBytes();

  // Cleanup operations
  Future<int> deleteStoredImagesByGrade(String grade);
  Future<int> deleteStoredImagesByUser(int userId);
  Future<int> deleteStoredImagesByModel(String model);
  Future<int> deleteOldStoredImages(DateTime cutoffDate);
  Future<int> deleteAllStoredImages();

  // File system synchronization
  Future<bool> verifyStoredImageExists(int id);
  Future<List<StoredImage>> findOrphanedDatabaseRecords();
  Future<int> cleanupOrphanedRecords();

  // Export support
  Future<List<StoredImage>> getStoredImagesForExport();
  Future<Map<String, List<StoredImage>>> getStoredImagesGroupedByGrade();
}
