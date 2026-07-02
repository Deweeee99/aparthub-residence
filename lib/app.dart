import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/resident/resident_shell.dart';
import 'features/resident/services/service_request/pages/service_assigned_step_page.dart';
import 'features/resident/services/service_request/pages/service_completed_step_page.dart';
import 'features/resident/services/service_request/pages/service_create_step_page.dart';
import 'features/resident/services/service_request/pages/service_describe_step_page.dart';
import 'features/resident/services/service_request/pages/service_history_step_page.dart';
import 'features/resident/services/service_request/pages/service_progress_step_page.dart';
import 'features/resident/services/service_request/pages/service_submitted_step_page.dart';
import 'features/resident/services/service_request/service_request_flow_controller.dart';
import 'features/resident/services/service_request/service_request_flow_scope.dart';
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
  late final AuthStorageService _authStorageService =
      widget.authStorageService ?? AuthStorageService();
  late final ApiService _apiService =
      widget.apiService ?? ApiService(authStorageService: _authStorageService);
  late final ServiceRequestFlowController _serviceRequestFlowController =
      ServiceRequestFlowController(apiService: _apiService);

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
  void dispose() {
    _serviceRequestFlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => SplashScreen(
            apiService: _apiService,
            authStorageService: _authStorageService,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(apiService: _apiService),
        ),
        GoRoute(
          path: '/resident',
          builder: (context, state) => _residentShell(currentIndex: 0),
        ),
        GoRoute(
          path: '/resident/access',
          builder: (context, state) => _residentShell(currentIndex: 1),
        ),
        GoRoute(
          path: '/resident/services',
          builder: (context, state) => _residentShell(currentIndex: 2),
        ),
        GoRoute(
          path: '/resident/community',
          builder: (context, state) => _residentShell(currentIndex: 3),
        ),
        GoRoute(
          path: '/resident/profile',
          builder: (context, state) => _residentShell(currentIndex: 4),
        ),
        GoRoute(
          path: '/resident/services/request/create',
          builder: (context, state) => _residentShell(
            currentIndex: 2,
            serviceChild: const ServiceCreateRequestPage(),
          ),
        ),
        GoRoute(
          path: '/resident/services/request/describe',
          builder: (context, state) => _residentShell(
            currentIndex: 2,
            serviceChild: const ServiceDescribeRequestPage(),
          ),
        ),
        GoRoute(
          path: '/resident/services/request/submitted',
          builder: (context, state) => _residentShell(
            currentIndex: 2,
            serviceChild: const ServiceSubmittedRequestPage(),
          ),
        ),
        GoRoute(
          path: '/resident/services/request/history',
          builder: (context, state) => _residentShell(
            currentIndex: 2,
            serviceChild: const ServiceHistoryRequestPage(),
          ),
        ),
        GoRoute(
          path: '/resident/services/request/assigned/:ticketId',
          builder: (context, state) => _residentShell(
            currentIndex: 2,
            serviceChild: ServiceAssignedRequestPage(
              ticketId: _ticketIdFromState(state),
            ),
          ),
        ),
        GoRoute(
          path: '/resident/services/request/progress/:ticketId',
          builder: (context, state) => _residentShell(
            currentIndex: 2,
            serviceChild: ServiceProgressRequestPage(
              ticketId: _ticketIdFromState(state),
            ),
          ),
        ),
        GoRoute(
          path: '/resident/services/request/completed/:ticketId',
          builder: (context, state) => _residentShell(
            currentIndex: 2,
            serviceChild: ServiceCompletedRequestPage(
              ticketId: _ticketIdFromState(state),
            ),
          ),
        ),
      ],
    );

    return ServiceRequestFlowScope(
      controller: _serviceRequestFlowController,
      child: MaterialApp.router(
        builder: DevicePreview.appBuilder,
        title: 'ApartHub Residence',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightLuxuryTheme,
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
  }

  ResidentShell _residentShell({
    required int currentIndex,
    Widget? serviceChild,
  }) {
    return ResidentShell(
      apiService: _apiService,
      currentLocale: _locale,
      onLocaleChanged: _changeLocale,
      currentIndex: currentIndex,
      serviceChild: serviceChild,
    );
  }

  int _ticketIdFromState(GoRouterState state) {
    return int.tryParse(state.pathParameters['ticketId'] ?? '') ?? 0;
  }
}
