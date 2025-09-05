import 'dart:math' as math;

class ImageUtils {
  static List<double> softmax(List<double> logits) {
    // Stable softmax
    final maxLogit = logits.reduce(math.max);
    final exps = logits
        .map((v) => math.exp(v - maxLogit))
        .toList(growable: false);
    final sum = exps.fold<double>(0.0, (s, v) => s + v);
    return exps.map((v) => v / sum).toList(growable: false);
  }

  static String formatShape(List<int> shape) => '[${shape.join(', ')}]';

  static String formatPythonTuple(
    String label,
    double conf,
    List<double> probs,
  ) {
    final probsStr = formatNumpyArray(probs);
    final confStr = conf.toStringAsFixed(15);
    return "('$label', $confStr, $probsStr)";
  }

  static String formatNumpyArray(List<double> values) {
    final formatted = values.map((v) => v.toStringAsFixed(8)).join(', ');
    return 'array([$formatted], dtype=float32)';
  }

  static bool isProbabilityDistribution(List<double> probs) {
    final sum = probs.fold<double>(0.0, (s, v) => s + v);
    return sum > 0.98 && sum < 1.02;
  }

  static int findMaxIndex(List<double> values) {
    int maxIdx = 0;
    double maxVal = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }
}
