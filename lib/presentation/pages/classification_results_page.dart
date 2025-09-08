import 'package:flutter/material.dart';
import 'dart:io';
import '../../domain/entities/classification_result.dart';
import '../widgets/camera_with_guide_overlay.dart';
import '../../core/utils/grade_colors.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/classification_view_model.dart';

class ClassificationResultsPage extends StatefulWidget {
  final String imagePath;
  final ClassificationResult? result;
  final List<String>? labels;
  final bool isError;
  final VoidCallback? onRetakePhoto;
  final VoidCallback? onNewClassification;
  final AuthViewModel? authViewModel;
  final ClassificationViewModel? classificationViewModel;

  const ClassificationResultsPage({
    super.key,
    required this.imagePath,
    this.result,
    this.labels,
    this.isError = false,
    this.onRetakePhoto,
    this.onNewClassification,
    this.authViewModel,
    this.classificationViewModel,
  });

  @override
  State<ClassificationResultsPage> createState() =>
      _ClassificationResultsPageState();
}

class _ClassificationResultsPageState extends State<ClassificationResultsPage> {
  bool _isExpanded = false; // State to track if grade distribution is expanded
  String? _currentModelName; // Track current model name for admin display

  bool get isAdmin =>
      widget.authViewModel?.loggedInUser?.isAdmin == true;

  @override
  void initState() {
    super.initState();
    _loadCurrentModelName();
  }

  Future<void> _loadCurrentModelName() async {
    if (isAdmin && widget.classificationViewModel != null) {
      try {
        final modelName = await widget.classificationViewModel!
            .getCurrentModelName();
        if (mounted) {
          setState(() {
            _currentModelName = modelName;
          });
        }
      } catch (e) {
        // Handle error silently - admin feature shouldn't break the page
        debugPrint('Error loading model name: $e');
      }
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    // You need to add intl package to your pubspec.yaml: intl: ^0.18.0
    // import 'package:intl/intl.dart';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}, ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  void _showClassificationGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ClassificationGuidePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Results',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Image Display
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.imagePath.startsWith('assets/')
                          ? Image.asset(
                              widget.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Results or Error Content
                  if (widget.isError) ...[
                    // Error State
                    const Icon(Icons.warning, size: 60, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text(
                      "We couldn't classify\nthe fiber",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Please make sure the photo is clear,\nwell-lit, and shows an abaca fiber",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Follow the Classification Guide for best results",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ] else if (widget.result != null &&
                      widget.result!.confidence <= 0.5) ...[
                    // Low Confidence State (≤50%)
                    const Icon(Icons.warning, size: 60, color: Colors.amber),
                    const SizedBox(height: 16),

                    // Show different messages based on user role
                    if (isAdmin) ...[
                      // Admin users see the original message
                      const Text(
                        "We couldn't classify\nthe fiber",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ] else ...[
                      // Non-admin users see "Cannot be classified"
                      const Text(
                        "Cannot be classified",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      "Please make sure the photo is clear,\nwell-lit, and shows an abaca fiber",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Follow the Classification Guide for best results",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),

                    // Grade Distribution for Low Confidence - Only show for admin users
                    if (isAdmin) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Possible Grade Distribution',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isExpanded ? 'Show less' : 'Show all',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      AnimatedRotation(
                                        turns: _isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Icon(
                                          Icons.keyboard_arrow_up,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Grade bars for low confidence - admin only
                            if (widget.result!.probabilities.isNotEmpty) ...[
                              _buildAllGradeBars(
                                widget.result!.probabilities,
                                widget.labels,
                                _isExpanded,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ] else if (widget.result != null) ...[
                    // Success State
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'GRADE ${widget.result!.predictedLabel.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Admin-only: Model Information
                    if (isAdmin && _currentModelName != null) ...[
                      Text(
                        'Model: $_currentModelName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Confidence
                    Text(
                      'Confidence: ${(widget.result!.confidence * 100).toInt()}%',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

                    // Grade Distribution - Show for admin users or non-admin users with ≥50% confidence
                    if (isAdmin ||
                        (widget.result!.confidence > 0.5)) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Grade Distribution',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isExpanded ? 'Show less' : 'Show all',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      AnimatedRotation(
                                        turns: _isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Icon(
                                          Icons.keyboard_arrow_up,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Grade bars
                            if (widget.result!.probabilities.isNotEmpty) ...[
                              _buildAllGradeBars(
                                widget.result!.probabilities,
                                widget.labels,
                                _isExpanded,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // Timestamp
                    Text(
                      _formatTimestamp(DateTime.now()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        (widget.isError ||
                            (widget.result != null &&
                                widget.result!.confidence <= 0.5))
                        ? _showClassificationGuide
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      (widget.isError ||
                              (widget.result != null &&
                                  widget.result!.confidence <= 0.5))
                          ? 'View Guide'
                          : 'Done',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (widget.isError ||
                            (widget.result != null &&
                                widget.result!.confidence <= 0.5))
                        ? widget.onRetakePhoto
                        : widget.onNewClassification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            (widget.isError ||
                                    (widget.result != null &&
                                        widget.result!.confidence <= 0.5))
                                ? 'Retake Photo'
                                : 'New',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllGradeBars(
    List<double> probabilities,
    List<String>? modelLabels,
    bool showAll,
  ) {
    // Use model labels if available, otherwise fall back to default grades
    final List<String> allGrades =
        modelLabels ?? ['EF', 'G', 'H', 'I', 'JK', 'M1', 'S2', 'S3'];

    // Define colors for different grades using centralized utility
    final Map<String, Color> gradeColors = {
      for (String grade in allGrades) grade: GradeColors.getGradeColor(grade),
    };

    // Create a list of grade-probability pairs and sort by probability (highest first)
    List<MapEntry<String, double>> gradeProbs = [];
    for (int i = 0; i < allGrades.length && i < probabilities.length; i++) {
      gradeProbs.add(MapEntry(allGrades[i], probabilities[i]));
    }

    // Sort by probability (descending order)
    gradeProbs.sort((a, b) => b.value.compareTo(a.value));

    // Filter based on showAll flag
    if (showAll) {
      // Show all 8 grades regardless of probability
      // Keep all grades that have corresponding probabilities
      gradeProbs = gradeProbs.take(8).toList();

      // If we have fewer than 8 grades, pad with remaining grades at 0% probability
      if (gradeProbs.length < 8) {
        final existingGrades = gradeProbs.map((e) => e.key).toSet();
        final remainingGrades = allGrades
            .where((grade) => !existingGrades.contains(grade))
            .toList();

        for (
          int i = 0;
          i < remainingGrades.length && gradeProbs.length < 8;
          i++
        ) {
          gradeProbs.add(MapEntry(remainingGrades[i], 0.0));
        }
      }
    } else {
      // Show only top 4 grades
      gradeProbs = gradeProbs.take(4).toList();
    }

    return Column(
      children: [
        for (int i = 0; i < gradeProbs.length; i++) ...[
          _buildGradeBar(
            gradeProbs[i].key,
            gradeProbs[i].value,
            gradeColors[gradeProbs[i].key] ?? Colors.grey,
          ),
          if (i < gradeProbs.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildGradeBar(String grade, double probability, Color color) {
    final percentage = (probability * 100)
        .round(); // Use round() for better accuracy
    return Row(
      children: [
        SizedBox(
          width: 24, // Slightly wider to accommodate longer grade names
          child: Text(
            grade,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: probability.clamp(0.0, 1.0), // Ensure valid range
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35, // Slightly wider for 3-digit percentages
          child: Text(
            '$percentage%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
