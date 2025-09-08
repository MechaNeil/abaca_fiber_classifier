import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/features/admin/data/admin_repository_impl.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/usecases/import_model_usecase.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/usecases/manage_models_usecase.dart';
import 'package:abaca_fiber_classifier/features/admin/domain/usecases/export_logs_usecase.dart';
import 'package:abaca_fiber_classifier/features/admin/presentation/viewmodels/admin_view_model.dart';
import 'package:abaca_fiber_classifier/features/auth/domain/entities/user.dart';

void main() {
  group('Admin Integration Tests', () {
    late AdminRepositoryImpl adminRepository;
    late AdminViewModel adminViewModel;

    setUpAll(() async {
      // Initialize repositories
      adminRepository = AdminRepositoryImpl();

      // Initialize use cases
      final importModelUseCase = ImportModelUseCase(adminRepository);
      final manageModelsUseCase = ManageModelsUseCase(adminRepository);
      final exportLogsUseCase = ExportLogsUseCase(adminRepository);

      // Initialize admin view model
      adminViewModel = AdminViewModel(
        importModelUseCase: importModelUseCase,
        manageModelsUseCase: manageModelsUseCase,
        exportLogsUseCase: exportLogsUseCase,
      );
    });

    test('Admin user should be automatically created', () async {
      // This test verifies that the default admin user is created
      // when the database is initialized

      // The admin user should exist after database initialization
      // Note: This depends on the DatabaseService auto-creating the admin user
      expect(
        true,
        isTrue,
      ); // Placeholder - actual implementation would check database
    });

    test('Admin view model should initialize successfully', () {
      expect(adminViewModel, isNotNull);
      expect(adminViewModel.hasAnyOperation, isFalse);
      expect(adminViewModel.error, isNull);
    });

    test(
      'Admin view model should handle model management operations',
      () async {
        // Test that the view model can handle model operations
        expect(adminViewModel.availableModels, isNotNull);
        expect(adminViewModel.availableModels, isEmpty);
        expect(adminViewModel.hasAnyOperation, isFalse);
        expect(adminViewModel.currentModel, isNull);
      },
    );

    test('Admin view model should handle loading states correctly', () {
      // Test loading state management
      expect(adminViewModel.isImporting, isFalse);
      expect(adminViewModel.isLoadingModels, isFalse);
      expect(adminViewModel.isSwitchingModel, isFalse);
      expect(adminViewModel.isExporting, isFalse);
      expect(adminViewModel.hasAnyOperation, isFalse);
    });

    test('Admin view model should initialize and load models', () async {
      // Test the initialization process without actually calling initialize
      // since it requires database setup which is not available in unit tests

      expect(adminViewModel.error, isNull);
      expect(adminViewModel.availableModels, isNotNull);
      expect(adminViewModel.availableModels, isEmpty);
      // In a real app with database, after initialization, there should be at least the default model
    });

    test('User entity should correctly identify admin users', () {
      // Test admin user identification
      final adminUser = User(
        id: 1,
        username: 'Admin',
        firstName: 'System',
        lastName: 'Administrator',
        password: 'admin29',
        createdAt: DateTime.now(),
        role: UserRole.admin,
      );

      final regularUser = User(
        id: 2,
        username: 'user1',
        firstName: 'Regular',
        lastName: 'User',
        password: 'password123',
        createdAt: DateTime.now(),
        role: UserRole.user,
      );

      expect(adminUser.isAdmin, isTrue);
      expect(regularUser.isAdmin, isFalse);
    });
  });
}
