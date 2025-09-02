class AppConstants {
  // Model Configuration
  static const String modelPath = 'assets/mobilenetv3small_b2.tflite';
  static const String labelsPath = 'assets/labels.txt';

  // Image Processing
  static const int imageWidth = 224;
  static const int imageHeight = 224;
  static const int imageChannels = 3;

  // UI Constants
  static const String appTitle = 'Abaca Prototype';
  static const String pageTitle = 'TFLite MobileNetV3 Inference';
  static const String pickImageButtonText = 'Pick image';

  // Image Display
  static const double imageDisplayHeight = 220.0;
  static const double borderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double largeSpacing = 16.0;
}
