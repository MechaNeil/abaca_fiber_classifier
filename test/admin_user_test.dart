import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/features/auth/data/auth_repository_impl.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  group('Admin User Tests', () {
    late AuthRepositoryImpl authRepository;

    setUp(() {
      authRepository = AuthRepositoryImpl();
    });

    test('should create default admin user automatically', () async {
      // Act: The admin user should be created automatically when the database is initialized
      // This happens when we first access the database through the repository
      await authRepository.ensureAdminUserExists();

      // Assert: Admin user should exist
      final adminUser = await authRepository.getUserByUsername('admin');

      expect(adminUser, isNotNull);
      expect(adminUser!.username, 'admin');
      expect(adminUser.firstName, 'Admin');
      expect(adminUser.lastName, 'User');
      expect(adminUser.role, 'admin');
      expect(adminUser.isAdmin, isTrue);
    });

    test('should be able to login with default admin credentials', () async {
      // Arrange: Ensure admin user exists
      await authRepository.ensureAdminUserExists();

      // Act: Try to login with default credentials
      final loggedInUser = await authRepository.loginUser('admin', 'admin29');

      // Assert: Login should be successful
      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.username, 'admin');
      expect(loggedInUser.isAdmin, isTrue);
    });

    test('should not create duplicate admin users', () async {
      // Arrange: Ensure admin user exists
      await authRepository.ensureAdminUserExists();

      // Act: Try to create admin user again
      await authRepository.ensureAdminUserExists();

      // Assert: Should still have only one admin user
      final allUsers = await authRepository.getAllUsers();
      final adminUsers = allUsers
          .where((user) => user.username == 'admin')
          .toList();

      expect(adminUsers.length, 1);
    });

    test('should fail login with wrong admin password', () async {
      // Arrange: Ensure admin user exists
      await authRepository.ensureAdminUserExists();

      // Act: Try to login with wrong password
      final loggedInUser = await authRepository.loginUser(
        'admin',
        'wrongpassword',
      );

      // Assert: Login should fail
      expect(loggedInUser, isNull);
    });

    test('admin password should be properly hashed', () async {
      // Arrange: Ensure admin user exists
      await authRepository.ensureAdminUserExists();

      // Act: Get admin user from database
      final adminUser = await authRepository.getUserByUsername('admin');

      // Assert: Password should be hashed, not plain text
      expect(adminUser, isNotNull);
      expect(adminUser!.password, isNot('admin29')); // Should not be plain text
      expect(
        adminUser.password.startsWith('\$2'),
        isTrue,
      ); // Should be bcrypt hash

      // Verify password can be verified with bcrypt
      final isValidPassword = BCrypt.checkpw('admin29', adminUser.password);
      expect(isValidPassword, isTrue);
    });
  });
}
