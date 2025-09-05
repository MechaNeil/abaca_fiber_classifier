import '../entities/model_info.dart';
import '../repositories/classification_repository.dart';

class InitializeModelUseCase {
  final ClassificationRepository repository;

  InitializeModelUseCase(this.repository);

  Future<(ModelInfo, List<String>)> call() async {
    final modelInfo = await repository.initializeModel();
    final labels = await repository.loadLabels();
    return (modelInfo, labels);
  }
}
