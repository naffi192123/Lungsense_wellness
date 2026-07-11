import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';

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
  
  // Register Supabase Client
  sl.registerLazySingleton<supabase.SupabaseClient>(() => supabase.Supabase.instance.client);

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

  // Blocs
  sl.registerFactory(
    () => SplashBloc(sl()),
  );
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      resetPasswordUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );
}
