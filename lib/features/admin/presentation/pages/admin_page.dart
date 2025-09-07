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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          constraints: const BoxConstraints(maxHeight: 120),
          child: SingleChildScrollView(
            child: Text(message, style: const TextStyle(fontSize: 14)),
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(
          seconds: 8,
        ), // Longer duration for detailed error messages
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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
                        '• Database table queries\n'
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
        title: const Text('Switch Model'),
        content: Text(
          'Are you sure you want to switch to "${model.name}"? This will change the active model used for all classifications.',
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
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteModel(model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text(
          'Are you sure you want to delete "${model.name}"? This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
