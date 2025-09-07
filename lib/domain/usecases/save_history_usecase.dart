import '../entities/classification_history.dart';
import '../repositories/history_repository.dart';

/// Use case for saving classification history
///
/// This use case encapsulates the business logic for saving
/// a classification result to the history database.
class SaveHistoryUseCase {
  final HistoryRepository _historyRepository;

  SaveHistoryUseCase(this._historyRepository);

  /// Executes the save history operation
  ///
  /// Parameters:
  /// - [imagePath]: The path to the classified image
  /// - [predictedLabel]: The predicted classification label
  /// - [confidence]: The confidence score of the prediction
  /// - [probabilities]: The probability scores for all classes
  /// - [userId]: Optional user ID for multi-user support
  /// - [model]: The model used for classification
  ///
  /// Returns: The ID of the saved history record
  ///
  /// Throws:
  /// - [Exception] if the save operation fails
  Future<int> execute({
    required String imagePath,
    required String predictedLabel,
    required double confidence,
    required List<double> probabilities,
    int? userId,
    String model = 'mobilenetv3small_b2.tflite',
  }) async {
    try {
      // Validate input parameters
      if (imagePath.trim().isEmpty) {
        throw Exception('Image path cannot be empty');
      }

      if (predictedLabel.trim().isEmpty) {
        throw Exception('Predicted label cannot be empty');
      }

      if (confidence < 0 || confidence > 1) {
        throw Exception('Confidence must be between 0 and 1');
      }

      if (probabilities.isEmpty) {
        throw Exception('Probabilities list cannot be empty');
      }

      // Create the history record
      final history = ClassificationHistory(
        imagePath: imagePath,
        predictedLabel: predictedLabel,
        confidence: confidence,
        probabilities: probabilities,
        timestamp: DateTime.now(),
        userId: userId,
        model: model,
      );

      // Save to repository
      return await _historyRepository.saveHistory(history);
    } catch (e) {
      throw Exception('Failed to save classification history: ${e.toString()}');
    }
  }
}
