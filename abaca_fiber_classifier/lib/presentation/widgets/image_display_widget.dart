import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class ImageDisplayWidget extends StatelessWidget {
  final String? imagePath;

  const ImageDisplayWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Image.file(
        File(imagePath!),
        width: double.infinity,
        height: AppConstants.imageDisplayHeight,
        fit: BoxFit.cover,
      ),
    );
  }
}
