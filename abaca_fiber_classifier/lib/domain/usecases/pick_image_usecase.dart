import '../repositories/classification_repository.dart';

class PickImageUseCase {
  final ClassificationRepository repository;

  PickImageUseCase(this.repository);

  Future<String?> call() async {
    return await repository.pickImage();
  }
}
