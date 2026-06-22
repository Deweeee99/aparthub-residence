import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/resident/resident_shell.dart';
import 'features/splash/splash_screen.dart';

class ApartHubResidenceApp extends StatelessWidget {
  const ApartHubResidenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/resident',
          builder: (context, state) => const ResidentShell(),
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
