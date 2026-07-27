import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/google_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/observe_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/onboarding/data/datasources/onboarding_local_data_source.dart';
import '../../features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/clear_onboarding_draft_usecase.dart';
import '../../features/onboarding/domain/usecases/fetch_conditions_usecase.dart';
import '../../features/onboarding/domain/usecases/check_profile_completed_usecase.dart';
import '../../features/onboarding/domain/usecases/load_onboarding_draft_usecase.dart';
import '../../features/onboarding/domain/usecases/save_onboarding_draft_usecase.dart';
import '../../features/onboarding/domain/usecases/save_onboarding_usecase.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/onboarding/domain/repositories/wellness_repository.dart';
import '../../features/onboarding/data/repositories/wellness_repository_impl.dart';
import '../../features/dashboard/presentation/bloc/wellness_bloc.dart';

/// Service Locator instance.
final sl = GetIt.instance;

/// Initializes all dependencies of the application.
/// Registered in order: External -> Core -> Features (Data, Domain, Presentation).
Future<void> initDependencies() async {
  // ==========================================
  // External Layers
  // ==========================================
  // Initialize Hive
  await Hive.initFlutter();
  final preferencesBox = await Hive.openBox(AppConstants.userPreferencesBox);
  sl.registerLazySingleton<Box>(() => preferencesBox);
  
  final checkInBox = await Hive.openBox(AppConstants.checkInBox);
  final recordingsBox = await Hive.openBox(AppConstants.recordingsBox);
  
  // Register http.Client and ApiClient
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl(), sl()));

  // ==========================================
  // Core Layer
  // ==========================================
  // Place to register global utilities like NetworkInfo, ApiClient, local database services

  // ==========================================
  // Features Layer - Authentication
  // ==========================================
  // DataSources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));
  sl.registerLazySingleton(() => ObserveUserUseCase(sl()));

  // ==========================================
  // Features Layer - Onboarding & Wellness
  // ==========================================
  // DataSources
  sl.registerLazySingleton<OnboardingLocalDataSource>(() => OnboardingLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<OnboardingRemoteDataSource>(() => OnboardingRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ));
  sl.registerLazySingleton<WellnessRepository>(() => WellnessRepositoryImpl(
        checkInBox: checkInBox,
        recordingsBox: recordingsBox,
      ));

  // UseCases
  sl.registerLazySingleton(() => SaveOnboardingUseCase(sl()));
  sl.registerLazySingleton(() => FetchConditionsUseCase(sl()));
  sl.registerLazySingleton(() => CheckProfileCompletedUseCase(sl()));
  sl.registerLazySingleton(() => SaveOnboardingDraftUseCase(sl()));
  sl.registerLazySingleton(() => LoadOnboardingDraftUseCase(sl()));
  sl.registerLazySingleton(() => ClearOnboardingDraftUseCase(sl()));

  // Blocs
  sl.registerFactory(
    () => SplashBloc(sl(), sl()),
  );
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      resetPasswordUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      googleSignInUseCase: sl(),
      observeUserUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => OnboardingBloc(
      saveOnboardingUseCase: sl(),
      fetchConditionsUseCase: sl(),
      saveOnboardingDraftUseCase: sl(),
      loadOnboardingDraftUseCase: sl(),
      clearOnboardingDraftUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => WellnessBloc(
      repository: sl(),
    ),
  );
}
