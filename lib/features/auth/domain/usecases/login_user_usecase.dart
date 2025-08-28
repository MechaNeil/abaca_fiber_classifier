import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login
///
/// This use case handles the business logic for user authentication.
/// It validates credentials and delegates the authentication to the repository.
class LoginUserUseCase {
  final AuthRepository _authRepository;

  LoginUserUseCase(this._authRepository);

  /// Executes the user login process
  ///
  /// Parameters:
  /// - [username]: User's username
  /// - [password]: User's password
  ///
  /// Returns: [User] object if login successful, null otherwise
  ///
  /// Throws: [Exception] if validation fails
  Future<User?> execute({
    required String username,
    required String password,
  }) async {
    // Validate input
    if (username.trim().isEmpty) {
      throw Exception('Username cannot be empty');
    }
    if (password.trim().isEmpty) {
      throw Exception('Password cannot be empty');
    }

    // Attempt login
    return await _authRepository.loginUser(
      username.trim().toLowerCase(),
      password, // In production, hash this password before comparison
    );
  }
}
