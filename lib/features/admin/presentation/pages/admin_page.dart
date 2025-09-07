import 'package:flutter/material.dart';
import '../viewmodels/admin_view_model.dart';
import '../widgets/model_card.dart';
import '../widgets/admin_button.dart';

/// Admin tools page for managing models and system operations
class AdminPage extends StatefulWidget {
  final AdminViewModel viewModel;

  const AdminPage({super.key, required this.viewModel});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.viewModel.addListener(_onViewModelChanged);

    // Initialize the view model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.initialize();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    // Show error or success messages
    if (widget.viewModel.error != null) {
      _showErrorSnackBar(widget.viewModel.error!);
    } else if (widget.viewModel.successMessage != null) {
      _showSuccessSnackBar(widget.viewModel.successMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    final userFriendlyMessage = _getUserFriendlyErrorMessage(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              userFriendlyMessage,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    widget.viewModel.clearError();
  }

  /// Convert technical error messages to user-friendly ones
  String _getUserFriendlyErrorMessage(String technicalMessage) {
    final lowerMessage = technicalMessage.toLowerCase();

    // File picker related errors
    if (lowerMessage.contains('failed to pick file')) {
      return 'Unable to access the selected file. Please try selecting the file again.';
    }

    if (lowerMessage.contains('please select a valid tensorflow lite')) {
      return 'The selected file is not a valid model file. Please choose a .tflite file.';
    }

    // Model loading/switching errors
    if (lowerMessage.contains(
          'incompatible with the current tensorflow lite runtime',
        ) ||
        lowerMessage.contains('unsupported operators')) {
      return 'This model is not compatible with the app. Please use a different model file or check with your administrator.';
    }

    if (lowerMessage.contains('unable to create interpreter') ||
        lowerMessage.contains('corrupted or incompatible')) {
      return 'The model file appears to be damaged or corrupted. Please try downloading the model again.';
    }

    if (lowerMessage.contains('failed to load models')) {
      return 'Unable to load the available models. Please check your device storage and try again.';
    }

    if (lowerMessage.contains('failed to import model')) {
      return 'The model could not be imported. Please ensure the file is a valid .tflite model and try again.';
    }

    if (lowerMessage.contains('failed to switch model')) {
      return 'Unable to change to the selected model. The previous model will continue to be used.';
    }

    if (lowerMessage.contains('failed to revert to default model')) {
      return 'Unable to restore the default model. Please restart the app or contact support.';
    }

    if (lowerMessage.contains('failed to delete model')) {
      return 'The model could not be removed. Please try again or restart the app.';
    }

    // Export related errors
    if (lowerMessage.contains('export feature will be available')) {
      return 'The export feature is coming soon! This functionality will be available in a future update.';
    }

    if (lowerMessage.contains('failed to export logs')) {
      return 'Unable to export the data. Please check your device storage and permissions.';
    }

    // Network/permission related errors
    if (lowerMessage.contains('permission') ||
        lowerMessage.contains('access denied')) {
      return 'The app needs permission to access this file. Please check your device settings and try again.';
    }

    if (lowerMessage.contains('storage') || lowerMessage.contains('space')) {
      return 'There may not be enough storage space on your device. Please free up some space and try again.';
    }

    // Generic fallback for unknown errors
    if (lowerMessage.contains('failed to') || lowerMessage.contains('error')) {
      return 'Something went wrong. Please try again or restart the app if the problem continues.';
    }

    // If no pattern matches, return a generic user-friendly message
    return 'An unexpected issue occurred. Please try again or contact support if this continues.';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    widget.viewModel.clearSuccessMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Tools',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.cloud_upload), text: 'Model Management'),
            Tab(icon: Icon(Icons.download), text: 'Export Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildModelManagementTab(), _buildExportLogsTab()],
      ),
    );
  }

  Widget _buildModelManagementTab() {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, child) {
        if (widget.viewModel.isLoadingModels) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Import/Update Model Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_upload, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Import/Update Model',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Import a new TensorFlow Lite model (.tflite) to use for classification. The new model will be saved to the device and can be selected as the active model.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AdminButton(
                              text: 'Import',
                              icon: Icons.file_upload,
                              onPressed: widget.viewModel.importModelFromPicker,
                              isLoading: widget.viewModel.isImporting,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AdminButton(
                              text: 'Revert',
                              icon: Icons.restore,
                              onPressed: widget.viewModel.revertToDefaultModel,
                              isLoading: widget.viewModel.isSwitchingModel,
                              isOutlined: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Current Model Section
              if (widget.viewModel.currentModel != null) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Current Active Model',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ModelCard(
                  model: widget.viewModel.currentModel!,
                  isActive: true,
                ),
                const SizedBox(height: 24),
              ],

              // Available Models Section
              Row(
                children: [
                  const Icon(Icons.list, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Available Models',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (widget.viewModel.availableModels.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No models available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...widget.viewModel.availableModels.map((model) {
                  final isActive = widget.viewModel.isCurrentModel(model);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ModelCard(
                      model: model,
                      isActive: isActive,
                      onSelect: isActive
                          ? null
                          : () => _confirmSwitchModel(model),
                      onDelete: model.isDefault
                          ? null
                          : () => _confirmDeleteModel(model),
                      isLoading: widget.viewModel.hasAnyOperation,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportLogsTab() {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.download, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Export Classification Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Export all classification history and logs to a file. This feature will be implemented in a future update.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      AdminButton(
                        text: 'Export Logs',
                        icon: Icons.file_download,
                        onPressed: widget.viewModel.exportLogs,
                        isLoading: widget.viewModel.isExporting,
                        backgroundColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The export functionality will include:\n'
                        '• Classification history\n'
                        '• Model performance metrics\n'
                        '• User activity logs\n'
                        '• CSV and JSON export formats',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSwitchModel(model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.orange),
            SizedBox(width: 8),
            Text('Switch Model'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to switch to "${model.name}"?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will change the active model used for all future classifications. Your current model will remain available in the list.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.viewModel.switchToModel(model);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Switch Model',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteModel(model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Remove Model'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove "${model.name}"?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. The model file will be permanently deleted from your device.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can re-import this model later if needed.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.viewModel.deleteModel(model);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Remove Model',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
