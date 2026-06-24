
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/luxury_background.dart';
import '../../core/widgets/luxury_button.dart';
import '../../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isPasswordVisible = false;
  var _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) {
      return;
    }

    final inputLogin = _loginController.text.trim();
    final inputPassword = _passwordController.text;

    if (inputLogin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login tidak boleh kosong.')),
      );
      return;
    }

    if (inputPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.loginResident(
        login: inputLogin,
        password: inputPassword,
      );

      if (!mounted) {
        return;
      }

      context.go('/resident');
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ApiServiceException
          ? error.message
          : 'Login gagal. Periksa kembali akun dan password Anda.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              _LoginHero(
                loginController: _loginController,
                passwordController: _passwordController,
                isPasswordVisible: _isPasswordVisible,
                isLoading: _isLoading,
                onPasswordVisibilityChanged: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                onLogin: _handleLogin,
              ).animate().fadeIn(duration: 420.ms).moveY(begin: 16, end: 0),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _LoginSecurityNotice(),
              ).animate().fadeIn(delay: 240.ms, duration: 380.ms),

              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Text(
                  'Akses resident dilindungi dan akan diverifikasi sebelum dashboard dapat digunakan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                ),
              ).animate().fadeIn(delay: 340.ms, duration: 360.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({
    required this.loginController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.onPasswordVisibilityChanged,
    required this.onLogin,
  });

  final TextEditingController loginController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoading;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 248,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.navy,
                  Color(0xFF103B86),
                  AppColors.blue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned(
            right: -34,
            bottom: 220,
            child: Icon(
              Icons.apartment_rounded,
              size: 230,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          Positioned(
            right: 34,
            top: 40,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/apartHub-logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APARTHUB RESIDENCE',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Resident Digital Platform',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            top: 104,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Masuk untuk mengakses layanan hunian Anda.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 180,
            left: 20,
            right: 20,
            child: GlassCard(
              padding: const EdgeInsets.all(22),
              fillColor: AppColors.glassFillStrong,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masuk ke Akun Anda',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Gunakan akun resident yang telah terdaftar.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 22),

                  const _InputLabel(text: 'EMAIL ATAU NOMOR PONSEL'),
                  const SizedBox(height: 8),

                  TextField(
                    key: const ValueKey('username-field'),
                    controller: loginController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Masukkan email atau nomor ponsel',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const _InputLabel(text: 'PASSWORD'),
                  const SizedBox(height: 8),

                  TextField(
                    key: const ValueKey('password-field'),
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => onLogin(),
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: isPasswordVisible
                            ? 'Sembunyikan password'
                            : 'Tampilkan password',
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: onPasswordVisibilityChanged,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  AbsorbPointer(
                    absorbing: isLoading,
                    child: Opacity(
                      opacity: isLoading ? 0.72 : 1,
                      child: LuxuryButton(
                        key: const ValueKey('login-button'),
                        label: isLoading
                            ? 'Signing In...'
                            : 'MASUK',
                        icon: isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.login_rounded,
                        onPressed: onLogin,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginSecurityNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.navy.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.navy,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akses Aman',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data resident dan aktivitas akun diproses melalui sesi terautentikasi.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.35,
          ),
    );
  }
}
