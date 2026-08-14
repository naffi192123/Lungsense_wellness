import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/network_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/widgets/offline_banner.dart';

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
    return BlocProvider<NetworkCubit>(
      create: (_) => di.sl<NetworkCubit>(),
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return OfflineBanner(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
