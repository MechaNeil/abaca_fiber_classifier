import 'package:flutter/material.dart';

/// Logo placeholder widget
///
/// This widget displays a placeholder logo that matches the UI design.
/// In a real application, you would replace this with your actual logo image.
class LogoPlaceholder extends StatelessWidget {
  final double size;

  const LogoPlaceholder({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.eco, color: Colors.white, size: 40),
    );
  }
}
