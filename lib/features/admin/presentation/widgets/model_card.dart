import 'package:flutter/material.dart';
import '../../domain/entities/model_entity.dart';

/// Widget for displaying a model card
class ModelCard extends StatelessWidget {
  final ModelEntity model;
  final bool isActive;
  final VoidCallback? onSelect;
  final VoidCallback? onDelete;
  final bool isLoading;

  const ModelCard({
    super.key,
    required this.model,
    this.isActive = false,
    this.onSelect,
    this.onDelete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isActive ? 4 : 2,
      color: isActive
          ? (Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.green.shade50)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.8)
                                    : Colors.green.shade700)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (model.description != null)
                        Text(
                          model.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.7)
                          : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Imported: ${_formatDate(model.importedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isActive && onSelect != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Select'),
                    ),
                  ),
                if (!isActive &&
                    onSelect != null &&
                    !model.isDefault &&
                    onDelete != null)
                  const SizedBox(width: 8),
                if (!model.isDefault && onDelete != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : onDelete,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                if (isActive)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Currently Active',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.8)
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
