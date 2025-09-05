import '../../domain/entities/classification_result.dart';
import '../../domain/entities/model_info.dart';
import '../../domain/repositories/classification_repository.dart';
import '../../services/ml_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/asset_loader_service.dart';

class ClassificationRepositoryImpl implements ClassificationRepository {
  final MLService _mlService;
  final ImagePickerService _imagePickerService;
  final AssetLoaderService _assetLoaderService;

  ClassificationRepositoryImpl({
    required MLService mlService,
    required ImagePickerService imagePickerService,
    required AssetLoaderService assetLoaderService,
  }) : _mlService = mlService,
       _imagePickerService = imagePickerService,
       _assetLoaderService = assetLoaderService;

  @override
  Future<ModelInfo> initializeModel() async {
    try {
      return await _mlService.loadModel();
    } catch (e) {
      throw Exception('Failed to initialize model: $e');
    }
  }

  @override
  Future<List<String>> loadLabels() async {
    try {
      return await _assetLoaderService.loadLabels();
    } catch (e) {
      throw Exception('Failed to load labels: $e');
    }
  }

  @override
  Future<String?> pickImage() async {
    try {
      return await _imagePickerService.pickImageFromGallery();
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  @override
  Future<ClassificationResult> classifyImage(
    String imagePath,
    List<String> labels,
  ) async {
    try {
      return await _mlService.predict(imagePath, labels);
    } catch (e) {
      throw Exception('Failed to classify image: $e');
    }
  }

  @override
  void dispose() {
    _mlService.dispose();
  }
}
