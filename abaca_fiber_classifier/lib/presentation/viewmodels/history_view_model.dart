import 'package:flutter/material.dart';
import '../../domain/entities/classification_history.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/delete_history_usecase.dart';
import '../../domain/usecases/save_history_usecase.dart';

/// ViewModel for managing classification history state and operations
///
/// This ViewModel handles:
/// - Loading and displaying history records
/// - Filtering history by grade
/// - Deleting history records
/// - Providing recent history for the home page
/// - Managing loading states and errors
class HistoryViewModel extends ChangeNotifier {
  final GetHistoryUseCase _getHistoryUseCase;
  final DeleteHistoryUseCase _deleteHistoryUseCase;
  final SaveHistoryUseCase _saveHistoryUseCase;

  HistoryViewModel({
    required GetHistoryUseCase getHistoryUseCase,
    required DeleteHistoryUseCase deleteHistoryUseCase,
    required SaveHistoryUseCase saveHistoryUseCase,
  }) : _getHistoryUseCase = getHistoryUseCase,
       _deleteHistoryUseCase = deleteHistoryUseCase,
       _saveHistoryUseCase = saveHistoryUseCase;

  // State variables
  bool _isLoading = false;
  String? _error;
  List<ClassificationHistory> _allHistory = [];
  List<ClassificationHistory> _recentHistory = [];
  Map<String, int> _statistics = {};
  String _selectedGradeFilter = 'All';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ClassificationHistory> get allHistory => _allHistory;
  List<ClassificationHistory> get recentHistory => _recentHistory;
  Map<String, int> get statistics => _statistics;
  String get selectedGradeFilter => _selectedGradeFilter;
  int get totalCount => _allHistory.length;

  /// Gets filtered history based on selected grade
  List<ClassificationHistory> get filteredHistory {
    if (_selectedGradeFilter == 'All') {
      return _allHistory;
    }
    return _allHistory
        .where((history) => history.predictedLabel == _selectedGradeFilter)
        .toList();
  }

  /// Gets available grade filters from the history data
  List<String> get availableGrades {
    final grades = _allHistory.map((h) => h.predictedLabel).toSet().toList();
    grades.sort();
    return ['All', ...grades];
  }

  /// Gets grade statistics as a list for display
  List<MapEntry<String, int>> get gradeStatistics {
    return _statistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Loads all history records
  Future<void> loadAllHistory() async {
    await _performOperation(() async {
      _allHistory = await _getHistoryUseCase.getAllHistory();
    });
  }

  /// Loads recent history records (for home page)
  Future<void> loadRecentHistory({int limit = 3}) async {
    await _performOperation(() async {
      _recentHistory = await _getHistoryUseCase.getRecentHistory(limit: limit);
    });
  }

  /// Loads history statistics
  Future<void> loadStatistics() async {
    await _performOperation(() async {
      _statistics = await _getHistoryUseCase.getHistoryStatistics();
    });
  }

  /// Loads all history data (history, recent, and statistics)
  Future<void> loadCompleteHistory() async {
    await _performOperation(() async {
      // Load all data in parallel for better performance
      final futures = await Future.wait([
        _getHistoryUseCase.getAllHistory(),
        _getHistoryUseCase.getRecentHistory(limit: 3),
        _getHistoryUseCase.getHistoryStatistics(),
      ]);

      _allHistory = futures[0] as List<ClassificationHistory>;
      _recentHistory = futures[1] as List<ClassificationHistory>;
      _statistics = futures[2] as Map<String, int>;
    });
  }

  /// Saves a new classification to history
  Future<void> saveClassification({
    required String imagePath,
    required String predictedLabel,
    required double confidence,
    required List<double> probabilities,
    int? userId,
  }) async {
    try {
      await _saveHistoryUseCase.execute(
        imagePath: imagePath,
        predictedLabel: predictedLabel,
        confidence: confidence,
        probabilities: probabilities,
        userId: userId,
      );

      // Reload data after saving
      await loadCompleteHistory();
    } catch (e) {
      _setError('Failed to save classification: ${e.toString()}');
    }
  }

  /// Deletes a specific history record
  Future<bool> deleteHistory(int id) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _deleteHistoryUseCase.deleteHistory(id);

      if (success) {
        // Remove from local lists
        _allHistory.removeWhere((history) => history.id == id);
        _recentHistory.removeWhere((history) => history.id == id);

        // Reload statistics
        await loadStatistics();
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to delete history: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clears all history records
  Future<bool> clearAllHistory() async {
    try {
      _setLoading(true);
      _clearError();

      final deletedCount = await _deleteHistoryUseCase.clearAllHistory();

      if (deletedCount > 0) {
        _allHistory.clear();
        _recentHistory.clear();
        _statistics.clear();
        notifyListeners();
      }

      return deletedCount > 0;
    } catch (e) {
      _setError('Failed to clear history: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the grade filter
  void setGradeFilter(String grade) {
    if (_selectedGradeFilter != grade) {
      _selectedGradeFilter = grade;
      notifyListeners();
    }
  }

  /// Refreshes all data
  Future<void> refresh() async {
    await loadCompleteHistory();
  }

  /// Performs an operation with loading state management
  Future<void> _performOperation(Future<void> Function() operation) async {
    try {
      _setLoading(true);
      _clearError();
      await operation();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Sets an error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clears the current error
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Clears the error state (for UI to call)
  void clearError() {
    _clearError();
  }
}
