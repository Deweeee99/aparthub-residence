import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/resident/resident_shell.dart';
import 'features/splash/splash_screen.dart';
import 'services/api_service.dart';
import 'services/auth_storage_service.dart';

class ApartHubResidenceApp extends StatelessWidget {
  const ApartHubResidenceApp({
    super.key,
    this.apiService,
    this.authStorageService,
  });

  final ApiService? apiService;
  final AuthStorageService? authStorageService;

  @override
  Widget build(BuildContext context) {
    final resolvedAuthStorageService =
        authStorageService ?? AuthStorageService();
    final resolvedApiService =
        apiService ??
        ApiService(authStorageService: resolvedAuthStorageService);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => SplashScreen(
            apiService: resolvedApiService,
            authStorageService: resolvedAuthStorageService,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              LoginPage(apiService: resolvedApiService),
        ),
        GoRoute(
          path: '/resident',
          builder: (context, state) =>
              ResidentShell(apiService: resolvedApiService),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'ApartHub Residence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightLuxuryTheme,
      routerConfig: router,
    );
  }
}
