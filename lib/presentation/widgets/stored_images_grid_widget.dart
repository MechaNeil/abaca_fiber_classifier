import 'package:flutter/material.dart';
import 'dart:io';

import '../../domain/entities/stored_image.dart';

/// Widget for displaying stored images organized by grade
class StoredImagesGridWidget extends StatelessWidget {
  final Map<String, List<StoredImage>> imagesByGrade;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(String)? onExportGrade;
  final Function(StoredImage)? onImageTap;

  const StoredImagesGridWidget({
    super.key,
    required this.imagesByGrade,
    this.isLoading = false,
    this.onRefresh,
    this.onExportGrade,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (imagesByGrade.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No stored images found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Images will appear here after classification',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: ListView.builder(
        itemCount: imagesByGrade.length,
        itemBuilder: (context, index) {
          final grade = imagesByGrade.keys.elementAt(index);
          final images = imagesByGrade[grade]!;

          return _buildGradeSection(context, grade, images);
        },
      ),
    );
  }

  Widget _buildGradeSection(
    BuildContext context,
    String grade,
    List<StoredImage> images,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getGradeColor(grade),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                grade,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${images.length} images',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Spacer(),
            if (onExportGrade != null && images.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => onExportGrade!(grade),
                tooltip: 'Export grade $grade',
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildImageGrid(context, images),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<StoredImage> images) {
    if (images.isEmpty) {
      return const Text('No images in this grade');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildImageTile(context, image);
      },
    );
  }

  Widget _buildImageTile(BuildContext context, StoredImage image) {
    return GestureDetector(
      onTap: () => onImageTap?.call(image),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: _buildImageWidget(image),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    image.confidencePercentage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    image.fileSizeString,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(StoredImage image) {
    final file = File(image.storedImagePath);

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.data == true) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          );
        } else {
          return _buildErrorWidget();
        }
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'EF':
        return Colors.purple;
      case 'G':
        return Colors.blue;
      case 'H':
        return Colors.green;
      case 'I':
        return Colors.orange;
      case 'JK':
        return Colors.red;
      case 'M1':
        return Colors.indigo;
      case 'S2':
        return Colors.teal;
      case 'S3':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
