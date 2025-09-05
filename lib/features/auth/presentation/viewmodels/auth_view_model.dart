import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/register_user_usecase.dart';
import '../../domain/usecases/login_user_usecase.dart';

/// ViewModel for handling authentication state and operations
///
/// This class manages the state for both registration and login processes,
/// providing reactive updates to the UI through ChangeNotifier.
class AuthViewModel extends ChangeNotifier {
  final RegisterUserUseCase _registerUserUseCase;
  final LoginUserUseCase _loginUserUseCase;

  AuthViewModel({
    required RegisterUserUseCase registerUserUseCase,
    required LoginUserUseCase loginUserUseCase,
  }) : _registerUserUseCase = registerUserUseCase,
       _loginUserUseCase = loginUserUseCase;

  // Loading states
  bool _isRegistering = false;
  bool _isLoggingIn = false;

  // Error states
  String? _registrationError;
  String? _loginError;

  // Success states
  bool _registrationSuccess = false;
  User? _loggedInUser;

  // Getters
  bool get isRegistering => _isRegistering;
  bool get isLoggingIn => _isLoggingIn;
  String? get registrationError => _registrationError;
  String? get loginError => _loginError;
  bool get registrationSuccess => _registrationSuccess;
  User? get loggedInUser => _loggedInUser;
  bool get isLoggedIn => _loggedInUser != null;

  /// Registers a new user
  ///
  /// Parameters:
  /// - [firstName]: User's first name
  /// - [lastName]: User's last name
  /// - [username]: Desired username
  /// - [password]: User's password
  ///
  /// Updates the UI state based on registration result
  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
  }) async {
    _isRegistering = true;
    _registrationError = null;
    _registrationSuccess = false;
    notifyListeners();

    try {
      await _registerUserUseCase.execute(
        firstName: firstName,
        lastName: lastName,
        username: username,
        password: password,
      );
      _registrationSuccess = true;
    } catch (e) {
      _registrationError = e.toString();
    }

    _isRegistering = false;
    notifyListeners();
  }

  /// Logs in a user
  ///
  /// Parameters:
  /// - [username]: User's username
  /// - [password]: User's password
  ///
  /// Updates the UI state based on login result
  Future<void> loginUser({
    required String username,
    required String password,
  }) async {
    _isLoggingIn = true;
    _loginError = null;
    notifyListeners();

    try {
      final user = await _loginUserUseCase.execute(
        username: username,
        password: password,
      );

      if (user != null) {
        _loggedInUser = user;
      } else {
        _loginError = 'Invalid username or password';
      }
    } catch (e) {
      _loginError = e.toString();
    }

    _isLoggingIn = false;
    notifyListeners();
  }

  /// Logs out the current user
  void logout() {
    _loggedInUser = null;
    _loginError = null;
    notifyListeners();
  }

  /// Clears registration error
  void clearRegistrationError() {
    if (_registrationError != null) {
      _registrationError = null;
      notifyListeners();
    }
  }

  /// Clears login error
  void clearLoginError() {
    if (_loginError != null) {
      _loginError = null;
      notifyListeners();
    }
  }

  /// Resets registration state
  void resetRegistrationState() {
    bool shouldNotify = false;

    if (_registrationError != null) {
      _registrationError = null;
      shouldNotify = true;
    }

    if (_registrationSuccess != false) {
      _registrationSuccess = false;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Resets all authentication state
  ///
  /// This method clears all authentication-related state including
  /// login status, errors, and registration state. It's useful when
  /// navigating between auth pages or when you want to ensure a
  /// clean state after registration.
  void resetAllAuthState() {
    _loggedInUser = null;
    _isRegistering = false;
    _isLoggingIn = false;
    _registrationError = null;
    _loginError = null;
    _registrationSuccess = false;
    // Only call notifyListeners once after all state changes
    notifyListeners();
  }

  /// Clears all form states and errors
  ///
  /// This method is specifically designed to be called after successful
  /// registration to ensure the login page starts with a clean state.
  void clearAllErrors() {
    bool shouldNotify = false;

    if (_registrationError != null) {
      _registrationError = null;
      shouldNotify = true;
    }

    if (_loginError != null) {
      _loginError = null;
      shouldNotify = true;
    }

    // Only notify if there were actually changes
    if (shouldNotify) {
      notifyListeners();
    }
  }
}
