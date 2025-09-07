# Model Switching Testing Guide

## Overview
This guide helps you test the TensorFlow Lite model switching functionality to ensure that the runtime is properly restarted when switching models.

## Prerequisites
- Admin access (username: `admin`, password: `admin29`)
- At least one additional .tflite model file to import and test

## Testing Steps

### 1. Initial Setup
1. Launch the abaca fiber classifier app
2. Login as admin using credentials: `admin` / `admin29`
3. Navigate to the home page and locate the "Admin Tools" section

### 2. Import a Test Model
1. Click "Import/Update Model" button
2. Navigate to "Model Management" tab
3. Click "Import Model" button
4. Select a .tflite file from your device
5. Provide a descriptive name for the model
6. Verify import success message appears

### 3. Test Model Switching
1. In the Model Management section, you should see:
   - Default model (assets/mobilenetv3small_b2.tflite)
   - Your imported model
2. Click "Select" on your imported model
3. Confirm the switch in the dialog
4. **Check console output** for these debug messages:
   ```
   Loading model from path: [your_model_path]
   Model loaded successfully with input: shape=[1,224,224,3] type=float32, output: shape=[1,8] type=float32
   Model reloaded in classification system
   ```

### 4. Verify Model is Active
1. Go back to the main classification page
2. Take or select a photo for classification
3. The classification should now use your imported model
4. **Note**: Results may differ if your model has different training data

### 5. Test Fallback Mechanism
1. Manually delete the imported model file from device storage (optional advanced test)
2. Try to switch to the deleted model
3. Should see error message and automatic revert to previous working model

### 6. Switch Back to Default
1. Return to Admin Tools → Model Management
2. Click "Select" on the default model
3. Verify successful switch with console output:
   ```
   Loading model from path: assets/mobilenetv3small_b2.tflite
   Model loaded successfully...
   Model reloaded in classification system
   ```

## Expected Console Output

### Successful Model Switch:
```
I/flutter: Loading model from path: /data/user/0/com.example.abaca_fiber_classifier/app_flutter/models/my_model_1693234567890.tflite
I/flutter: Loading file model: /data/user/0/com.example.abaca_fiber_classifier/app_flutter/models/my_model_1693234567890.tflite
I/flutter: Model loaded successfully with input: shape=[1,224,224,3] type=float32, output: shape=[1,8] type=float32
I/flutter: Model reloaded in classification system
```

### Failed Model Switch (with recovery):
```
I/flutter: Error during model reload, attempting fallback to default: Exception: Model file does not exist: /invalid/path/model.tflite
I/flutter: Model file not found: /invalid/path/model.tflite, reverting to default
I/flutter: Loading model from path: assets/mobilenetv3small_b2.tflite
I/flutter: Loading asset model: assets/mobilenetv3small_b2.tflite
I/flutter: Model loaded successfully with input: shape=[1,224,224,3] type=float32, output: shape=[1,8] type=float32
```

## Troubleshooting

### "Invalid argument(s): Unable to create interpreter" Error
**Causes:**
- Corrupted .tflite file
- Invalid model file format
- Insufficient permissions to read model file
- Model file was deleted after import

**Solutions:**
1. Verify the .tflite file is valid and not corrupted
2. Try importing a different known-good .tflite file
3. Check that the imported model file still exists on device
4. The app should automatically fall back to default model

### Model Switch Shows Success but Classification Uses Old Model
**Causes:**
- TensorFlow Lite interpreter not properly restarted
- Model path not updated in ModelService

**Solutions:**
1. Check console logs for "Model reloaded in classification system" message
2. Restart the app if issue persists
3. File a bug report with console logs

### UI Shows Wrong Current Model
**Causes:**
- Admin view model state not synchronized with actual model service

**Solutions:**
1. Navigate away from admin panel and back
2. Restart the app
3. Check SharedPreferences for current_model_path key

## Verification Checklist

- [ ] Can import new .tflite models successfully
- [ ] Model switching shows success message
- [ ] Console shows "Model reloaded in classification system"
- [ ] Console shows correct model path being loaded
- [ ] Classification results change when using different models (if models differ)
- [ ] Can switch back to default model
- [ ] Error handling works when model file is invalid/missing
- [ ] App automatically falls back to default model on errors
- [ ] No memory leaks or crashes during model switching

## Performance Notes

- Model switching takes 2-5 seconds depending on model size
- TensorFlow Lite interpreter is completely restarted (not just reloaded)
- Previous model memory is fully released before loading new model
- No app restart required for model switching

## Debug Mode

To enable additional debug output, add these lines in your development environment:
```dart
// In MLService.loadModel()
debugPrint('TensorFlow Lite interpreter created successfully');
debugPrint('Input tensor allocated: $inputInfo');
debugPrint('Output tensor allocated: $outputInfo');
```

This ensures the TensorFlow Lite runtime is properly restarted and your imported models are fully loaded and active.
