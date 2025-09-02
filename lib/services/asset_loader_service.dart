import 'package:flutter/services.dart' show rootBundle;
import '../core/constants/app_constants.dart';

class AssetLoaderService {
  Future<List<String>> loadLabels() async {
    try {
      final labelsTxt = await rootBundle.loadString(AppConstants.labelsPath);
      return labelsTxt
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      throw Exception('Failed to load labels: $e');
    }
  }
}
