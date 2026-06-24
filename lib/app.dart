import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/resident/resident_shell.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/api_service.dart';
import 'services/auth_storage_service.dart';
import 'services/language_storage_service.dart';

class ApartHubResidenceApp extends StatefulWidget {
  const ApartHubResidenceApp({
    super.key,
    this.apiService,
    this.authStorageService,
    this.languageStorageService,
  });

  final ApiService? apiService;
  final AuthStorageService? authStorageService;
  final LanguageStorageService? languageStorageService;

  @override
  State<ApartHubResidenceApp> createState() => _ApartHubResidenceAppState();
}

class _ApartHubResidenceAppState extends State<ApartHubResidenceApp> {
  late final LanguageStorageService _languageStorageService =
      widget.languageStorageService ?? LanguageStorageService();

  var _locale = const Locale('id');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await _languageStorageService.loadLocale();
    if (!mounted) {
      return;
    }
    setState(() => _locale = locale);
  }

  Future<void> _changeLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) {
      return;
    }
    setState(() => _locale = locale);
    await _languageStorageService.saveLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAuthStorageService =
        widget.authStorageService ?? AuthStorageService();
    final resolvedApiService =
        widget.apiService ??
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
          builder: (context, state) => ResidentShell(
            apiService: resolvedApiService,
            currentLocale: _locale,
            onLocaleChanged: _changeLocale,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      builder: DevicePreview.appBuilder,
      title: 'ApartHub Residence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightLuxuryTheme,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
