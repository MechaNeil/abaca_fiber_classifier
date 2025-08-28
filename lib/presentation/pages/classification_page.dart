import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../viewmodels/classification_view_model.dart';
import '../widgets/image_display_widget.dart';
import '../widgets/prediction_result_widget.dart';
import '../widgets/probability_list_widget.dart';
import '../widgets/loading_indicator_widget.dart';
import '../widgets/model_info_widget.dart';

class ClassificationPage extends StatefulWidget {
  final ClassificationViewModel viewModel;

  const ClassificationPage({Key? key, required this.viewModel})
    : super(key: key);

  @override
  State<ClassificationPage> createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  @override
  void initState() {
    super.initState();
    // Initialize the model when the page loads
    widget.viewModel.initializeModel();
    // Listen to changes in the view model
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    // This will trigger a rebuild when the view model state changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.pageTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pick Image Button and Loading Indicator
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: widget.viewModel.canPredict
                      ? widget.viewModel.pickAndClassifyImage
                      : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text(AppConstants.pickImageButtonText),
                ),
                const SizedBox(width: AppConstants.mediumSpacing),
                LoadingIndicatorWidget(isVisible: widget.viewModel.isLoading),
              ],
            ),

            const SizedBox(height: AppConstants.mediumSpacing),

            // Selected Image Display
            ImageDisplayWidget(imagePath: widget.viewModel.imagePath),

            const SizedBox(height: AppConstants.largeSpacing),

            // Error Display
            if (widget.viewModel.error != null)
              Text(
                widget.viewModel.error!,
                style: const TextStyle(color: Colors.red),
              ),

            // Model Information
            ModelInfoWidget(modelInfo: widget.viewModel.modelInfo),

            if (widget.viewModel.modelInfo != null)
              const SizedBox(height: AppConstants.smallSpacing),

            // Prediction Results
            PredictionResultWidget(
              result: widget.viewModel.classificationResult,
            ),

            if (widget.viewModel.classificationResult != null)
              const SizedBox(height: AppConstants.mediumSpacing),

            // Probability List
            ProbabilityListWidget(
              labels: widget.viewModel.labels,
              probabilities: widget.viewModel.probabilities,
            ),
          ],
        ),
      ),
    );
  }
}
