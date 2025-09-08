import 'package:flutter/material.dart';
import 'dart:io';
import '../../domain/entities/classification_history.dart';
import '../viewmodels/history_view_model.dart';
import '../pages/history_page.dart';
import '../../core/utils/grade_colors.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';

/// Widget for displaying recent classification history
///
/// This widget shows the most recent classification results
/// on the home page and provides navigation to the full history.
class RecentHistoryWidget extends StatefulWidget {
  final HistoryViewModel historyViewModel;
  final AuthViewModel authViewModel;

  const RecentHistoryWidget({
    super.key,
    required this.historyViewModel,
    required this.authViewModel,
  });

  @override
  State<RecentHistoryWidget> createState() => _RecentHistoryWidgetState();
}

class _RecentHistoryWidgetState extends State<RecentHistoryWidget> {
  @override
  void initState() {
    super.initState();
    widget.historyViewModel.addListener(_onViewModelChanged);
    // Load today's history when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.historyViewModel.loadTodayHistory();
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
              'Today',
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

        // Today's items display - increased height and made more scrollable
        SizedBox(height: 140, child: _buildRecentContent()),
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

    return _buildTodayList();
  }

  Widget _buildTodayList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: widget.historyViewModel.recentHistory.length,
      itemBuilder: (context, index) {
        final history = widget.historyViewModel.recentHistory[index];
        return _buildRecentItem(history);
      },
    );
  }

  Widget _buildRecentItem(ClassificationHistory history) {
    final bool isAdmin = widget.authViewModel.loggedInUser?.isAdmin ?? false;
    final bool isLowConfidence = history.confidence <= 0.5;

    return GestureDetector(
      onTap: () => _showHistoryDetails(history),
      child: Container(
        width: 100,
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
                    // Grade badge or "Cannot be classified" for non-admin low confidence
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isLowConfidence && !isAdmin)
                            ? Colors.grey[600]
                            : _getGradeColor(history.predictedLabel),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (isLowConfidence && !isAdmin)
                            ? 'Unclassified'
                            : _getShortGradeName(history.predictedLabel),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Confidence and time (only show confidence for admin or high confidence)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isAdmin || !isLowConfidence)
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
            'No classifications today',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Start classifying to see today\'s results',
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
            onPressed: () => widget.historyViewModel.loadTodayHistory(),
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
        builder: (context) => HistoryPage(
          viewModel: widget.historyViewModel,
          authViewModel: widget.authViewModel,
        ),
      ),
    );
  }

  void _showHistoryDetails(ClassificationHistory history) {
    final bool isAdmin = widget.authViewModel.loggedInUser?.isAdmin ?? false;
    final bool isLowConfidence = history.confidence <= 0.5;

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
              // Show grade or "Cannot be classified" based on user role and confidence
              _buildDetailRow(
                'Grade:',
                (isLowConfidence && !isAdmin)
                    ? 'Cannot be classified'
                    : history.gradeLabel,
              ),
              // Only show confidence for admin users or high confidence results
              if (isAdmin || !isLowConfidence)
                _buildDetailRow('Confidence:', history.confidencePercentage),
              _buildDetailRow('Date:', history.formattedDate),
              if (isAdmin) ...[_buildDetailRow('Model:', history.model)],
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
