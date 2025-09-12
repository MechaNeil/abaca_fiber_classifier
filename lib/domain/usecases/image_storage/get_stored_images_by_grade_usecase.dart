import '../../entities/stored_image.dart';
import '../../repositories/image_storage_repository.dart';

/// Use case for retrieving stored images by grade
class GetStoredImagesByGradeUseCase {
  final ImageStorageRepository _repository;

  GetStoredImagesByGradeUseCase(this._repository);

  /// Gets all stored images for a specific grade
  Future<List<StoredImage>> execute(String grade) async {
    try {
      if (grade.trim().isEmpty) {
        throw ArgumentError('Grade cannot be empty');
      }

      return await _repository.getStoredImagesByGrade(grade);
    } catch (e) {
      throw Exception('Failed to get stored images by grade: ${e.toString()}');
    }
  }

  /// Gets stored images for multiple grades
  Future<Map<String, List<StoredImage>>> executeForMultipleGrades(
    List<String> grades,
  ) async {
    try {
      final result = <String, List<StoredImage>>{};

      for (final grade in grades) {
        result[grade] = await execute(grade);
      }

      return result;
    } catch (e) {
      throw Exception(
        'Failed to get stored images for multiple grades: ${e.toString()}',
      );
    }
  }

  /// Gets all stored images grouped by grade
  Future<Map<String, List<StoredImage>>> executeGroupedByGrade() async {
    try {
      return await _repository.getStoredImagesGroupedByGrade();
    } catch (e) {
      throw Exception(
        'Failed to get stored images grouped by grade: ${e.toString()}',
      );
    }
  }
}
