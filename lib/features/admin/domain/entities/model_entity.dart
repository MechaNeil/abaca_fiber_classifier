/// Model entity representing a TensorFlow Lite model
class ModelEntity {
  final String name;
  final String path;
  final DateTime importedAt;
  final bool isDefault;
  final String? description;

  const ModelEntity({
    required this.name,
    required this.path,
    required this.importedAt,
    this.isDefault = false,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'importedAt': importedAt.millisecondsSinceEpoch,
      'isDefault': isDefault ? 1 : 0,
      'description': description,
    };
  }

  factory ModelEntity.fromMap(Map<String, dynamic> map) {
    return ModelEntity(
      name: map['name'],
      path: map['path'],
      importedAt: DateTime.fromMillisecondsSinceEpoch(map['importedAt']),
      isDefault: map['isDefault'] == 1,
      description: map['description'],
    );
  }

  ModelEntity copyWith({
    String? name,
    String? path,
    DateTime? importedAt,
    bool? isDefault,
    String? description,
  }) {
    return ModelEntity(
      name: name ?? this.name,
      path: path ?? this.path,
      importedAt: importedAt ?? this.importedAt,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'ModelEntity(name: $name, path: $path, isDefault: $isDefault, importedAt: $importedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelEntity &&
        other.name == name &&
        other.path == path &&
        other.importedAt == importedAt &&
        other.isDefault == isDefault &&
        other.description == description;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        path.hashCode ^
        importedAt.hashCode ^
        isDefault.hashCode ^
        description.hashCode;
  }
}
