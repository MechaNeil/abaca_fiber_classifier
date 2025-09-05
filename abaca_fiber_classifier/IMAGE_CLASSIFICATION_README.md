# Image Classification App

This is a Flutter application that performs image classification using TensorFlow Lite with the specified dependencies:

- `tflite_flutter: ^0.11.0`
- `image_picker: ^1.2.0`
- `image: ^4.5.4`

## Features

- **Image Selection**: Pick images from gallery or capture using camera
- **Real-time Classification**: Classify images using a pre-trained MobileNetV3 model
- **Confidence Scores**: Display prediction confidence percentages
- **User-friendly Interface**: Clean and intuitive UI

## Model Information

The app uses a MobileNetV3 model (`mobilenetv3small_fixed.tflite`) that can classify the following categories:

- EF
- G
- H
- I
- JK
- M1
- S2
- S3

## How to Use

1. **Launch the App**: Start the Flutter application
2. **Select an Image**:
   - Tap "Gallery" to choose from your photo library
   - Tap "Camera" to capture a new image
3. **Classify**: Tap "Classify Image" to run the TensorFlow Lite model
4. **View Results**: See the prediction and confidence score

## Technical Implementation

### Dependencies Used

```yaml
dependencies:
  tflite_flutter: ^0.11.0 # TensorFlow Lite Flutter plugin
  image_picker: ^1.2.0 # Image selection from gallery/camera
  image: ^4.5.4 # Image processing and manipulation
```

### Key Features of Implementation

1. **Model Loading**:

   - Loads the TFLite model from assets using `Interpreter.fromAsset()`
   - Properly handles model initialization and cleanup

2. **Image Processing**:

   - Resizes images to 224x224 pixels (MobileNet standard input size)
   - Converts images to the required tensor format
   - Normalizes pixel values to [0, 1] range

3. **TensorFlow Lite Integration**:

   - Uses `tflite_flutter: ^0.11.0` properly with the Interpreter class
   - Handles input/output tensor shapes dynamically
   - Runs inference with proper error handling

4. **Image Selection**:

   - Uses `image_picker: ^1.2.0` for gallery and camera access
   - Handles permissions for both Android and iOS
   - Supports both ImageSource.gallery and ImageSource.camera

5. **Image Processing**:
   - Uses `image: ^4.5.4` for image decoding and resizing
   - Proper pixel access using the modern API (pixel.r, pixel.g, pixel.b)
   - Efficient tensor conversion

## Permissions

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture images for classification.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images for classification.</string>
```

## Running the App

1. Ensure you have Flutter installed and configured
2. Connect an Android device or start an emulator
3. Run: `flutter pub get`
4. Run: `flutter run`

## Code Structure

- **main.dart**: Main application file containing:
  - UI components and layout
  - Image selection logic
  - TensorFlow Lite model integration
  - Image preprocessing and classification
  - Results display

## Model Assets

- `assets/mobilenetv3small_fixed.tflite`: The trained model file
- `assets/labels.txt`: Class labels for the model

## Error Handling

The app includes comprehensive error handling for:

- Model loading failures
- Image selection cancellation
- Image processing errors
- Classification failures
- Permission denials

## Performance Considerations

- Efficient image resizing before classification
- Proper tensor format conversion
- Memory management with model cleanup
- Asynchronous operations to maintain UI responsiveness
