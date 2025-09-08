import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/features/auth/domain/entities/user.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  group('Admin User Entity Tests', () {
    test('should create admin user with correct properties', () {
      // Arrange
      final hashedPassword = BCrypt.hashpw('admin29', BCrypt.gensalt());

      // Act
      final adminUser = User(
        firstName: 'Admin',
        lastName: 'User',
        username: 'admin',
        password: hashedPassword,
        createdAt: DateTime.now(),
        role: UserRole.admin,
      );

      // Assert
      expect(adminUser.username, 'admin');
      expect(adminUser.firstName, 'Admin');
      expect(adminUser.lastName, 'User');
      expect(adminUser.role, UserRole.admin);
      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.password, isNot('admin29')); // Should be hashed
      expect(
        BCrypt.checkpw('admin29', adminUser.password),
        isTrue,
      ); // Password should verify
    });

    test('should identify admin role correctly', () {
      // Arrange & Act
      final adminUser = User(
        firstName: 'Admin',
        lastName: 'User',
        username: 'admin',
        password: 'hashedPassword',
        createdAt: DateTime.now(),
        role: UserRole.admin,
      );

      final regularUser = User(
        firstName: 'John',
        lastName: 'Doe',
        username: 'johndoe',
        password: 'hashedPassword',
        createdAt: DateTime.now(),
        role: UserRole.user,
      );

      // Assert
      expect(adminUser.isAdmin, isTrue);
      expect(regularUser.isAdmin, isFalse);
    });

    test('should convert admin user to map correctly', () {
      // Arrange
      final now = DateTime.now();
      final adminUser = User(
        id: 1,
        firstName: 'Admin',
        lastName: 'User',
        username: 'admin',
        password: 'hashedPassword',
        createdAt: now,
        role: UserRole.admin,
      );

      // Act
      final userMap = adminUser.toMap();

      // Assert
      expect(userMap['id'], 1);
      expect(userMap['firstName'], 'Admin');
      expect(userMap['lastName'], 'User');
      expect(userMap['username'], 'admin');
      expect(userMap['password'], 'hashedPassword');
      expect(userMap['createdAt'], now.millisecondsSinceEpoch);
      expect(userMap['role'], 'admin');
    });

    test('should create admin user from map correctly', () {
      // Arrange
      final now = DateTime.now();
      final userMap = {
        'id': 1,
        'firstName': 'Admin',
        'lastName': 'User',
        'username': 'admin',
        'password': 'hashedPassword',
        'createdAt': now.millisecondsSinceEpoch,
        'role': 'admin',
      };

      // Act
      final adminUser = User.fromMap(userMap);

      // Assert
      expect(adminUser.id, 1);
      expect(adminUser.firstName, 'Admin');
      expect(adminUser.lastName, 'User');
      expect(adminUser.username, 'admin');
      expect(adminUser.password, 'hashedPassword');
      expect(
        adminUser.createdAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      expect(adminUser.role, UserRole.admin);
      expect(adminUser.isAdmin, isTrue);
    });
  });
}
