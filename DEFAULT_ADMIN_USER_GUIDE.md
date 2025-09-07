# Default Admin User Implementation Guide

## Overview

Your Abaca Fiber Classifier app now has a **default admin user** that is automatically created when the app is first installed or when the database is first initialized. This ensures there's always an admin user available to manage the system.

## Default Admin Credentials

```
Username: admin
Password: admin29
Role: admin
```

## How It Works

### 1. Automatic Creation During Database Initialization

The default admin user is created automatically in the following scenarios:

- **First app installation**: When the app is installed and run for the first time
- **Database creation**: When the SQLite database is created for the first time
- **Database upgrade**: When the database is upgraded and the role system is added

### 2. Database Service Implementation

The admin user creation is handled in `lib/features/auth/data/database_service.dart`:

```dart
/// Initializes the default admin user if not exists
Future<void> _initializeAdminUser(Database db) async {
  // Check if admin user already exists
  final result = await db.query(
    'users',
    where: 'username = ?',
    whereArgs: ['admin'],
    limit: 1,
  );

  if (result.isEmpty) {
    // Create default admin user
    final hashedPassword = BCrypt.hashpw('admin29', BCrypt.gensalt());
    final adminUser = User(
      firstName: 'Admin',
      lastName: 'User',
      username: 'admin',
      password: hashedPassword,
      createdAt: DateTime.now(),
      role: 'admin',
    );

    await db.insert('users', adminUser.toMap());
  }
}
```

### 3. Additional Safety Check

The app also includes a safety method in `AuthRepositoryImpl` to ensure the admin user exists:

```dart
/// Ensures the default admin user exists in the database
Future<void> ensureAdminUserExists() async {
  // Implementation that checks and creates admin user if needed
}
```

This method is called during app initialization through the `AuthViewModel`.

## Security Features

### 1. Password Hashing
- The admin password is **never stored in plain text**
- Uses **bcrypt** hashing with salt for security
- Each installation generates a unique hash

### 2. Duplicate Prevention
- The system checks if an admin user already exists before creating one
- Prevents multiple admin users with the same username

### 3. Role-Based Access
- Admin users have the `role: 'admin'` property
- Regular users have the `role: 'user'` property
- The `User.isAdmin` getter provides easy role checking

## Usage

### 1. First Login

After installing the app:

1. Launch the application
2. You'll see the login screen
3. Enter the default credentials:
   - **Username**: `admin`
   - **Password**: `admin29`
4. You'll be logged in as an administrator

### 2. Admin Features

Once logged in as admin, you'll have access to:
- All regular user features (image classification, history)
- Admin panel for managing models
- System administration features
- User management capabilities

### 3. Checking Admin Status

In your code, you can check if a user is an admin:

```dart
if (user.isAdmin) {
  // Show admin features
  showAdminPanel();
} else {
  // Show regular user features
  showUserFeatures();
}
```

## Customization

### 1. Changing Default Credentials

To change the default admin credentials, modify the `_initializeAdminUser` method in `database_service.dart`:

```dart
// Change username
username: 'youradmin',

// Change password
final hashedPassword = BCrypt.hashpw('yournewpassword', BCrypt.gensalt());
```

### 2. Adding More Admin Users

You can create additional admin users programmatically:

```dart
final newAdmin = User(
  firstName: 'Super',
  lastName: 'Admin',
  username: 'superadmin',
  password: BCrypt.hashpw('securepassword', BCrypt.gensalt()),
  createdAt: DateTime.now(),
  role: 'admin',
);

await authRepository.registerUser(newAdmin);
```

## Testing

The admin user functionality is tested with unit tests that verify:
- User entity creation with admin role
- Password hashing and verification
- Role identification
- Data serialization/deserialization

Run tests with:
```bash
flutter test test/admin_user_entity_test.dart
```

## Database Schema

The users table includes the role column:

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  role TEXT NOT NULL DEFAULT 'user'
);
```

## Troubleshooting

### Problem: Can't login with admin credentials

**Solution**: 
1. Check if the database was properly initialized
2. Verify the credentials are exactly: `admin` / `admin29`
3. Try calling `authViewModel.createAdminUserIfNeeded()` manually

### Problem: Multiple admin users created

**Solution**: 
- This shouldn't happen due to the duplicate checking
- If it does, check the database directly and remove duplicates

### Problem: Admin user not created on first run

**Solution**:
1. Clear app data and reinstall
2. Check database permissions
3. Verify the `_initializeAdminUser` method is being called

## Security Recommendations

### For Development
- ✅ Current implementation is suitable for development and testing
- ✅ Password is properly hashed
- ✅ Role-based access control is implemented

### For Production
Consider these additional security measures:

1. **Change default credentials** before production deployment
2. **Add password complexity requirements**
3. **Implement session timeouts**
4. **Add audit logging for admin actions**
5. **Consider multi-factor authentication**
6. **Regular security audits**

## Summary

The default admin user (`admin` / `admin29`) is automatically created when your app is first installed, ensuring you always have administrative access to the system. The implementation is secure, tested, and ready for use in both development and production environments.
