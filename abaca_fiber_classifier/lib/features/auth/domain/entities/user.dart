class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final DateTime createdAt;

  const User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'password': password,
      'createdAt': createdAt.millisecondsSinceEpoch,
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
    );
  }

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, firstName: $firstName, lastName: $lastName, username: $username, createdAt: $createdAt)';
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
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        username.hashCode ^
        password.hashCode ^
        createdAt.hashCode;
  }
}
