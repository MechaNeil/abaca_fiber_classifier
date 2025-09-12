import 'package:flutter/material.dart';

/// Skeleton loading widget with shimmer effect for better loading UX
class SkeletonLoadingWidget extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonLoadingWidget({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius,
  });

  @override
  State<SkeletonLoadingWidget> createState() => _SkeletonLoadingWidgetState();
}

class _SkeletonLoadingWidgetState extends State<SkeletonLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading for grade sections
class GradeSectionSkeleton extends StatelessWidget {
  const GradeSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Grade badge skeleton
                SkeletonLoadingWidget(
                  height: 32,
                  width: 60,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 12),
                // Image count skeleton
                const SkeletonLoadingWidget(height: 16, width: 80),
                const Spacer(),
                // Action buttons skeleton
                SkeletonLoadingWidget(
                  height: 40,
                  width: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: 8),
                SkeletonLoadingWidget(
                  height: 40,
                  width: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Image grid skeleton
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 1.0,
              ),
              itemCount: 6, // Show 6 skeleton items
              itemBuilder: (context, index) {
                return SkeletonLoadingWidget(
                  height: 120,
                  width: 120,
                  borderRadius: BorderRadius.circular(8),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading for individual image tiles
class ImageTileSkeleton extends StatelessWidget {
  const ImageTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Expanded(
            child: SkeletonLoadingWidget(
              height: double.infinity,
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
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
            child: const Column(
              children: [
                SkeletonLoadingWidget(height: 12, width: 40),
                SizedBox(height: 2),
                SkeletonLoadingWidget(height: 10, width: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full skeleton loading for the entire storage grid
class StorageGridSkeleton extends StatelessWidget {
  const StorageGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3, // Show 3 skeleton grade sections
      itemBuilder: (context, index) {
        return const GradeSectionSkeleton();
      },
    );
  }
}
