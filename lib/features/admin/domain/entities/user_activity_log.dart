/// Entity representing a user activity log
///
/// This entity tracks user interactions with the app such as
/// login, logout, model switches, and other significant activities.
class UserActivityLog {
  final int? id;
  final int? userId;
  final String? username;
  final String activityType;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const UserActivityLog({
    this.id,
    this.userId,
    this.username,
    required this.activityType,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  /// Creates a UserActivityLog from a database map
  factory UserActivityLog.fromMap(Map<String, dynamic> map) {
    return UserActivityLog(
      id: map['id'],
      userId: map['userId'],
      username: map['username'],
      activityType: map['activityType'],
      description: map['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(_parseMetadata(map['metadata']))
          : null,
    );
  }

  /// Converts UserActivityLog to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'activityType': activityType,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  /// Parse metadata from JSON string
  static Map<String, dynamic> _parseMetadata(String metadataString) {
    try {
      return Map<String, dynamic>.from(
        metadataString
            .split(',')
            .map((pair) {
              final parts = pair.split(':');
              return MapEntry(parts[0], parts[1]);
            })
            .fold<Map<String, dynamic>>({}, (map, entry) {
              map[entry.key] = entry.value;
              return map;
            }),
      );
    } catch (e) {
      return {};
    }
  }

  /// Encode metadata to JSON string
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    return metadata.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(',');
  }

  /// Creates a copy with updated fields
  UserActivityLog copyWith({
    int? id,
    int? userId,
    String? username,
    String? activityType,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return UserActivityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserActivityLog(id: $id, userId: $userId, username: $username, activityType: $activityType, description: $description, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserActivityLog &&
        other.id == id &&
        other.userId == userId &&
        other.username == username &&
        other.activityType == activityType &&
        other.description == description &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        username.hashCode ^
        activityType.hashCode ^
        description.hashCode ^
        timestamp.hashCode;
  }
}

/// Predefined activity types for consistency
class ActivityType {
  static const String login = 'LOGIN';
  static const String logout = 'LOGOUT';
  static const String classification = 'CLASSIFICATION';
  static const String modelSwitch = 'MODEL_SWITCH';
  static const String modelImport = 'MODEL_IMPORT';
  static const String modelDelete = 'MODEL_DELETE';
  static const String historyDelete = 'HISTORY_DELETE';
  static const String exportData = 'EXPORT_DATA';
  static const String userRegistration = 'USER_REGISTRATION';
  static const String appStart = 'APP_START';
  static const String appClose = 'APP_CLOSE';
}
