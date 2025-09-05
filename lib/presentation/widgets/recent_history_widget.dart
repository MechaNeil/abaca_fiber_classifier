import 'package:flutter/material.dart';
import 'dart:io';
import '../../domain/entities/classification_history.dart';
import '../viewmodels/history_view_model.dart';
import '../pages/history_page.dart';
import '../../core/utils/grade_colors.dart';

/// Widget for displaying recent classification history
///
/// This widget shows the most recent classification results
/// on the home page and provides navigation to the full history.
class RecentHistoryWidget extends StatefulWidget {
  final HistoryViewModel historyViewModel;

  const RecentHistoryWidget({super.key, required this.historyViewModel});

  @override
  State<RecentHistoryWidget> createState() => _RecentHistoryWidgetState();
}

class _RecentHistoryWidgetState extends State<RecentHistoryWidget> {
  @override
  void initState() {
    super.initState();
    widget.historyViewModel.addListener(_onViewModelChanged);
    // Load recent history when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.historyViewModel.loadRecentHistory(limit: 3);
    });
  }

  @override
  void dispose() {
    widget.historyViewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "View All" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (widget.historyViewModel.recentHistory.isNotEmpty)
              TextButton(
                onPressed: () => _navigateToHistoryPage(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Recent items display
        SizedBox(height: 120, child: _buildRecentContent()),
      ],
    );
  }

  Widget _buildRecentContent() {
    if (widget.historyViewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
      );
    }

    if (widget.historyViewModel.error != null) {
      return _buildErrorState();
    }

    if (widget.historyViewModel.recentHistory.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRecentList();
  }

  Widget _buildRecentList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.historyViewModel.recentHistory.length,
      itemBuilder: (context, index) {
        final history = widget.historyViewModel.recentHistory[index];
        return _buildRecentItem(history);
      },
    );
  }

  Widget _buildRecentItem(ClassificationHistory history) {
    return GestureDetector(
      onTap: () => _showHistoryDetails(history),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildImageWidget(history.imagePath),
                ),
              ),
            ),

            // Grade and confidence info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grade badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getGradeColor(history.predictedLabel),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getShortGradeName(history.predictedLabel),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Confidence and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              history.confidencePercentage,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              history.shortFormattedDate,
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400], size: 30),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No recent classifications',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Start classifying to see your history',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.red[400]),
          const SizedBox(height: 8),
          Text(
            'Failed to load history',
            style: TextStyle(fontSize: 12, color: Colors.red[700]),
          ),
          TextButton(
            onPressed: () =>
                widget.historyViewModel.loadRecentHistory(limit: 3),
            child: const Text('Retry', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    return GradeColors.getGradeColor(grade);
  }

  String _getShortGradeName(String grade) {
    return GradeColors.getShortGradeName(grade);
  }

  void _navigateToHistoryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryPage(viewModel: widget.historyViewModel),
      ),
    );
  }

  void _showHistoryDetails(ClassificationHistory history) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classification Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: _buildImageWidget(history.imagePath),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Grade:', history.gradeLabel),
              _buildDetailRow('Confidence:', history.confidencePercentage),
              _buildDetailRow('Date:', history.formattedDate),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _navigateToHistoryPage(),
                    child: const Text('View All History'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }
}
