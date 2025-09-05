class ClassificationResult {
  final String predictedLabel;
  final double confidence;
  final List<double> probabilities;

  const ClassificationResult({
    required this.predictedLabel,
    required this.confidence,
    required this.probabilities,
  });

  @override
  String toString() {
    return 'ClassificationResult(label: $predictedLabel, confidence: ${(confidence * 100).toStringAsFixed(2)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassificationResult &&
        other.predictedLabel == predictedLabel &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return predictedLabel.hashCode ^ confidence.hashCode;
  }
}
