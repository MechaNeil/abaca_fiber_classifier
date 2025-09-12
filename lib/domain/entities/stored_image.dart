/// Entity representing a stored classified image
///
/// This entity contains information about an image that has been
/// classified and stored in the organized folder structure.
class StoredImage {
  final int? id;
  final String originalImagePath;
  final String storedImagePath;
  final String grade;
  final double confidence;
  final List<double> probabilities;
  final DateTime timestamp;
  final int? userId;
  final String model;
  final String fileName;
  final int fileSizeBytes;

  const StoredImage({
    this.id,
    required this.originalImagePath,
    required this.storedImagePath,
    required this.grade,
    required this.confidence,
    required this.probabilities,
    required this.timestamp,
    this.userId,
    required this.model,
    required this.fileName,
    required this.fileSizeBytes,
  });

  /// Creates a StoredImage from a database map
  factory StoredImage.fromMap(Map<String, dynamic> map) {
    return StoredImage(
      id: map['id'],
      originalImagePath: map['originalImagePath'],
      storedImagePath: map['storedImagePath'],
      grade: map['grade'],
      confidence: map['confidence'],
      probabilities: List<double>.from(
        map['probabilities'].split(',').map((p) => double.parse(p)),
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      userId: map['userId'],
      model: map['model'],
      fileName: map['fileName'],
      fileSizeBytes: map['fileSizeBytes'],
    );
  }

  /// Converts the StoredImage to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalImagePath': originalImagePath,
      'storedImagePath': storedImagePath,
      'grade': grade,
      'confidence': confidence,
      'probabilities': probabilities.join(','),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userId': userId,
      'model': model,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  /// Creates a copy of this StoredImage with some properties updated
  StoredImage copyWith({
    int? id,
    String? originalImagePath,
    String? storedImagePath,
    String? grade,
    double? confidence,
    List<double>? probabilities,
    DateTime? timestamp,
    int? userId,
    String? model,
    String? fileName,
    int? fileSizeBytes,
  }) {
    return StoredImage(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      storedImagePath: storedImagePath ?? this.storedImagePath,
      grade: grade ?? this.grade,
      confidence: confidence ?? this.confidence,
      probabilities: probabilities ?? this.probabilities,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      model: model ?? this.model,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  @override
  String toString() {
    return 'StoredImage(id: $id, grade: $grade, confidence: ${(confidence * 100).toStringAsFixed(2)}%, fileName: $fileName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoredImage &&
        other.storedImagePath == storedImagePath &&
        other.grade == grade &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return storedImagePath.hashCode ^ grade.hashCode ^ confidence.hashCode;
  }

  /// Gets a human-readable file size string
  String get fileSizeString {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Gets the confidence as a percentage string
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }
}
