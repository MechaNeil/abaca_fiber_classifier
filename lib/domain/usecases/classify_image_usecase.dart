import '../entities/classification_result.dart';
import '../repositories/classification_repository.dart';

class ClassifyImageUseCase {
  final ClassificationRepository repository;

  ClassifyImageUseCase(this.repository);

  Future<ClassificationResult> call(
    String imagePath,
    List<String> labels,
  ) async {
    return await repository.classifyImage(imagePath, labels);
  }
}
