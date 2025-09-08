import '../entities/model_info.dart';
import '../repositories/classification_repository.dart';

class ReloadModelUseCase {
  final ClassificationRepository repository;

  ReloadModelUseCase(this.repository);

  Future<(ModelInfo, List<String>)> call() async {
    final modelInfo = await repository.reloadModel();
    final labels = await repository.loadLabels();
    return (modelInfo, labels);
  }
}
