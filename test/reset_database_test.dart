import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abaca_fiber_classifier/features/auth/data/database_service.dart';

void main() {
  test('Reset database test', () async {
    // WARNING: This will delete all data!
    await DatabaseService.instance.resetDatabase();
    debugPrint('Database reset completed successfully!');
  });
}
