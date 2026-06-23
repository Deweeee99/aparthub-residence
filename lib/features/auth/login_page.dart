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
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/apartHub-logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apart Hub',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Resident access portal',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).moveY(begin: -10, end: 0),
              const SizedBox(height: 44),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ).animate().fadeIn(delay: 100.ms).moveY(begin: 10, end: 0),
              const SizedBox(height: 8),
              Text(
                'Login with your registered resident account to continue.',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 180.ms).moveY(begin: 10, end: 0),
              const SizedBox(height: 30),
              GlassCard(
                padding: const EdgeInsets.all(22),
                fillColor: AppColors.glassFillStrong,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InputLabel(text: 'Login'),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('username-field'),
                      controller: _loginController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Email or mobile number',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InputLabel(text: 'Password'),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('password-field'),
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      onSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _isPasswordVisible
                              ? 'Hide password'
                              : 'Show password',
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AbsorbPointer(
                      absorbing: _isLoading,
                      child: Opacity(
                        opacity: _isLoading ? 0.72 : 1,
                        child: LuxuryButton(
                          key: const ValueKey('login-button'),
                          label: _isLoading
                              ? 'Signing In...'
                              : 'Login to Dashboard',
                          icon: _isLoading
                              ? Icons.hourglass_top_rounded
                              : Icons.login_rounded,
                          onPressed: _handleLogin,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 260.ms).moveY(begin: 20, end: 0),
              const SizedBox(height: 18),
              Text(
                'Your resident session is validated securely before access is granted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 360.ms),
            ],
          ),
        ),
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
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
