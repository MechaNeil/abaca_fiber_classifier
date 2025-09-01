import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import 'package:bcrypt/bcrypt.dart';

/// Use case for user registration
///
/// This use case handles the business logic for registering a new user.
/// It validates input data and delegates the actual registration to the repository.
class RegisterUserUseCase {
  final AuthRepository _authRepository;

  RegisterUserUseCase(this._authRepository);

  /// Executes the user registration process
  ///
  /// Parameters:
  /// - [firstName]: User's first name
  /// - [lastName]: User's last name
  /// - [username]: Desired username
  /// - [password]: User's password
  ///
  /// Returns: The ID of the newly registered user
  ///
  /// Throws: [Exception] if validation fails or registration errors occur
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
    if (lastName.trim().isEmpty) {
      throw Exception('Last name cannot be empty');
    }
    if (username.trim().isEmpty) {
      throw Exception('Username cannot be empty');
    }
    if (password.trim().isEmpty) {
      throw Exception('Password cannot be empty');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    // Hash the password using bcrypt
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    // Create user object
    final user = User(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      username: username.trim().toLowerCase(),
      password: hashedPassword,
      createdAt: DateTime.now(),
    );

    // Register user
    return await _authRepository.registerUser(user);
  }
}
