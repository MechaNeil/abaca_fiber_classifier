# SQLite Database Integration with sqflite 2.4.2

## Overview

This project uses SQLite as the local database solution for user authentication and data persistence. The implementation follows clean architecture principles with proper separation of concerns.

## Setup and Configuration

### Dependencies

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  sqflite: 2.4.2
  path: ^1.8.3
```

### Project Structure

```
lib/
  features/
    auth/
      data/
        database_service.dart          # Database configuration and management
        auth_repository_impl.dart      # Repository implementation
      domain/
        entities/
          user.dart                    # User entity/model
        repositories/
          auth_repository.dart         # Repository interface
        usecases/
          register_user_usecase.dart   # Registration business logic
          login_user_usecase.dart      # Login business logic
      presentation/
        viewmodels/
          auth_view_model.dart         # UI state management
        pages/
          login_page.dart             # Login UI
          register_page.dart          # Registration UI
          auth_wrapper.dart           # Authentication wrapper
        widgets/
          custom_input_field.dart     # Custom input components
          custom_button.dart          # Custom button components
          logo_placeholder.dart       # Logo component
```

## Core Components

### 1. Database Service (`database_service.dart`)

The `DatabaseService` class manages the SQLite database connection and operations:

```dart
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // Singleton pattern implementation
  DatabaseService._init();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('abaca_users.db');
    return _database!;
  }
}
```

#### Key Features:

- **Singleton Pattern**: Ensures only one database instance
- **Lazy Initialization**: Database is created only when needed
- **Automatic Schema Creation**: Creates tables on first run
- **Version Management**: Supports database migrations

#### Database Schema

The `users` table structure:

| Column    | Type    | Constraints               | Description                        |
| --------- | ------- | ------------------------- | ---------------------------------- |
| id        | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique user identifier             |
| firstName | TEXT    | NOT NULL                  | User's first name                  |
| lastName  | TEXT    | NOT NULL                  | User's last name                   |
| username  | TEXT    | NOT NULL UNIQUE           | Unique username for login          |
| password  | TEXT    | NOT NULL                  | User's password (should be hashed) |
| createdAt | INTEGER | NOT NULL                  | Timestamp when user was created    |

### 2. User Entity (`user.dart`)

The `User` class represents the data model:

```dart
class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final DateTime createdAt;

  // Converts User object to Map for database storage
  Map<String, dynamic> toMap() { ... }

  // Creates User object from database Map
  factory User.fromMap(Map<String, dynamic> map) { ... }
}
```

### 3. Repository Implementation (`auth_repository_impl.dart`)

Implements the repository pattern for data access:

```dart
class AuthRepositoryImpl implements AuthRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  Future<int> registerUser(User user) async {
    final db = await _databaseService.database;
    return await db.insert('users', user.toMap());
  }

  @override
  Future<User?> loginUser(String username, String password) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty ? User.fromMap(result.first) : null;
  }
}
```

## Usage Examples

### Basic Operations

#### 1. Initialize Database

```dart
// Database is automatically initialized when first accessed
final dbService = DatabaseService.instance;
final db = await dbService.database; // Creates database if it doesn't exist
```

#### 2. Register a New User

```dart
final authRepo = AuthRepositoryImpl();

final user = User(
  firstName: 'John',
  lastName: 'Doe',
  username: 'johndoe',
  password: 'hashedPassword123', // Should be hashed in production
  createdAt: DateTime.now(),
);

try {
  final userId = await authRepo.registerUser(user);
  print('User registered with ID: $userId');
} catch (e) {
  print('Registration failed: $e');
}
```

#### 3. Login User

```dart
final authRepo = AuthRepositoryImpl();

try {
  final user = await authRepo.loginUser('johndoe', 'hashedPassword123');
  if (user != null) {
    print('Login successful: ${user.firstName} ${user.lastName}');
  } else {
    print('Invalid credentials');
  }
} catch (e) {
  print('Login failed: $e');
}
```

#### 4. Check if User Exists

```dart
final authRepo = AuthRepositoryImpl();

final exists = await authRepo.userExists('johndoe');
if (exists) {
  print('Username already taken');
} else {
  print('Username available');
}
```

#### 5. Get User by Username

```dart
final authRepo = AuthRepositoryImpl();

final user = await authRepo.getUserByUsername('johndoe');
if (user != null) {
  print('Found user: ${user.firstName} ${user.lastName}');
}
```

#### 6. Get All Users

```dart
final authRepo = AuthRepositoryImpl();

final users = await authRepo.getAllUsers();
print('Total users: ${users.length}');
for (final user in users) {
  print('${user.username}: ${user.firstName} ${user.lastName}');
}
```

#### 7. Delete User

```dart
final authRepo = AuthRepositoryImpl();

await authRepo.deleteUser(userId);
print('User deleted successfully');
```

### UI Integration

#### Using with View Model

```dart
class AuthViewModel extends ChangeNotifier {
  final RegisterUserUseCase _registerUserUseCase;
  final LoginUserUseCase _loginUserUseCase;

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
  }) async {
    try {
      await _registerUserUseCase.execute(
        firstName: firstName,
        lastName: lastName,
        username: username,
        password: password,
      );
      // Handle success
    } catch (e) {
      // Handle error
    }
  }
}
```

#### Using in Flutter Widgets

```dart
class LoginPage extends StatefulWidget {
  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return Scaffold(
          body: Column(
            children: [
              TextField(controller: usernameController),
              TextField(controller: passwordController),
              ElevatedButton(
                onPressed: viewModel.isLoading ? null : () {
                  viewModel.loginUser(
                    username: usernameController.text,
                    password: passwordController.text,
                  );
                },
                child: Text('Login'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## Advanced Features

### Database Migrations

To handle schema changes in future versions:

```dart
Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add new column in version 2
    await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
  }
  if (oldVersion < 3) {
    // Add new table in version 3
    await db.execute('''
      CREATE TABLE user_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        sessionToken TEXT NOT NULL,
        expiresAt INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }
}
```

### Custom Queries

For complex database operations:

```dart
class AuthRepositoryImpl {
  Future<List<User>> getUsersCreatedAfter(DateTime date) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'users',
      where: 'createdAt > ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<int> getUserCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
```

### Transaction Support

For atomic operations:

```dart
Future<void> transferUserData(int fromUserId, int toUserId) async {
  final db = await _databaseService.database;

  await db.transaction((txn) async {
    // Delete old user
    await txn.delete('users', where: 'id = ?', whereArgs: [fromUserId]);

    // Update references to new user
    await txn.update(
      'user_sessions',
      {'userId': toUserId},
      where: 'userId = ?',
      whereArgs: [fromUserId],
    );
  });
}
```

## Best Practices

### 1. Password Security

```dart
import 'package:crypto/crypto.dart';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

// Use when registering/logging in
final hashedPassword = hashPassword(plainTextPassword);
```

### 2. Error Handling

```dart
try {
  final user = await authRepo.registerUser(user);
} on DatabaseException catch (e) {
  if (e.isUniqueConstraintError()) {
    throw Exception('Username already exists');
  } else {
    throw Exception('Database error: ${e.toString()}');
  }
} catch (e) {
  throw Exception('Unexpected error: ${e.toString()}');
}
```

### 3. Input Validation

```dart
class RegisterUserUseCase {
  Future<int> execute({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
  }) async {
    // Validate input
    if (firstName.trim().isEmpty) {
      throw Exception('First name cannot be empty');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    // Proceed with registration
    final user = User(...);
    return await _authRepository.registerUser(user);
  }
}
```

### 4. Database Cleanup

```dart
class DatabaseService {
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
  }

  Future<bool> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'abaca_users.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Database Locked Error**

   - Ensure you're not calling database operations simultaneously
   - Use proper connection management

2. **Schema Migration Failures**

   - Always backup data before migrations
   - Test migrations thoroughly

3. **Performance Issues**
   - Add indexes for frequently queried columns
   - Use transactions for bulk operations
   - Limit result sets with pagination

### Debug Information

```dart
// Enable database logging
await Sqflite.setDebugModeOn(true);

// Check database path
final dbPath = await getDatabasesPath();
print('Database path: $dbPath');

// Verify table structure
final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
print('Tables: $tables');
```

## Conclusion

This SQLite implementation provides a robust foundation for local data storage in your Flutter application. The architecture is scalable and maintainable, following clean architecture principles while providing excellent performance for user authentication and data management.

For production use, consider additional features like:

- Password hashing and salting
- Session management
- Data encryption for sensitive information
- Backup and restore functionality
- Performance monitoring and optimization
