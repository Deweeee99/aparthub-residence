import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/luxury_background.dart';
import '../../services/api_service.dart';
import '../../services/app_debug_logger.dart';
import '../../services/auth_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.apiService,
    this.authStorageService,
    this.delay = const Duration(milliseconds: 1800),
  });

  final ApiService? apiService;
  final AuthStorageService? authStorageService;
  final Duration delay;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthStorageService _authStorageService =
      widget.authStorageService ?? AuthStorageService();
  late final ApiService _apiService =
      widget.apiService ?? ApiService(authStorageService: _authStorageService);

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    await Future.delayed(widget.delay);

    final token = await _authStorageService.getToken();
    appDebugLog(
      'Splash',
      token == null || token.isEmpty
          ? 'No stored token found'
          : 'Stored token found ${maskToken(token)}',
    );

    if (!mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      context.go('/login');
      return;
    }

    try {
      await _apiService.getResidentMe();
      if (!mounted) {
        return;
      }
      appDebugLog('Splash', 'Resident session valid, opening dashboard');
      context.go('/resident');
    } catch (_) {
      appDebugLog('Splash', 'Resident session invalid, clearing local session');
      await _authStorageService.clearSession();
      if (!mounted) {
        return;
      }
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.20),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/apartHub-logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1.04, 1.04),
                      duration: 1100.ms,
                    ),
                const SizedBox(height: 28),
                Text(
                  'Apart Hub',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(duration: 500.ms).moveY(begin: 12, end: 0),
                const SizedBox(height: 10),
                Text(
                  'Integrated Apartment Management Platform',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 180.ms, duration: 500.ms),
                const Spacer(),
                SizedBox(
                  width: 64,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: AppColors.borderSoft,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
