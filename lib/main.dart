import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

void main() async {
  // Ensure Flutter engine is initialized before calling platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection & Hive
  await di.initDependencies();

  runApp(const LungSenseApp());
}

class LungSenseApp extends StatelessWidget {
  const LungSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
