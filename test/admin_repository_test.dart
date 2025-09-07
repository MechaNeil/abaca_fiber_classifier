import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/features/admin/data/admin_repository_impl.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/entities/model_entity.dart';

void main() {
  group('Admin Repository Unit Tests', () {
    late AdminRepositoryImpl adminRepository;

    setUp(() {
      adminRepository = AdminRepositoryImpl();
    });

    test('should instantiate admin repository', () {
      expect(adminRepository, isNotNull);
    });

    test('should handle model entity creation', () {
      final model = ModelEntity(
        name: 'Test Model',
        path: '/path/to/model.tflite',
        importedAt: DateTime.now(),
        isDefault: false,
        description: 'A test model',
      );

      expect(model.name, equals('Test Model'));
      expect(model.path, equals('/path/to/model.tflite'));
      expect(model.isDefault, isFalse);
      expect(model.description, equals('A test model'));
    });

    test('should identify default model correctly', () {
      final defaultModel = ModelEntity(
        name: 'Default Model',
        path: 'assets/mobilenetv3small_b2.tflite',
        importedAt: DateTime.now(),
        isDefault: true,
        description: 'Default TensorFlow Lite model',
      );

      final importedModel = ModelEntity(
        name: 'Imported Model',
        path: '/app/data/imported_model.tflite',
        importedAt: DateTime.now(),
        isDefault: false,
        description: 'User imported model',
      );

      expect(defaultModel.isDefault, isTrue);
      expect(importedModel.isDefault, isFalse);
    });
  });
}
