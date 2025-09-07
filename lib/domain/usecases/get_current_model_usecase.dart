import '../repositories/classification_repository.dart';

/// Use case for getting the current model name
///
/// This use case retrieves the name of the currently active model
/// being used for classifications.
class GetCurrentModelUseCase {
  final ClassificationRepository _repository;

  GetCurrentModelUseCase(this._repository);

  /// Gets the current model name
  ///
  /// Returns: The filename of the currently active model
  ///
  /// Throws:
  /// - [Exception] if the operation fails
  Future<String> execute() async {
    try {
      return await _repository.getCurrentModelName();
    } catch (e) {
      throw Exception('Failed to get current model name: ${e.toString()}');
    }
  }
}
