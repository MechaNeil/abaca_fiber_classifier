import 'package:flutter/material.dart';

/// Widget for displaying storage statistics and insights
class StorageStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const StorageStatisticsWidget({
    super.key,
    required this.statistics,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (statistics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.storage, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No storage data available',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              if (onRefresh != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Storage Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Refresh statistics',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatisticsTiles(),
            const SizedBox(height: 16),
            _buildGradeDistribution(),
            if (statistics['recommendations'] != null) ...[
              const SizedBox(height: 16),
              _buildRecommendations(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTiles() {
    final totalCount = statistics['totalCount'] ?? 0;
    final totalSizeFormatted = statistics['totalSizeFormatted'] ?? '0 B';
    final averageFileSizeFormatted =
        statistics['averageFileSizeFormatted'] ?? '0 B';
    final mostCommonGrade = statistics['mostCommonGrade'] ?? 'N/A';

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            'Total Images',
            '$totalCount',
            Icons.photo_library,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            'Total Size',
            totalSizeFormatted,
            Icons.storage,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            'Avg. Size',
            averageFileSizeFormatted,
            Icons.insert_chart,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            'Top Grade',
            mostCommonGrade,
            Icons.star,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution() {
    final gradeDistribution =
        statistics['gradeDistribution'] as Map<String, Map<String, dynamic>>?;

    if (gradeDistribution == null || gradeDistribution.isEmpty) {
      return const Text('No grade distribution data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grade Distribution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...gradeDistribution.entries.map((entry) {
          final grade = entry.key;
          final data = entry.value;
          final count = data['count'] ?? 0;
          final sizeFormatted = _formatBytes(data['size'] ?? 0);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      grade,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('$count images')),
                Text(
                  sizeFormatted,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecommendations() {
    final recommendations = statistics['recommendations'] as List<String>?;

    if (recommendations == null || recommendations.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((recommendation) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
