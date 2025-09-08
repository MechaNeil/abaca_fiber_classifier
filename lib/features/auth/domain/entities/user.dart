enum UserRole { admin, user }

extension UserRoleExtension on UserRole {
  String get name => toString().split('.').last;

  static UserRole fromString(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final DateTime createdAt;
  final UserRole role;

  const User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.createdAt,
    this.role = UserRole.user,
  });

  bool get isAdmin => role == UserRole.admin;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'password': password,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'role': role.name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      username: map['username'],
      password: map['password'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      role: map['role'] != null
          ? UserRoleExtension.fromString(map['role'])
          : UserRole.user,
    );
  }

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    DateTime? createdAt,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, firstName: $firstName, lastName: $lastName, username: $username, role: ${role.name}, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.username == username &&
        other.password == password &&
        other.createdAt == createdAt &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        username.hashCode ^
        password.hashCode ^
        createdAt.hashCode ^
        role.hashCode;
  }
}
