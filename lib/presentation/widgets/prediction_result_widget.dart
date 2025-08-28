import 'package:flutter/material.dart';
import '../../domain/entities/classification_result.dart';

class PredictionResultWidget extends StatelessWidget {
  final ClassificationResult? result;

  const PredictionResultWidget({Key? key, required this.result})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prediction: ${result!.predictedLabel}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Confidence: ${(result!.confidence * 100).toStringAsFixed(2)}%',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
