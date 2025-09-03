import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/repositories/classification_repository_impl.dart';
import '../data/repositories/history_repository_impl.dart';
import '../domain/usecases/initialize_model_usecase.dart';
import '../domain/usecases/pick_image_usecase.dart';
import '../domain/usecases/classify_image_usecase.dart';
import '../domain/usecases/save_history_usecase.dart';
import '../domain/usecases/get_history_usecase.dart';
import '../domain/usecases/delete_history_usecase.dart';
import '../services/ml_service.dart';
import '../services/image_picker_service.dart';
import '../services/asset_loader_service.dart';
import '../presentation/viewmodels/classification_view_model.dart';
import '../presentation/viewmodels/history_view_model.dart';
import '../presentation/pages/classification_page_with_auth.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/usecases/register_user_usecase.dart';
import '../features/auth/domain/usecases/login_user_usecase.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/auth/presentation/pages/auth_wrapper.dart';

class AbacaApp extends StatefulWidget {
  const AbacaApp({super.key});

  @override
  State<AbacaApp> createState() => _AbacaAppState();
}

class _AbacaAppState extends State<AbacaApp> {
  late final ClassificationRepositoryImpl _repository;
  late final ClassificationViewModel _viewModel;
  late final AuthRepositoryImpl _authRepository;
  late final AuthViewModel _authViewModel;
  late final HistoryRepositoryImpl _historyRepository;
  late final HistoryViewModel _historyViewModel;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  void _initializeDependencies() {
    try {
      // Initialize classification services
      final mlService = MLService();
      final imagePickerService = ImagePickerService();
      final assetLoaderService = AssetLoaderService();

      // Initialize classification repository
      _repository = ClassificationRepositoryImpl(
        mlService: mlService,
        imagePickerService: imagePickerService,
        assetLoaderService: assetLoaderService,
      );

      // Initialize classification use cases
      final initializeModelUseCase = InitializeModelUseCase(_repository);
      final pickImageUseCase = PickImageUseCase(_repository);
      final classifyImageUseCase = ClassifyImageUseCase(_repository);

      // Initialize classification view model
      _viewModel = ClassificationViewModel(
        initializeModelUseCase: initializeModelUseCase,
        pickImageUseCase: pickImageUseCase,
        classifyImageUseCase: classifyImageUseCase,
      );

      // Initialize auth repository
      _authRepository = AuthRepositoryImpl();

      // Initialize auth use cases
      final registerUserUseCase = RegisterUserUseCase(_authRepository);
      final loginUserUseCase = LoginUserUseCase(_authRepository);

      // Initialize auth view model
      _authViewModel = AuthViewModel(
        registerUserUseCase: registerUserUseCase,
        loginUserUseCase: loginUserUseCase,
      );

      // Initialize history repository
      _historyRepository = HistoryRepositoryImpl();

      // Initialize history use cases
      final saveHistoryUseCase = SaveHistoryUseCase(_historyRepository);
      final getHistoryUseCase = GetHistoryUseCase(_historyRepository);
      final deleteHistoryUseCase = DeleteHistoryUseCase(_historyRepository);

      // Initialize history view model
      _historyViewModel = HistoryViewModel(
        getHistoryUseCase: getHistoryUseCase,
        deleteHistoryUseCase: deleteHistoryUseCase,
        saveHistoryUseCase: saveHistoryUseCase,
      );
    } catch (e) {
      // Log initialization error but continue with app startup
      debugPrint('Error initializing dependencies: $e');
      rethrow;
    }
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
      home: AuthWrapper(
        authViewModel: _authViewModel,
        mainAppBuilder: (authViewModel) => ClassificationPageWithAuth(
          viewModel: _viewModel,
          authViewModel: authViewModel,
          historyViewModel: _historyViewModel,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
