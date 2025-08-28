import 'package:flutter/material.dart';
import '../../domain/entities/model_info.dart';

class ModelInfoWidget extends StatelessWidget {
  final ModelInfo? modelInfo;

  const ModelInfoWidget({Key? key, required this.modelInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (modelInfo == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input tensor: ${modelInfo!.inputInfo}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          'Output tensor: ${modelInfo!.outputInfo}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
