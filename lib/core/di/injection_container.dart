import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../network/network_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/confirm_reset_password_usecase.dart';
import '../../features/auth/domain/usecases/google_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/observe_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/onboarding/data/datasources/onboarding_local_data_source.dart';
import '../../features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import '../../features/daily_log/data/datasources/daily_log_remote_data_source.dart';
import '../../features/dashboard/data/datasources/score_remote_data_source.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
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
import '../../features/recording/data/services/audio_recorder_service.dart';
import '../../features/recording/data/services/audio_player_service.dart';
import '../../features/recording/data/services/file_picker_service.dart';
import '../../features/recording/data/datasources/audio_recording_remote_data_source.dart';
import '../../features/recording/data/repositories/audio_recording_repository_impl.dart';
import '../../features/recording/domain/repositories/audio_recording_repository.dart';
import '../../features/recording/domain/usecases/upload_audio_usecase.dart';
import '../../features/recording/domain/usecases/get_job_status_usecase.dart';
import '../../features/recording/domain/usecases/check_and_record_consent_usecase.dart';
import '../../features/recording/presentation/bloc/audio_recording_bloc.dart';
import '../../features/dashboard/presentation/bloc/wellness_bloc.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/daily_checkin/presentation/bloc/daily_checkin_bloc.dart';

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
  final scoreBox = await Hive.openBox('score_history_box');
  
  // Register http.Client, NetworkInfo, NetworkCubit, and ApiClient
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerFactory<NetworkCubit>(() => NetworkCubit(sl()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl(), sl(), sl()));

  // ==========================================
  // Features Layer - Authentication & Profile
  // ==========================================
  // DataSources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ConfirmResetPasswordUseCase(sl()));
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
  sl.registerLazySingleton<DailyLogRemoteDataSource>(() => DailyLogRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ScoreRemoteDataSource>(() => ScoreRemoteDataSourceImpl(sl()));

  sl.registerLazySingleton<AudioRecordingRemoteDataSource>(
    () => AudioRecordingRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
      ));
  sl.registerLazySingleton<WellnessRepository>(() => WellnessRepositoryImpl(
        checkInBox: checkInBox,
        recordingsBox: recordingsBox,
        scoreBox: scoreBox,
        dailyLogRemoteDataSource: sl(),
        scoreRemoteDataSource: sl(),
        audioRecordingRemoteDataSource: sl(),
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
      forgotPasswordUseCase: sl(),
      confirmResetPasswordUseCase: sl(),
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

  // ==========================================
  // Features Layer - Audio Recording & Processing
  // ==========================================
  // Services
  sl.registerLazySingleton<AudioRecorderService>(() => AudioRecorderService());
  sl.registerLazySingleton<AudioPlayerService>(() => AudioPlayerService());
  sl.registerLazySingleton<FilePickerService>(() => FilePickerService());

  // Repositories
  sl.registerLazySingleton<AudioRecordingRepository>(
    () => AudioRecordingRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => UploadAudioUseCase(sl()));
  sl.registerLazySingleton(() => GetJobStatusUseCase(sl()));
  sl.registerLazySingleton(() => CheckAndRecordConsentUseCase(sl()));

  // Blocs
  sl.registerFactory(
    () => AudioRecordingBloc(
      recorderService: sl(),
      filePickerService: sl(),
      uploadAudioUseCase: sl(),
      getJobStatusUseCase: sl(),
      checkAndRecordConsentUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => WellnessBloc(repository: sl()),
  );

  sl.registerFactory(
    () => AnalyticsBloc(repository: sl()),
  );

  sl.registerFactory(
    () => DailyCheckinBloc(
      scoreRemoteDataSource: sl(),
      wellnessRepository: sl(),
    ),
  );
}
