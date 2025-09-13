import 'package:flutter/material.dart';
import 'dart:io';
import '../../domain/entities/classification_history.dart';
import '../viewmodels/history_view_model.dart';
import '../../core/utils/grade_colors.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';

/// History page displaying classification history records
///
/// This page shows:
/// - List of all classification history
/// - Filtering by grade
/// - Statistics overview
/// - Delete functionality
/// - Recent activity
class HistoryPage extends StatefulWidget {
  final HistoryViewModel viewModel;
  final AuthViewModel authViewModel;

  const HistoryPage({
    super.key,
    required this.viewModel,
    required this.authViewModel,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  static const double confidenceThreshold = 0.5;
  late TabController _tabController;
  bool _showAllGrades = false; // Toggle state for showing all grades

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.viewModel.addListener(_onViewModelChanged);
    // Load history data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadCompleteHistory();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'History',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Clear All',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Grade'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: widget.viewModel.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : widget.viewModel.error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [_buildGradeTab(), _buildRecentTab()],
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.viewModel.error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                widget.viewModel.clearError();
                widget.viewModel.loadCompleteHistory();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeTab() {
    if (widget.viewModel.allHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Statistics overview - Only show for admin users
        if (widget.authViewModel.loggedInUser?.isAdmin == true)
          _buildStatisticsOverview(),

        // Grade filter
        _buildGradeFilter(),

        // History list with custom filtering
        Expanded(child: _buildHistoryList(_getFilteredHistoryForUser())),
      ],
    );
  }

  /// Gets filtered history based on user role and selected filter
  List<ClassificationHistory> _getFilteredHistoryForUser() {
    final bool isAdmin = widget.authViewModel.loggedInUser?.isAdmin ?? false;
    final selectedFilter = widget.viewModel.selectedGradeFilter;

    if (selectedFilter == 'All') {
      if (isAdmin) {
        // Admin sees all history
        return widget.viewModel.allHistory;
      } else {
        // Non-admin users see all history but with modified display
        return widget.viewModel.allHistory;
      }
    } else if (selectedFilter == 'Cannot be classified') {
      // Show only low confidence entries (for non-admin users)
      return widget.viewModel.allHistory
          .where((history) => history.confidence <= confidenceThreshold)
          .toList();
    } else {
      // Standard grade filtering
      if (isAdmin) {
        // Admin sees all entries for the grade
        return widget.viewModel.allHistory
            .where((history) => history.predictedLabel == selectedFilter)
            .toList();
      } else {
        // Non-admin users only see high confidence entries for the grade
        return widget.viewModel.allHistory
            .where(
              (history) =>
                  history.predictedLabel == selectedFilter &&
                  history.confidence > confidenceThreshold,
            )
            .toList();
      }
    }
  }

  Widget _buildRecentTab() {
    if (widget.viewModel.recentHistory.isEmpty) {
      return _buildEmptyState();
    }

    return _buildHistoryList(widget.viewModel.recentHistory);
  }

  Widget _buildStatisticsOverview() {
    final stats = widget.viewModel.gradeStatistics;
    if (stats.isEmpty) return const SizedBox.shrink();

    // Determine which stats to show based on toggle state
    final displayStats = _showAllGrades ? stats : stats.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Classification Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (stats.length > 3)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllGrades = !_showAllGrades;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAllGrades ? 'Show Less' : 'Show All',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showAllGrades ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayStats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getGradeColor(stat.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatGradeName(stat.key),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    '${stat.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeFilter() {
    final bool isAdmin = widget.authViewModel.loggedInUser?.isAdmin ?? false;

    // Get available grades based on user role
    List<String> availableGrades;
    if (isAdmin) {
      // Admin users see all actual grades
      availableGrades = widget.viewModel.availableGrades;
    } else {
      // Non-admin users see modified grade list
      final actualGrades = widget.viewModel.availableGrades
          .where((grade) => grade != 'All')
          .toList();
      final nonLowConfidenceGrades = <String>[];
      bool hasLowConfidenceEntries = false;

      // Check which grades have high confidence entries for non-admin users
      for (final grade in actualGrades) {
        final gradeEntries = widget.viewModel.allHistory
            .where((h) => h.predictedLabel == grade)
            .toList();
        final hasHighConfidenceEntries = gradeEntries.any(
          (h) => h.confidence > confidenceThreshold,
        );
        final hasLowConfidenceForGrade = gradeEntries.any(
          (h) => h.confidence <= confidenceThreshold,
        );

        if (hasHighConfidenceEntries) {
          nonLowConfidenceGrades.add(grade);
        }

        if (hasLowConfidenceForGrade) {
          hasLowConfidenceEntries = true;
        }
      }

      availableGrades = ['All', ...nonLowConfidenceGrades];

      // Add "Cannot be classified" filter if there are low confidence entries
      if (hasLowConfidenceEntries) {
        availableGrades.add('Cannot be classified');
      }
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableGrades.length,
        itemBuilder: (context, index) {
          final grade = availableGrades[index];
          final isSelected = grade == widget.viewModel.selectedGradeFilter;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                grade == 'Cannot be classified'
                    ? grade
                    : _formatGradeName(grade),
              ),
              selected: isSelected,
              onSelected: (_) => widget.viewModel.setGradeFilter(grade),
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(List<ClassificationHistory> history) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(ClassificationHistory history) {
    final bool isAdmin = widget.authViewModel.loggedInUser?.isAdmin ?? false;
    final bool isLowConfidence = history.confidence <= confidenceThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: _buildImageWidget(history.imagePath),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isLowConfidence && !isAdmin)
                    ? Theme.of(context).colorScheme.outline
                    : _getGradeColor(history.predictedLabel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (isLowConfidence && !isAdmin)
                    ? 'Cannot be classified'
                    : history.gradeLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Only show confidence for admin users or high confidence results
            if (isAdmin || !isLowConfidence)
              Text(
                history.confidencePercentage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
        subtitle: Text(
          history.friendlyDate,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleItemAction(value, history),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 12),
                  Text('View Details'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Icon(
        Icons.image,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        size: 30,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Classification History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start classifying some abaca fiber to see your history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    return GradeColors.getGradeColor(grade);
  }

  String _formatGradeName(String grade) {
    return GradeColors.formatGradeName(grade);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        widget.viewModel.refresh();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  void _handleItemAction(String action, ClassificationHistory history) {
    switch (action) {
      case 'view':
        _showDetailsDialog(history);
        break;
      case 'delete':
        _showDeleteDialog(history);
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all classification history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              final success = await widget.viewModel.clearAllHistory();
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'All history cleared successfully'
                          : 'Failed to clear history',
                    ),
                    backgroundColor: success
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ClassificationHistory history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History Item'),
        content: const Text(
          'Are you sure you want to delete this classification record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              if (history.id != null) {
                final success = await widget.viewModel.deleteHistory(
                  history.id!,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'History item deleted successfully'
                            : 'Failed to delete history item',
                      ),
                      backgroundColor: success
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(ClassificationHistory history) {
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
                  color: Theme.of(context).colorScheme.onSurface,
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
