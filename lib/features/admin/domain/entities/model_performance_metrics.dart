/// Entity representing model performance metrics
///
/// This entity tracks performance data for different models including
/// accuracy, usage statistics, and performance trends.
class ModelPerformanceMetrics {
  final int? id;
  final String modelName;
  final String modelPath;
  final DateTime recordedAt;
  final int totalClassifications;
  final int
  successfulClassifications; // Classifications above confidence threshold
  final double averageConfidence;
  final double highestConfidence;
  final double lowestConfidence;
  final Map<String, int> gradeDistribution; // Count of each grade classified
  final Map<String, double>
  averageConfidencePerGrade; // Average confidence per grade
  final double processingTimeMs; // Average processing time in milliseconds
  final String deviceInfo; // Device information for performance tracking

  const ModelPerformanceMetrics({
    this.id,
    required this.modelName,
    required this.modelPath,
    required this.recordedAt,
    required this.totalClassifications,
    required this.successfulClassifications,
    required this.averageConfidence,
    required this.highestConfidence,
    required this.lowestConfidence,
    required this.gradeDistribution,
    required this.averageConfidencePerGrade,
    required this.processingTimeMs,
    required this.deviceInfo,
  });

  /// Creates ModelPerformanceMetrics from a database map
  factory ModelPerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return ModelPerformanceMetrics(
      id: map['id'],
      modelName: map['modelName'],
      modelPath: map['modelPath'],
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt']),
      totalClassifications: map['totalClassifications'],
      successfulClassifications: map['successfulClassifications'],
      averageConfidence: map['averageConfidence'],
      highestConfidence: map['highestConfidence'],
      lowestConfidence: map['lowestConfidence'],
      gradeDistribution: _parseGradeDistribution(map['gradeDistribution']),
      averageConfidencePerGrade: _parseConfidencePerGrade(
        map['averageConfidencePerGrade'],
      ),
      processingTimeMs: map['processingTimeMs'],
      deviceInfo: map['deviceInfo'],
    );
  }

  /// Converts ModelPerformanceMetrics to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modelName': modelName,
      'modelPath': modelPath,
      'recordedAt': recordedAt.millisecondsSinceEpoch,
      'totalClassifications': totalClassifications,
      'successfulClassifications': successfulClassifications,
      'averageConfidence': averageConfidence,
      'highestConfidence': highestConfidence,
      'lowestConfidence': lowestConfidence,
      'gradeDistribution': _encodeGradeDistribution(gradeDistribution),
      'averageConfidencePerGrade': _encodeConfidencePerGrade(
        averageConfidencePerGrade,
      ),
      'processingTimeMs': processingTimeMs,
      'deviceInfo': deviceInfo,
    };
  }

  /// Parse grade distribution from JSON string
  static Map<String, int> _parseGradeDistribution(String distributionString) {
    try {
      final Map<String, int> distribution = {};
      final pairs = distributionString.split(',');
      for (final pair in pairs) {
        if (pair.isNotEmpty) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            distribution[parts[0]] = int.parse(parts[1]);
          }
        }
      }
      return distribution;
    } catch (e) {
      return {};
    }
  }

  /// Encode grade distribution to JSON string
  static String _encodeGradeDistribution(Map<String, int> distribution) {
    return distribution.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(',');
  }

  /// Parse confidence per grade from JSON string
  static Map<String, double> _parseConfidencePerGrade(String confidenceString) {
    try {
      final Map<String, double> confidence = {};
      final pairs = confidenceString.split(',');
      for (final pair in pairs) {
        if (pair.isNotEmpty) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            confidence[parts[0]] = double.parse(parts[1]);
          }
        }
      }
      return confidence;
    } catch (e) {
      return {};
    }
  }

  /// Encode confidence per grade to JSON string
  static String _encodeConfidencePerGrade(Map<String, double> confidence) {
    return confidence.entries
        .map((entry) => '${entry.key}:${entry.value.toStringAsFixed(4)}')
        .join(',');
  }

  /// Calculate success rate (percentage of successful classifications)
  double get successRate {
    if (totalClassifications == 0) return 0.0;
    return (successfulClassifications / totalClassifications) * 100;
  }

  /// Get the most classified grade
  String get mostClassifiedGrade {
    if (gradeDistribution.isEmpty) return 'None';
    return gradeDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get performance summary as a formatted string
  String get performanceSummary {
    return 'Model: $modelName\n'
        'Total Classifications: $totalClassifications\n'
        'Success Rate: ${successRate.toStringAsFixed(1)}%\n'
        'Average Confidence: ${(averageConfidence * 100).toStringAsFixed(1)}%\n'
        'Processing Time: ${processingTimeMs.toStringAsFixed(1)}ms\n'
        'Most Classified Grade: $mostClassifiedGrade';
  }

  /// Creates a copy with updated fields
  ModelPerformanceMetrics copyWith({
    int? id,
    String? modelName,
    String? modelPath,
    DateTime? recordedAt,
    int? totalClassifications,
    int? successfulClassifications,
    double? averageConfidence,
    double? highestConfidence,
    double? lowestConfidence,
    Map<String, int>? gradeDistribution,
    Map<String, double>? averageConfidencePerGrade,
    double? processingTimeMs,
    String? deviceInfo,
  }) {
    return ModelPerformanceMetrics(
      id: id ?? this.id,
      modelName: modelName ?? this.modelName,
      modelPath: modelPath ?? this.modelPath,
      recordedAt: recordedAt ?? this.recordedAt,
      totalClassifications: totalClassifications ?? this.totalClassifications,
      successfulClassifications:
          successfulClassifications ?? this.successfulClassifications,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      highestConfidence: highestConfidence ?? this.highestConfidence,
      lowestConfidence: lowestConfidence ?? this.lowestConfidence,
      gradeDistribution: gradeDistribution ?? this.gradeDistribution,
      averageConfidencePerGrade:
          averageConfidencePerGrade ?? this.averageConfidencePerGrade,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  @override
  String toString() {
    return 'ModelPerformanceMetrics(id: $id, modelName: $modelName, totalClassifications: $totalClassifications, successRate: ${successRate.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelPerformanceMetrics &&
        other.id == id &&
        other.modelName == modelName &&
        other.modelPath == modelPath &&
        other.recordedAt == recordedAt &&
        other.totalClassifications == totalClassifications &&
        other.successfulClassifications == successfulClassifications;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        modelName.hashCode ^
        modelPath.hashCode ^
        recordedAt.hashCode ^
        totalClassifications.hashCode ^
        successfulClassifications.hashCode;
  }
}
