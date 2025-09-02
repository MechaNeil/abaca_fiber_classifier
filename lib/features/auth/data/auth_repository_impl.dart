import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/auth_repository.dart';
import 'database_service.dart';

/// Implementation of [AuthRepository] using SQLite database
///
/// This class provides concrete implementations for user authentication operations
/// including registration, login, and user management using SQLite via sqflite.
///
/// Usage:
/// ```dart
/// final authRepo = AuthRepositoryImpl();
///
/// // Register a new user
/// final user = User(
///   firstName: 'John',
///   lastName: 'Doe',
///   username: 'johndoe',
///   password: 'hashedPassword',
///   createdAt: DateTime.now(),
/// );
/// final userId = await authRepo.registerUser(user);
///
/// // Login user
/// final loggedInUser = await authRepo.loginUser('johndoe', 'plainPassword');
/// ```
class AuthRepositoryImpl implements AuthRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  /// Registers a new user in the database
  ///
  /// Parameters:
  /// - [user]: The user object containing registration details
  ///
  /// Returns: The ID of the newly created user
  ///
  /// Throws: [DatabaseException] if username already exists or other database errors
  @override
  Future<int> registerUser(User user) async {
    final db = await _databaseService.database;

    // Check if username already exists
    final existingUser = await getUserByUsername(user.username);
    if (existingUser != null) {
      throw Exception('Username already exists');
    }

    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Authenticates a user with username and password
  ///
  /// Parameters:
  /// - [username]: The user's username
  /// - [password]: The user's password (plain text - will be verified against stored hash)
  ///
  /// Returns: [User] object if authentication successful, null otherwise
  @override
  Future<User?> loginUser(String username, String password) async {
    final db = await _databaseService.database;

    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final userMap = result.first;
      final storedHashedPassword = userMap['password'] as String;
      if (BCrypt.checkpw(password, storedHashedPassword)) {
        return User.fromMap(userMap);
      }
    }
    return null;
  }

  /// Retrieves a user by username
  ///
  /// Parameters:
  /// - [username]: The username to search for
  ///
  /// Returns: [User] object if found, null otherwise
  @override
  Future<User?> getUserByUsername(String username) async {
    final db = await _databaseService.database;

    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  /// Checks if a user with the given username exists
  ///
  /// Parameters:
  /// - [username]: The username to check
  ///
  /// Returns: true if user exists, false otherwise
  @override
  Future<bool> userExists(String username) async {
    final user = await getUserByUsername(username);
    return user != null;
  }

  /// Deletes a user from the database
  ///
  /// Parameters:
  /// - [id]: The ID of the user to delete
  ///
  /// Returns: void
  @override
  Future<void> deleteUser(int id) async {
    final db = await _databaseService.database;

    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieves all users from the database
  ///
  /// Returns: List of all [User] objects
  ///
  /// Note: This method should be used carefully in production as it returns
  /// all users including sensitive information like passwords
  @override
  Future<List<User>> getAllUsers() async {
    final db = await _databaseService.database;

    final result = await db.query('users', orderBy: 'createdAt DESC');

    return result.map((userMap) => User.fromMap(userMap)).toList();
  }
}
