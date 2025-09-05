import 'package:flutter/material.dart';

class LoadingIndicatorWidget extends StatelessWidget {
  final bool isVisible;

  const LoadingIndicatorWidget({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
