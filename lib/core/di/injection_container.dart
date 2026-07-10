import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  
  // Register Hive instance or boxes if needed (to be added in specific features)

  // ==========================================
  // Core Layer
  // ==========================================
  // Place to register global utilities like NetworkInfo, ApiClient, local database services

  // ==========================================
  // Features Layer
  // ==========================================
  // Blocs, UseCases, Repositories, and DataSources will be registered here as features are built
}
