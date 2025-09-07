import 'package:flutter/material.dart';
import '../viewmodels/classification_view_model.dart';
import '../viewmodels/history_view_model.dart';
import '../widgets/image_source_selection_modal_with_guide.dart';
import '../widgets/camera_with_guide_overlay.dart';
import '../widgets/recent_history_widget.dart';
import 'classification_results_page.dart';
import 'history_page.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/admin/presentation/viewmodels/admin_view_model.dart';
import '../../features/admin/presentation/pages/admin_page.dart';

/// Classification page with authentication support
///
/// This page extends the original classification page by adding
/// logout functionality and user information display.
class ClassificationPageWithAuth extends StatefulWidget {
  final ClassificationViewModel viewModel;
  final AuthViewModel authViewModel;
  final HistoryViewModel historyViewModel;
  final AdminViewModel? adminViewModel;

  const ClassificationPageWithAuth({
    super.key,
    required this.viewModel,
    required this.authViewModel,
    required this.historyViewModel,
    this.adminViewModel,
  });

  @override
  State<ClassificationPageWithAuth> createState() =>
      _ClassificationPageWithAuthState();
}

class _ClassificationPageWithAuthState
    extends State<ClassificationPageWithAuth> {
  bool _showModelReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize the model when the page loads
    widget.viewModel.initializeModel();
    // Listen to changes in the view model
    widget.viewModel.addListener(_onViewModelChanged);
    // Listen to admin view model changes if available
    widget.adminViewModel?.addListener(_onAdminViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    widget.adminViewModel?.removeListener(_onAdminViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    // This will trigger a rebuild when the view model state changes
    if (mounted) {
      // Check if model just became ready
      if (widget.viewModel.isModelInitialized &&
          !widget.viewModel.isLoading &&
          !_showModelReady) {
        setState(() {
          _showModelReady = true;
        });

        // Hide the indicator after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showModelReady = false;
            });
          }
        });
      }

      setState(() {});
      // Check for classification view model errors and show dialog
      _checkAndShowClassificationErrors();
    }
  }

  void _onAdminViewModelChanged() {
    // Handle admin view model changes and show errors
    if (mounted) {
      setState(() {});
      _checkAndShowAdminErrors();
    }
  }

  void _checkAndShowClassificationErrors() {
    final error = widget.viewModel.error;
    if (error != null && error.contains('Failed to reload model:')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Clear the error after detecting it
          widget.viewModel.clearError();
        }
      });
    }
  }

  void _checkAndShowAdminErrors() {
    final adminError = widget.adminViewModel?.error;
    if (adminError != null && adminError.contains('Failed to load model')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Clear the error after detecting it
          widget.adminViewModel?.clearError();
        }
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.authViewModel.logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceSelectionModalWithGuide(
        onImageSelected: (imagePath) {
          _classifyImage(imagePath);
        },
      ),
    );
  }

  Widget _buildModelStatusIndicator() {
    final classificationError = widget.viewModel.error;
    final adminError = widget.adminViewModel?.error;
    final isModelInitialized = widget.viewModel.isModelInitialized;
    final isLoading = widget.viewModel.isLoading;
    final isSwitchingModel = widget.adminViewModel?.isSwitchingModel ?? false;

    // Show loading indicator when model is being switched or loaded
    if (isLoading || isSwitchingModel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isSwitchingModel ? 'Switching model...' : 'Loading model...',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Show error indicator if there are model-related errors
    if (classificationError != null || adminError != null) {
      final errorText = classificationError ?? adminError ?? '';
      final isModelError =
          errorText.contains('Failed to reload model:') ||
          errorText.contains('Failed to load model') ||
          errorText.contains('Critical error:');

      if (isModelError) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Model Error Detected',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Using default model for safety',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    // Show success indicator when model is ready and flag is true
    if (isModelInitialized && !isLoading && _showModelReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 8),
            Text(
              'Model Ready',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Return empty container if no special status to show
    return const SizedBox.shrink();
  }

  bool _canClassify() {
    // Check if model is initialized
    if (!widget.viewModel.isModelInitialized) {
      return false;
    }

    // Check if currently loading or switching models
    if (widget.viewModel.isLoading ||
        (widget.adminViewModel?.isSwitchingModel ?? false)) {
      return false;
    }

    // Check for model-related errors
    final classificationError = widget.viewModel.error;
    final adminError = widget.adminViewModel?.error;

    if (classificationError != null &&
        classificationError.contains('Failed to reload model:')) {
      return false;
    }

    if (adminError != null && adminError.contains('Failed to load model')) {
      return false;
    }

    return true;
  }

  void _showClassificationGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ClassificationGuidePage()),
    );
  }

  void _classifyImage(String imagePath) async {
    // Check if model is ready and there are no critical errors
    if (!widget.viewModel.isModelInitialized) {
      _showErrorSnackBar(
        'Model is not ready. Please wait for initialization to complete.',
      );
      return;
    }

    // Check for existing model errors
    final classificationError = widget.viewModel.error;
    final adminError = widget.adminViewModel?.error;
    if (classificationError != null &&
        classificationError.contains('Failed to reload model:')) {
      _showErrorSnackBar(
        'Cannot classify: Model error detected. Please check model status.',
      );
      return;
    }
    if (adminError != null && adminError.contains('Failed to load model')) {
      _showErrorSnackBar(
        'Cannot classify: Model switching error detected. Please check model status.',
      );
      return;
    }

    try {
      // Set loading state
      setState(() {
        // Update state as needed
      });

      // Process the image and get classification result
      await widget.viewModel.classifyImageFromPath(imagePath);

      // Check if classification was successful
      if (widget.viewModel.error != null) {
        // Classification failed, show error
        if (mounted) {
          _showErrorSnackBar(
            'Classification failed: ${widget.viewModel.error}',
          );
        }
        return;
      }

      // Save classification to history if successful
      if (widget.viewModel.classificationResult != null && mounted) {
        final result = widget.viewModel.classificationResult!;
        final user = widget.authViewModel.loggedInUser;

        try {
          // Get the current model name being used
          final currentModel = await widget.viewModel.getCurrentModelName();

          await widget.historyViewModel.saveClassification(
            imagePath: imagePath,
            predictedLabel: result.predictedLabel,
            confidence: result.confidence,
            probabilities: result.probabilities,
            userId: user?.id,
            model: currentModel,
          );
        } catch (e) {
          // Log error but don't prevent navigation
          debugPrint('Failed to save classification to history: $e');
        }
      }

      // Navigate to results page
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassificationResultsPage(
              imagePath: imagePath,
              result: widget.viewModel.classificationResult,
              labels: widget.viewModel.labels,
              isError: widget.viewModel.error != null,
              authViewModel: widget.authViewModel,
              classificationViewModel: widget.viewModel,
              onRetakePhoto: () {
                Navigator.of(context).pop();
                _showImageSourceModal();
              },
              onNewClassification: () {
                Navigator.of(context).pop();
                _showImageSourceModal();
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      debugPrint('Unexpected error during classification: $e');
      if (mounted) {
        // Show error message
        _showErrorSnackBar(
          'An unexpected error occurred during classification.',
        );

        // Still navigate to results page to show error state
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassificationResultsPage(
              imagePath: imagePath,
              result: null,
              labels: widget.viewModel.labels,
              isError: true,
              authViewModel: widget.authViewModel,
              classificationViewModel: widget.viewModel,
              onRetakePhoto: () {
                Navigator.of(context).pop();
                _showImageSourceModal();
              },
            ),
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showViewHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryPage(
          viewModel: widget.historyViewModel,
          authViewModel: widget.authViewModel,
        ),
      ),
    );
  }

  void _navigateToAdminTools() {
    if (widget.adminViewModel != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AdminPage(viewModel: widget.adminViewModel!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authViewModel.loggedInUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: const Icon(
          Icons.wb_sunny_outlined,
          color: Colors.orange,
          size: 28,
        ),
        actions: [
          // Admin tools button (only for admin users)
          if (user != null && user.isAdmin && widget.adminViewModel != null)
            IconButton(
              onPressed: _navigateToAdminTools,
              icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
              tooltip: 'Admin Tools',
            ),
          // User profile icon
          if (user != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutDialog();
                } else if (value == 'admin' &&
                    user.isAdmin &&
                    widget.adminViewModel != null) {
                  _navigateToAdminTools();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (user.isAdmin)
                        const Text(
                          'Administrator',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                if (user.isAdmin && widget.adminViewModel != null)
                  const PopupMenuItem<String>(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Admin Tools',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                if (user.isAdmin && widget.adminViewModel != null)
                  const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Logo and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ABACA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'FIBER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'CLASSIFIER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Model Status Indicator
            _buildModelStatusIndicator(),

            const SizedBox(height: 16),

            // Classify New Button
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: _canClassify() ? _showImageSourceModal : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canClassify() ? Colors.green : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _canClassify() ? 'Classify New' : 'Model Error',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // View Guide Button
            SizedBox(
              width: 200,
              height: 50,
              child: OutlinedButton(
                onPressed: _showClassificationGuide,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View Guide',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // View History Button
            SizedBox(
              width: 200,
              height: 50,
              child: OutlinedButton(
                onPressed: _showViewHistory,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'View History',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Recent Section
            RecentHistoryWidget(
              historyViewModel: widget.historyViewModel,
              authViewModel: widget.authViewModel,
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          currentIndex: 0, // Home is selected
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Classify',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                // Already on home
                break;
              case 1:
                _showImageSourceModal();
                break;
              case 2:
                _showViewHistory();
                break;
              case 3:
                // Settings placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings - Coming Soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                break;
            }
          },
        ),
      ),
    );
  }
}
