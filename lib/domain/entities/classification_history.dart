/// Entity representing a classification history record
///
/// This entity contains information about a classification performed
/// by the user, including the image path, results, and metadata.
class ClassificationHistory {
  final int? id;
  final String imagePath;
  final String predictedLabel;
  final double confidence;
  final List<double> probabilities;
  final DateTime timestamp;
  final int? userId; // Optional: for multi-user support

  const ClassificationHistory({
    this.id,
    required this.imagePath,
    required this.predictedLabel,
    required this.confidence,
    required this.probabilities,
    required this.timestamp,
    this.userId,
  });

  /// Creates a ClassificationHistory from a database map
  factory ClassificationHistory.fromMap(Map<String, dynamic> map) {
    return ClassificationHistory(
      id: map['id'],
      imagePath: map['imagePath'],
      predictedLabel: map['predictedLabel'],
      confidence: map['confidence'],
      probabilities: _parseProbabilities(map['probabilities']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      userId: map['userId'],
    );
  }

  /// Converts ClassificationHistory to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'predictedLabel': predictedLabel,
      'confidence': confidence,
      'probabilities': _encodeProbabilities(probabilities),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  /// Creates a copy of this history with updated fields
  ClassificationHistory copyWith({
    int? id,
    String? imagePath,
    String? predictedLabel,
    double? confidence,
    List<double>? probabilities,
    DateTime? timestamp,
    int? userId,
  }) {
    return ClassificationHistory(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      predictedLabel: predictedLabel ?? this.predictedLabel,
      confidence: confidence ?? this.confidence,
      probabilities: probabilities ?? this.probabilities,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }

  /// Helper method to encode probabilities as a comma-separated string
  static String _encodeProbabilities(List<double> probabilities) {
    return probabilities.map((p) => p.toString()).join(',');
  }

  /// Helper method to parse probabilities from a comma-separated string
  static List<double> _parseProbabilities(String encodedProbabilities) {
    if (encodedProbabilities.isEmpty) return [];
    return encodedProbabilities
        .split(',')
        .map((s) => double.tryParse(s.trim()) ?? 0.0)
        .toList();
  }

  /// Gets the grade label based on the predicted label
  String get gradeLabel {
    switch (predictedLabel.toLowerCase()) {
      case 'grade_s2':
        return 'GRADE S2';
      case 'grade_1':
        return 'GRADE 1';
      case 'grade_jk':
        return 'GRADE JK';
      default:
        return predictedLabel.toUpperCase();
    }
  }

  /// Gets the confidence percentage as a formatted string
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  /// Gets the formatted timestamp for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $amPm';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  String toString() {
    return 'ClassificationHistory(id: $id, label: $predictedLabel, confidence: $confidencePercentage, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassificationHistory &&
        other.id == id &&
        other.imagePath == imagePath &&
        other.predictedLabel == predictedLabel &&
        other.confidence == confidence &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        imagePath.hashCode ^
        predictedLabel.hashCode ^
        confidence.hashCode ^
        timestamp.hashCode;
  }
}
