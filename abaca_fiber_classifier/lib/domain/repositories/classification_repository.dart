import '../entities/classification_result.dart';
import '../entities/model_info.dart';

abstract class ClassificationRepository {
  Future<ModelInfo> initializeModel();
  Future<List<String>> loadLabels();
  Future<String?> pickImage();
  Future<ClassificationResult> classifyImage(
    String imagePath,
    List<String> labels,
  );
  void dispose();
}
