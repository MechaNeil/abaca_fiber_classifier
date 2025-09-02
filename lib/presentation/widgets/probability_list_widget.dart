import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class ProbabilityListWidget extends StatelessWidget {
  final List<String> labels;
  final List<double>? probabilities;

  const ProbabilityListWidget({
    super.key,
    required this.labels,
    required this.probabilities,
  });

  @override
  Widget build(BuildContext context) {
    if (probabilities == null) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: ListView.separated(
        itemCount: math.min(labels.length, probabilities!.length),
        separatorBuilder: (_, __) =>
            const Divider(height: AppConstants.smallSpacing),
        itemBuilder: (context, i) => Row(
          children: [
            Expanded(
              child: Text(
                i < labels.length ? labels[i] : 'Class $i',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              probabilities![i].toStringAsFixed(6),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
