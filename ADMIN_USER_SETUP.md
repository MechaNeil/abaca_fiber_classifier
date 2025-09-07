# Admin User Setup Guide

## Overview

The Abaca Fiber Classifier app automatically creates a default admin user during the initial database setup. This ensures that there's always an admin account available for accessing administrative features, even on fresh installations.

## Default Admin Credentials

The default admin user is created with the following credentials:

- **Username**: `admin`
- **Password**: `admin29`
- **Role**: `admin`
- **First Name**: `Admin`
- **Last Name**: `User`

## How It Works

### Automatic Creation

The admin user is automatically created in the following scenarios:

1. **Fresh Installation**: When the app is installed for the first time and the database is created
2. **Database Upgrade**: When upgrading from an older version that didn't have the role system
3. **Manual Verification**: When the AuthViewModel is initialized, it verifies the admin user exists

### Implementation Details

The admin user creation is handled by:

1. **Database Service** (`database_service.dart`):
   - `_initializeAdminUser()` method creates the admin user during database creation
   - Called in `_createDB()` and `_upgradeDB()` methods

2. **Auth Repository** (`auth_repository_impl.dart`):
   - `ensureAdminUserExists()` method provides manual verification
   - Uses bcrypt to hash the password securely

3. **Auth ViewModel** (`auth_view_model.dart`):
   - Automatically calls admin user verification during initialization
   - Provides `createAdminUserIfNeeded()` for manual admin user creation

## Security Considerations

### Password Hashing

The admin password is securely hashed using bcrypt before storage:

```dart
final hashedPassword = BCrypt.hashpw('admin29', BCrypt.gensalt());
```

### Recommended Changes for Production

**⚠️ IMPORTANT: Change the default admin password before deploying to production!**

To change the default admin credentials:

1. Modify the `_initializeAdminUser` method in `database_service.dart`
2. Update the `ensureAdminUserExists` method in `auth_repository_impl.dart`
3. Consider adding a password change requirement on first login

Example modification:

```dart
Future<void> _initializeAdminUser(Database db) async {
  // Check if admin user already exists
  final result = await db.query(
    'users',
    where: 'username = ?',
    whereArgs: ['admin'],
    limit: 1,
  );

  if (result.isEmpty) {
    // Create default admin user with STRONG password
    final hashedPassword = BCrypt.hashpw('YourStrongAdminPassword123!', BCrypt.gensalt());
    final adminUser = User(
      firstName: 'Administrator',
      lastName: 'System',
      username: 'admin',
      password: hashedPassword,
      createdAt: DateTime.now(),
      role: 'admin',
    );

    await db.insert('users', adminUser.toMap());
  }
}
```

## Usage Instructions

### Logging in as Admin

1. Open the app
2. On the login screen, enter:
   - Username: `admin`
   - Password: `admin29`
3. Tap "Log in"
4. You'll have access to admin features

### Admin Features Available

Once logged in as admin, you can access:

- **Model Management**: Import, export, and manage ML models
- **User Management**: View all users (future feature)
- **Data Export**: Export classification logs and history
- **System Administration**: Advanced app settings

## Troubleshooting

### Admin User Not Found

If you can't log in with the admin credentials:

1. **Check Database**: The admin user should be created automatically
2. **Manual Creation**: Use the `createAdminUserIfNeeded()` method
3. **Database Reset**: Clear app data to trigger fresh database creation

### Forgotten Admin Password

If you've changed the admin password and forgotten it:

1. **Database Access**: Directly modify the database (advanced users)
2. **App Reset**: Clear app data and reinstall
3. **Code Modification**: Temporarily modify the initialization code

### Manual Admin User Creation

You can manually trigger admin user creation:

```dart
// In your code, call this method
await authViewModel.createAdminUserIfNeeded();
```

## Database Schema

The admin user is stored in the `users` table with the following structure:

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

Admin users have `role = 'admin'` while regular users have `role = 'user'`.

## Best Practices

### For Development

1. Keep the default credentials for easy testing
2. Document any changes to default credentials
3. Test admin functionality regularly

### For Production

1. **Change default credentials immediately**
2. **Use strong passwords**
3. **Consider implementing password change requirements**
4. **Monitor admin access logs**
5. **Implement additional security measures** (2FA, session timeout, etc.)

## Code References

Key files related to admin user setup:

- `lib/features/auth/data/database_service.dart` - Database initialization
- `lib/features/auth/data/auth_repository_impl.dart` - Admin user verification
- `lib/features/auth/presentation/viewmodels/auth_view_model.dart` - Automatic setup
- `lib/features/auth/domain/entities/user.dart` - User model with role support

## Future Enhancements

Planned improvements for admin user management:

1. **Password Change API**: Allow changing admin password through UI
2. **Multiple Admin Users**: Support for multiple admin accounts
3. **Role-based Permissions**: Granular permission system
4. **Admin User Management UI**: Interface for managing admin accounts
5. **Security Audit Logs**: Track admin actions and login attempts

---

**Note**: This system ensures that you'll always have admin access to your app, regardless of how it's installed or deployed. The admin user is created automatically and securely, providing a reliable way to access administrative features.
