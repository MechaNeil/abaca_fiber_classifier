import 'package:flutter/material.dart';
import '../viewmodels/admin_view_model.dart';
import '../widgets/model_card.dart';
import '../widgets/admin_button.dart';
import '../../../auth/data/database_service.dart';
import '../../../../presentation/viewmodels/image_storage_view_model.dart';
import '../../../../presentation/widgets/stored_images_grid_widget.dart';
import '../../../../presentation/widgets/storage_statistics_widget.dart';

/// Admin tools page for managing models and system operations
class AdminPage extends StatefulWidget {
  final AdminViewModel viewModel;
  final ImageStorageViewModel? imageStorageViewModel;

  const AdminPage({
    super.key,
    required this.viewModel,
    this.imageStorageViewModel,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    if (!mounted) return;

    // Show error or success messages
    if (widget.viewModel.error != null) {
      _showErrorSnackBar(widget.viewModel.error!);
    } else if (widget.viewModel.successMessage != null) {
      _showSuccessSnackBar(widget.viewModel.successMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

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
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
    widget.viewModel.clearError();
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

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
            Tab(icon: Icon(Icons.storage), text: 'Image Storage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModelManagementTab(),
          _buildExportLogsTab(),
          _buildImageStorageTab(),
        ],
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
                            'Export Comprehensive Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Export comprehensive classification data including history, model performance metrics, user activity logs, and database tables in both CSV and JSON formats. Model performance metrics are automatically refreshed before export to ensure up-to-date data. Files will be saved to your Downloads folder if permission is granted, or to app storage as a fallback.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      AdminButton(
                        text: 'Export Data',
                        icon: Icons.file_download,
                        onPressed: widget.viewModel.exportLogs,
                        isLoading: widget.viewModel.isExporting,
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Database Management Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Database Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '⚠️ WARNING: This will permanently delete ALL data including users, classification history, and settings. This action cannot be undone!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AdminButton(
                        text: 'Reset Database',
                        icon: Icons.delete_forever,
                        onPressed: _confirmResetDatabase,
                        backgroundColor: Colors.red,
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
                            'Available Export Data',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The export functionality includes:\n'
                        '• Classification history\n'
                        '• Model performance metrics\n'
                        '• User activity logs\n'
                        '• Database tables\n'
                        '• CSV and JSON export formats\n'
                        '• System information and metadata\n'
                        '• Files saved to Downloads folder (with permission)\n'
                        '• Automatic fallback to app storage',
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
    if (!mounted) return;

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
    if (!mounted) return;

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

  void _confirmResetDatabase() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text(
          'Are you sure you want to reset the entire database?\n\n'
          'This will permanently delete:\n'
          '• All user accounts\n'
          '• Classification history\n'
          '• Model performance data\n'
          '• Activity logs\n'
          '• All settings\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetDatabase();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset Database'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStorageTab() {
    if (widget.imageStorageViewModel == null) {
      return const Center(
        child: Text(
          'Image storage is not available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Statistics Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: Colors.green[700]),
                      SizedBox(width: 8),
                      Text(
                        'Storage Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  StorageStatisticsWidget(
                    statistics: widget.imageStorageViewModel!.storageStatistics,
                    isLoading: widget.imageStorageViewModel!.isLoading,
                    onRefresh: () {
                      widget.imageStorageViewModel!.loadStorageStatistics();
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Stored Images Grid Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Text(
                        'Stored Images',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 400, // Fixed height for grid
                    child: StoredImagesGridWidget(
                      imagesByGrade:
                          widget.imageStorageViewModel!.imagesByGrade,
                      isLoading: widget.imageStorageViewModel!.isLoading,
                      onRefresh: () {
                        widget.imageStorageViewModel!.refresh();
                      },
                      onExportGrade: (grade) async {
                        try {
                          await widget.imageStorageViewModel!.exportGradeAsZip(
                            grade,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Grade $grade exported successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Export failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Export Options Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_download, color: Colors.orange[700]),
                      SizedBox(width: 8),
                      Text(
                        'Export Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final filePath = await widget
                                  .imageStorageViewModel!
                                  .exportAllImagesAsZip();
                              if (mounted) {
                                if (filePath != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Images exported successfully as ZIP to: $filePath',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Export failed: No file path returned',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Export failed: $e'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.archive),
                          label: Text('Export as ZIP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final dirPath = await widget
                                  .imageStorageViewModel!
                                  .exportToDirectory();
                              if (mounted) {
                                if (dirPath != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Images exported to folder successfully: $dirPath',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Export failed: No directory path returned',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Export failed: $e'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.folder),
                          label: Text('Export to Folder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Export functionality:\n'
                    '• ZIP export: Creates compressed archive with all grade folders\n'
                    '• Folder export: Copies organized folders to Downloads\n'
                    '• Includes metadata files for each grade\n'
                    '• Preserves original folder structure',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDatabase() async {
    try {
      await DatabaseService.instance.resetDatabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Database reset successfully. Please restart the app.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset database: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
