import 'package:flutter/material.dart';

/// Centralized color scheme for fiber grades
///
/// This utility provides consistent color coding across the entire app
/// for different fiber grades, ensuring visual consistency between
/// classification results, history page, and recent widgets.
class GradeColors {
  static const Map<String, Color> _gradeColorMap = {
    // Primary grades with full color scheme
    'EF': Colors.purple,
    'G': Colors.orange,
    'H': Colors.red,
    'I': Colors.pink,
    'JK': Colors.blue,
    'M1': Colors.teal,
    'S2': Colors.green,
    'S3': Colors.lightGreen,

    // Legacy grade formats for backward compatibility
    'grade_ef': Colors.purple,
    'grade_g': Colors.orange,
    'grade_h': Colors.red,
    'grade_i': Colors.pink,
    'grade_jk': Colors.blue,
    'grade_m1': Colors.teal,
    'grade_s2': Colors.green,
    'grade_s3': Colors.lightGreen,

    // Alternative formats
    'grade_1': Colors.orange, // Maps to G
    'ef': Colors.purple,
    'g': Colors.orange,
    'h': Colors.red,
    'i': Colors.pink,
    'jk': Colors.blue,
    'm1': Colors.teal,
    's2': Colors.green,
    's3': Colors.lightGreen,
  };

  /// Gets the color for a specific grade
  ///
  /// [grade] - The grade string (e.g., 'S2', 'grade_s2', 'JK')
  /// Returns the corresponding color or a default color if not found
  static Color getGradeColor(String grade) {
    final normalizedGrade = grade.toLowerCase().trim();
    return _gradeColorMap[normalizedGrade] ?? Colors.grey;
  }

  /// Gets all available grade colors as a map
  ///
  /// Returns a map of normalized grade names to their colors
  static Map<String, Color> getAllGradeColors() {
    return Map.from(_gradeColorMap);
  }

  /// Formats a grade name for display
  ///
  /// [grade] - The grade string to format
  /// Returns a properly formatted grade name
  static String formatGradeName(String grade) {
    if (grade.toLowerCase() == 'all') return grade;

    final normalizedGrade = grade.toLowerCase().trim();

    switch (normalizedGrade) {
      case 'ef':
      case 'grade_ef':
        return 'Grade EF';
      case 'g':
      case 'grade_g':
      case 'grade_1':
        return 'Grade G';
      case 'h':
      case 'grade_h':
        return 'Grade H';
      case 'i':
      case 'grade_i':
        return 'Grade I';
      case 'jk':
      case 'grade_jk':
        return 'Grade JK';
      case 'm1':
      case 'grade_m1':
        return 'Grade M1';
      case 's2':
      case 'grade_s2':
        return 'Grade S2';
      case 's3':
      case 'grade_s3':
        return 'Grade S3';
      default:
        return grade.toUpperCase();
    }
  }

  /// Gets a short grade name for compact display
  ///
  /// [grade] - The grade string to shorten
  /// Returns a short version of the grade name
  static String getShortGradeName(String grade) {
    final normalizedGrade = grade.toLowerCase().trim();

    switch (normalizedGrade) {
      case 'ef':
      case 'grade_ef':
        return 'EF';
      case 'g':
      case 'grade_g':
      case 'grade_1':
        return 'G';
      case 'h':
      case 'grade_h':
        return 'H';
      case 'i':
      case 'grade_i':
        return 'I';
      case 'jk':
      case 'grade_jk':
        return 'JK';
      case 'm1':
      case 'grade_m1':
        return 'M1';
      case 's2':
      case 'grade_s2':
        return 'S2';
      case 's3':
      case 'grade_s3':
        return 'S3';
      default:
        // Safe substring that handles short strings
        if (grade.length >= 2) {
          return grade.substring(0, 2).toUpperCase();
        } else if (grade.isNotEmpty) {
          return grade.substring(0, 1).toUpperCase();
        } else {
          return '?';
        }
    }
  }

  /// Checks if a grade has a defined color
  ///
  /// [grade] - The grade string to check
  /// Returns true if the grade has a defined color
  static bool hasGradeColor(String grade) {
    final normalizedGrade = grade.toLowerCase().trim();
    return _gradeColorMap.containsKey(normalizedGrade);
  }
}
