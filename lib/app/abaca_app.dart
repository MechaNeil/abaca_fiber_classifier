import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/repositories/classification_repository_impl.dart';
import '../domain/usecases/initialize_model_usecase.dart';
import '../domain/usecases/pick_image_usecase.dart';
import '../domain/usecases/classify_image_usecase.dart';
import '../services/ml_service.dart';
import '../services/image_picker_service.dart';
import '../services/asset_loader_service.dart';
import '../presentation/viewmodels/classification_view_model.dart';
import '../presentation/pages/classification_page.dart';

class AbacaApp extends StatefulWidget {
  const AbacaApp({super.key});

  @override
  State<AbacaApp> createState() => _AbacaAppState();
}

class _AbacaAppState extends State<AbacaApp> {
  late final ClassificationRepositoryImpl _repository;
  late final ClassificationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // Initialize services
    final mlService = MLService();
    final imagePickerService = ImagePickerService();
    final assetLoaderService = AssetLoaderService();

    // Initialize repository
    _repository = ClassificationRepositoryImpl(
      mlService: mlService,
      imagePickerService: imagePickerService,
      assetLoaderService: assetLoaderService,
    );

    // Initialize use cases
    final initializeModelUseCase = InitializeModelUseCase(_repository);
    final pickImageUseCase = PickImageUseCase(_repository);
    final classifyImageUseCase = ClassifyImageUseCase(_repository);

    // Initialize view model
    _viewModel = ClassificationViewModel(
      initializeModelUseCase: initializeModelUseCase,
      pickImageUseCase: pickImageUseCase,
      classifyImageUseCase: classifyImageUseCase,
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: ClassificationPage(viewModel: _viewModel),
      debugShowCheckedModeBanner: false,
    );
  }
}
