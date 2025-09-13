import 'package:flutter/material.dart';
import 'dart:io';

import '../../domain/entities/stored_image.dart';
import '../../presentation/viewmodels/image_storage_view_model.dart';
import 'skeleton_loading_widget.dart';

/// Widget for displaying stored images organized by grade
class StoredImagesGridWidget extends StatelessWidget {
  final Map<String, List<StoredImage>> imagesByGrade;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(String)? onExportGrade;
  final Function(String)? onClearGrade;
  final Function(StoredImage)? onImageTap;
  final ImageStorageViewModel? viewModel; // Add viewModel for per-grade states

  const StoredImagesGridWidget({
    super.key,
    required this.imagesByGrade,
    this.isLoading = false,
    this.onRefresh,
    this.onExportGrade,
    this.onClearGrade,
    this.onImageTap,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && imagesByGrade.isEmpty) {
      return const StorageGridSkeleton(); // Use skeleton loading
    }

    if (imagesByGrade.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No stored images found',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Images will appear here after classification',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
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
    final isClearing = viewModel?.isGradeClearing(grade) ?? false;
    final isExporting = viewModel?.isGradeExporting(grade) ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(8.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isClearing ? 0.5 : 1.0,
        child: Card(
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade, context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${images.length} images',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                if (isClearing) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Clearing...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Spacer(),
                if (onExportGrade != null && images.isNotEmpty) ...[
                  if (isExporting)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: isClearing
                          ? null
                          : () => onExportGrade!(grade),
                      tooltip: 'Export grade $grade',
                    ),
                ],
                if (onClearGrade != null && images.isNotEmpty) ...[
                  if (isClearing)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: isExporting
                          ? null
                          : () => onClearGrade!(grade),
                      tooltip: 'Clear grade $grade',
                    ),
                ],
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildImageGrid(context, images),
              ),
            ],
          ),
        ),
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
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
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
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    image.confidencePercentage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    image.fileSizeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
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
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
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
              return _buildErrorWidget(context);
            },
          );
        } else {
          return _buildErrorWidget(context);
        }
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        size: 32,
      ),
    );
  }

  Color _getGradeColor(String grade, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (grade) {
      case 'EF':
        return Colors.purple;
      case 'G':
        return Colors.orange;
      case 'H':
        return Colors.red;
      case 'I':
        return Colors.pink;
      case 'JK':
        return Colors.blue;
      case 'M1':
        return Colors.teal;
      case 'S2':
        return Colors.green;
      case 'S3':
        return Colors.lightGreen;
      case 'grade_1': // Maps to G
        return Colors.orange;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }
}
