# Model Switching and TensorFlow Lite Runtime Restart Implementation

## Problem Solved
When switching models through the admin panel, the TensorFlow Lite interpreter was not properly reloading the new model. The app continued to use the cached model in memory, making model switching ineffective.

## Solution Implemented

### 1. Added Model Reloading Infrastructure

**New Use Case: `ReloadModelUseCase`**
```dart
// lib/domain/usecases/reload_model_usecase.dart
class ReloadModelUseCase {
  final ClassificationRepository repository;

  ReloadModelUseCase(this.repository);

  Future<(ModelInfo, List<String>)> call() async {
    final modelInfo = await repository.reloadModel();
    final labels = await repository.loadLabels();
    return (modelInfo, labels);
  }
}
```

**Enhanced ML Service with Force Reload**
```dart
// lib/services/ml_service.dart
/// Force reload the model (used when switching models)
Future<ModelInfo> reloadModel() async {
  // Dispose of the current interpreter
  dispose();
  
  // Load the new model
  return await loadModel();
}
```

**Updated Classification Repository**
```dart
// lib/domain/repositories/classification_repository.dart
abstract class ClassificationRepository {
  // ... existing methods
  Future<ModelInfo> reloadModel();
}
```

### 2. TensorFlow Lite Runtime Restart Process

When a model is switched:

1. **Dispose Current Interpreter**: `_interpreter?.close(); _interpreter = null;`
2. **Get New Model Path**: `ModelService.getCurrentModelPath()`
3. **Load New Model**: 
   - For assets: `Interpreter.fromAsset(modelPath)`
   - For files: `Interpreter.fromFile(modelFile)`
4. **Allocate Tensors**: `_interpreter!.allocateTensors()`
5. **Validate Model**: Check input/output tensor shapes and types

### 3. Automatic Model Reload on Switch

**Enhanced Admin View Model**
```dart
// lib/features/admin/presentation/viewmodels/admin_view_model.dart
Future<void> switchToModel(ModelEntity model) async {
  try {
    await _manageModelsUseCase.setActiveModel(model.path);
    _currentModel = model;
    
    // Trigger model reload in classification view model
    if (_classificationViewModel != null) {
      await _classificationViewModel.reloadModel();
      debugPrint('Model reloaded in classification system');
    }
    
    _successMessage = 'Switched to model: ${model.name}';
  } catch (e) {
    _error = 'Failed to switch model: ${e.toString()}';
  }
}
```

### 4. Model Session Restart Workflow

```
User switches model in Admin Panel
         ↓
Admin View Model calls setActiveModel()
         ↓
Model path updated in SharedPreferences
         ↓
Classification View Model.reloadModel() called
         ↓
ML Service.reloadModel() called
         ↓
Current TensorFlow Lite interpreter disposed
         ↓
New model path retrieved from ModelService
         ↓
New TensorFlow Lite interpreter created
         ↓
New model loaded and tensors allocated
         ↓
Classification system ready with new model
```

## Key Features

### Complete TensorFlow Lite Runtime Restart
- **Proper Disposal**: Old interpreter is completely closed and nullified
- **Fresh Initialization**: New interpreter created from scratch
- **Memory Cleanup**: TensorFlow Lite resources properly released
- **Tensor Reallocation**: Input/output tensors reallocated for new model

### Automatic Integration
- **Seamless Admin Integration**: Model switching automatically triggers reload
- **Error Handling**: Comprehensive error handling during model switching
- **Fallback Protection**: Falls back to default model if imported model fails
- **Debug Logging**: Detailed logging for model switching operations

### Session Management
- **State Preservation**: Classification view model state properly maintained
- **UI Updates**: Loading states and notifications during model reload
- **Persistence**: Model selection persisted across app restarts
- **Validation**: Model file existence and validity checks

## Testing Model Switching

1. **Login as Admin**: Username: `admin`, Password: `admin29`
2. **Access Admin Panel**: Home page → Admin Tools
3. **Import New Model**: Select .tflite file using file picker
4. **Switch Models**: Use "Select" button to switch between models
5. **Verify Switching**: Check debug logs for "Model reloaded in classification system"
6. **Test Classification**: Take photo and verify new model is being used

## Debug Output

When switching models, you'll see console output like:
```
Model reloaded in classification system
Model initialized successfully
Input: shape=[1,224,224,3] type=float32
Output: shape=[1,8] type=float32
```

This confirms the TensorFlow Lite interpreter has been properly restarted with the new model.

## Benefits

- ✅ **Complete Model Isolation**: Each model switch creates fresh TensorFlow Lite session
- ✅ **Memory Efficiency**: Proper cleanup prevents memory leaks
- ✅ **Reliable Switching**: No cached model artifacts from previous sessions
- ✅ **Error Recovery**: Automatic fallback to default model on errors
- ✅ **Performance**: Minimal overhead during model switching
- ✅ **User Experience**: Seamless switching without app restart

The implementation ensures that when you switch models through the admin panel, the TensorFlow Lite runtime is completely restarted, guaranteeing that the imported model is fully loaded and actively used for classifications.
