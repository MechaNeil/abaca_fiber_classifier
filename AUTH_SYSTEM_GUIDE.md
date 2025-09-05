# Authentication System Implementation Guide

## Overview

This document provides a complete guide for the authentication system implemented in the Abaca Fiber Classifier app. The system includes user registration, login functionality, and SQLite database integration using sqflite 2.4.2.

## Features Implemented

### 1. User Interface Components

#### Registration Page

- **Location**: `lib/features/auth/presentation/pages/register_page.dart`
- **Features**:
  - Form fields for first name, last name, username, and password
  - Password confirmation field
  - Input validation
  - Loading states during registration
  - Success/error feedback
  - Navigation to login page

#### Login Page

- **Location**: `lib/features/auth/presentation/pages/login_page.dart`
- **Features**:
  - Username and password input fields
  - "Forgot password" placeholder link
  - Loading states during login
  - Error feedback for invalid credentials
  - Navigation to registration page

#### Custom UI Components

- **Custom Input Field**: Styled text input with password visibility toggle
- **Custom Button**: Consistent button styling with loading states
- **Logo Placeholder**: Eco-friendly icon placeholder matching the app theme

### 2. Database Integration

#### SQLite Setup

- **Database File**: `abaca_users.db`
- **Version**: 1.0 (with migration support for future versions)
- **Location**: Local device storage using sqflite

#### User Table Schema

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  createdAt INTEGER NOT NULL
);
```

### 3. Architecture Implementation

The authentication system follows Clean Architecture principles:

```
Features/Auth/
├── Data Layer
│   ├── database_service.dart       # SQLite database management
│   └── auth_repository_impl.dart   # Repository implementation
├── Domain Layer
│   ├── entities/user.dart          # User model
│   ├── repositories/auth_repository.dart  # Repository interface
│   └── usecases/                   # Business logic
│       ├── register_user_usecase.dart
│       └── login_user_usecase.dart
└── Presentation Layer
    ├── viewmodels/auth_view_model.dart   # State management
    ├── pages/                      # UI screens
    └── widgets/                    # Custom UI components
```

## Quick Start Guide

### 1. Running the Application

```bash
# Navigate to project directory
cd abaca_prototype_v1

# Get dependencies
flutter pub get

# Run the application
flutter run
```

### 2. Using the Authentication System

#### First Time User Registration

1. Launch the app
2. You'll see the Login page first
3. Tap "Register" at the bottom
4. Fill in all required fields:
   - First Name \*
   - Last Name \*
   - Username \*
   - Password \* (minimum 6 characters)
   - Confirm Password \*
5. Tap "Register" button
6. Upon successful registration, you'll be redirected to login

#### Existing User Login

1. From the Login page, enter your credentials:
   - Username
   - Password
2. Tap "Log in" button
3. Upon successful login, you'll access the main classification app

#### Using the Main App (After Login)

1. You'll see a welcome message with your name
2. User avatar and menu in the top-right corner
3. Tap the avatar to access user menu with logout option
4. All original classification features remain available

### 3. Logout Process

1. Tap the user avatar in the top-right corner
2. Select "Logout" from the dropdown menu
3. Confirm logout in the dialog
4. You'll be redirected back to the login page

## API Reference

### Authentication Methods

#### Registration

```dart
// Register a new user
final authViewModel = AuthViewModel(...);
await authViewModel.registerUser(
  firstName: 'John',
  lastName: 'Doe',
  username: 'johndoe',
  password: 'securePassword123',
);
```

#### Login

```dart
// Login existing user
await authViewModel.loginUser(
  username: 'johndoe',
  password: 'securePassword123',
);
```

#### Logout

```dart
// Logout current user
authViewModel.logout();
```

#### Check Authentication Status

```dart
// Check if user is logged in
if (authViewModel.isLoggedIn) {
  print('User is authenticated');
  print('Welcome ${authViewModel.loggedInUser?.firstName}');
}
```

### Database Operations

#### Direct Database Access (Advanced)

```dart
final authRepo = AuthRepositoryImpl();

// Check if username exists
bool exists = await authRepo.userExists('johndoe');

// Get user by username
User? user = await authRepo.getUserByUsername('johndoe');

// Get all users (admin function)
List<User> allUsers = await authRepo.getAllUsers();

// Delete user
await authRepo.deleteUser(userId);
```

## Validation Rules

### Input Validation

- **First Name**: Required, non-empty
- **Last Name**: Required, non-empty
- **Username**: Required, minimum 3 characters, unique
- **Password**: Required, minimum 6 characters
- **Password Confirmation**: Must match password field

### Database Constraints

- **Username**: Must be unique across all users
- **All Fields**: Cannot be null or empty

## Error Handling

### Common Error Messages

- "First name cannot be empty"
- "Last name cannot be empty"
- "Username cannot be empty"
- "Username must be at least 3 characters"
- "Password cannot be empty"
- "Password must be at least 6 characters long"
- "Passwords do not match"
- "Username already exists"
- "Invalid username or password"

### Error Display

- Registration errors: SnackBar with red background
- Login errors: SnackBar with red background
- Success messages: Alert dialog for registration success

## State Management

### AuthViewModel States

```dart
class AuthViewModel extends ChangeNotifier {
  // Loading states
  bool get isRegistering;
  bool get isLoggingIn;

  // Error states
  String? get registrationError;
  String? get loginError;

  // Success states
  bool get registrationSuccess;
  User? get loggedInUser;
  bool get isLoggedIn;
}
```

### UI Reactive Updates

The UI automatically updates based on state changes:

- Loading indicators during async operations
- Error messages display automatically
- Success navigation happens automatically
- Button states update based on loading status

## Security Considerations

### Current Implementation

- Passwords are stored in plain text (for prototype)
- Basic input validation
- SQLite database with local storage

### Production Recommendations

1. **Password Hashing**: Implement bcrypt or similar
2. **Input Sanitization**: Add SQL injection protection
3. **Session Management**: Implement JWT or similar tokens
4. **Encryption**: Encrypt sensitive data at rest
5. **Rate Limiting**: Prevent brute force attacks

## Customization Guide

### Changing UI Colors

Update the theme colors in `abaca_app.dart`:

```dart
theme: ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.green  // Change this color
),
```

### Adding New User Fields

1. Update the `User` entity
2. Modify the database schema
3. Update UI forms
4. Adjust validation rules

### Custom Validation Rules

Modify the use cases:

```dart
class RegisterUserUseCase {
  Future<int> execute({...}) async {
    // Add custom validation here
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }
    // ...
  }
}
```

## Troubleshooting

### Common Issues

1. **Database Connection Errors**

   - Ensure proper permissions for file access
   - Check if database path is accessible

2. **UI Not Updating**

   - Verify ChangeNotifier listeners are properly set up
   - Ensure `notifyListeners()` is called after state changes

3. **Navigation Issues**

   - Check route definitions
   - Ensure proper context passing

4. **Build Errors**
   - Run `flutter clean && flutter pub get`
   - Check for missing imports

### Debug Information

Enable debug logging:

```dart
// In database_service.dart
await Sqflite.setDebugModeOn(true);
```

## Future Enhancements

### Planned Features

1. **Password Reset**: Email-based password recovery
2. **User Profiles**: Extended user information
3. **Session Persistence**: Remember login across app restarts
4. **Social Authentication**: Google/Facebook login
5. **Multi-factor Authentication**: SMS or email verification
6. **User Roles**: Admin vs regular user permissions

### Database Migrations

Example for adding email field:

```dart
Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
  }
}
```

## Support

For issues or questions regarding the authentication system:

1. Check the error messages and logs
2. Review the SQLite documentation: `SQFLITE_DOCUMENTATION.md`
3. Verify the implementation follows the examples in this guide
4. Test with clean database by clearing app data

## Conclusion

This authentication system provides a solid foundation for user management in the Abaca Fiber Classifier app. The modular architecture makes it easy to extend and customize based on specific requirements while maintaining clean separation of concerns.

The system is ready for development and testing. For production deployment, implement the security recommendations mentioned in this guide.
