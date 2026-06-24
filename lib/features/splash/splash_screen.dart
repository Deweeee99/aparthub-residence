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
        body: Stack(
          children: [
            const _SplashDecorations(),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SplashLogo()
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(0.96, 0.96),
                            end: const Offset(1.04, 1.04),
                            duration: 1100.ms,
                          ),

                      const SizedBox(height: 28),

                      Text(
                            'APARTHUB',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .moveY(begin: 12, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        'Integrated Apartment\nManagement Platform',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(delay: 180.ms, duration: 500.ms),

                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Secure Resident Access',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 280.ms, duration: 450.ms),

                      const SizedBox(height: 40),

                      const SizedBox(
                        width: 88,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                          backgroundColor: AppColors.borderSoft,
                          color: AppColors.gold,
                        ),
                      ).animate().fadeIn(delay: 360.ms, duration: 450.ms),

                      const SizedBox(height: 16),

                      Text(
                        'Memverifikasi sesi akun Anda...',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fadeIn(delay: 420.ms, duration: 450.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.42),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Image.asset(
          'assets/images/apartHub-logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _SplashDecorations extends StatelessWidget {
  const _SplashDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -95,
            right: -75,
            child: Container(
              width: 255,
              height: 255,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -88,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: -44,
            bottom: 88,
            child: Icon(
              Icons.apartment_rounded,
              size: 230,
              color: AppColors.navy.withValues(alpha: 0.045),
            ),
          ),
        ],
      ),
    );
  }
}
