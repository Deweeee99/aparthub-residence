import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aparthub_residance/app.dart';
import 'package:aparthub_residance/models/resident_user.dart';
import 'package:aparthub_residance/models/community_announcement_models.dart';
import 'package:aparthub_residance/models/service_request_models.dart';
import 'package:aparthub_residance/models/visitor_access_models.dart';
import 'package:aparthub_residance/core/theme/app_theme.dart';
import 'package:aparthub_residance/core/widgets/luxury_button.dart';
import 'package:aparthub_residance/features/auth/login_page.dart';
import 'package:aparthub_residance/features/resident/access/access_page.dart';
import 'package:aparthub_residance/features/resident/billing/billing_page.dart';
import 'package:aparthub_residance/features/resident/community/community_page.dart';
import 'package:aparthub_residance/features/resident/home/resident_home_page.dart';
import 'package:aparthub_residance/features/resident/profile/profile_page.dart';
import 'package:aparthub_residance/features/resident/resident_shell.dart';
import 'package:aparthub_residance/features/resident/services/service_request_page.dart';
import 'package:aparthub_residance/features/resident/services/widgets/service_attachment_section.dart';
import 'package:aparthub_residance/features/resident/services/services_page.dart';
import 'package:aparthub_residance/l10n/generated/app_localizations.dart';
import 'package:aparthub_residance/services/api_client.dart';
import 'package:aparthub_residance/features/splash/splash_screen.dart';
import 'package:aparthub_residance/services/api_service.dart';
import 'package:aparthub_residance/services/auth_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('service ticket parses string attachments from api response', () {
    final ticket = ServiceTicketRecord.fromJson({
      'id': 77,
      'ticket_number': 'SR-2026-077',
      'title': 'Attachment string response',
      'attachments': [
        'http://localhost/storage/service-requests/attachments/photo-one.jpg',
        '/storage/service-requests/attachments/photo%20two.png',
      ],
    });

    expect(ticket.attachments, hasLength(2));
    expect(ticket.attachments.first.url, contains('photo-one.jpg'));
    expect(ticket.attachments.first.fileName, 'photo-one.jpg');
    expect(ticket.attachments.last.fileName, 'photo two.png');
  });

  testWidgets('app boots into splash screen', (tester) async {
    final storage = FakeAuthStorageService();
    final api = FakeApiService(storage: storage);
    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Apart Hub'), findsOneWidget);
    expect(
      find.text('Integrated Apartment Management Platform'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
  });

  testWidgets('splash navigates to login after delay', (tester) async {
    final storage = FakeAuthStorageService();
    final api = FakeApiService(storage: storage);
    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('app defaults to Indonesian locale on login', (tester) async {
    final storage = FakeAuthStorageService();
    final api = FakeApiService(storage: storage);

    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
  });

  testWidgets('app loads saved English locale on startup', (tester) async {
    SharedPreferences.setMockInitialValues({'aparthub_locale': 'en'});
    final storage = FakeAuthStorageService();
    final api = FakeApiService(storage: storage);

    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('profile language switch updates labels without restart', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var locale = const Locale('id');

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return _localizedMaterialApp(
            locale: locale,
            home: Scaffold(
              body: ProfilePage(
                resident: _residentUser(),
                currentLocale: locale,
                onLocaleChanged: (value) => setState(() => locale = value),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bahasa'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose the app language.'), findsOneWidget);
  });

  testWidgets('splash navigates to resident when token is valid', (
    tester,
  ) async {
    final storage = FakeAuthStorageService(token: 'resident-token');
    final api = FakeApiService(
      storage: storage,
      meResult: _residentUser(token: 'resident-token'),
    );

    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.byType(ResidentShell), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('splash clears invalid token and returns to login', (
    tester,
  ) async {
    final storage = FakeAuthStorageService(token: 'invalid-token');
    final api = FakeApiService(
      storage: storage,
      meError: const ApiServiceException('Sesi login Anda sudah berakhir.'),
    );

    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(storage.clearSessionCalls, 1);
    expect(storage.token, isNull);
  });

  testWidgets('resident tabs switch correctly', (tester) async {
    final api = FakeApiService(
      meResult: _residentUser(token: 'resident-token'),
    );

    await tester.pumpWidget(MaterialApp(home: ResidentShell(apiService: api)));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Community'), findsAtLeastNWidgets(1));
    expect(find.text('Profile'), findsAtLeastNWidgets(1));
    expect(find.text('Billing'), findsNothing);

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('Service Request'), findsOneWidget);

    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();

    expect(find.byType(CommunityPage), findsOneWidget);
    expect(find.text('Announcement Center'), findsOneWidget);
    expect(find.text('Resident feedback'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Nadia Resident'), findsOneWidget);
  });

  testWidgets('valid api login navigates to resident shell', (tester) async {
    final storage = FakeAuthStorageService();
    final api = FakeApiService(
      storage: storage,
      loginResult: _residentUser(token: 'resident-token'),
    );

    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('username-field')),
      'resident',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'password123',
    );
    await tester.tap(find.text('Login to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.byType(ResidentShell), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Quick Access'),
      find.byKey(const ValueKey('resident-home-page')),
      const Offset(0, -180),
    );
    expect(find.text('Quick Access'), findsOneWidget);
  });

  testWidgets('invalid api login stays on login', (tester) async {
    final storage = FakeAuthStorageService();
    final api = FakeApiService(
      storage: storage,
      loginError: const ApiServiceException(
        'Login gagal. Periksa kembali akun dan password Anda.',
      ),
    );

    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('username-field')),
      'resident',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'wrong-password',
    );
    await tester.tap(find.text('Login to Dashboard'));
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('Login gagal. Periksa kembali akun dan password Anda.'),
      findsOneWidget,
    );
  });

  testWidgets('login validates empty fields locally', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(body: LoginPage(apiService: FakeApiService())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login to Dashboard'));
    await tester.pump();

    expect(find.text('Login tidak boleh kosong.'), findsOneWidget);
  });

  testWidgets('login shows loading state while request is running', (
    tester,
  ) async {
    final completer = Completer<ResidentUser>();
    final api = FakeApiService(loginCompleter: completer);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(body: LoginPage(apiService: api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('username-field')),
      'resident@demo.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pump();

    expect(find.text('Signing In...'), findsOneWidget);
    expect(api.loginCalls, 1);
  });

  testWidgets('home header keeps billing card and removes help cta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(
          body: ResidentHomePage(
            resident: _residentUser(),
            apiService: FakeApiService(
              residentAnnouncements: _communityAnnouncements(),
            ),
            onNavigate: (_) {},
            onOpenBilling: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Quick Access'),
      find.byKey(const ValueKey('resident-home-page')),
      const Offset(0, -180),
    );
    expect(find.text('Monthly billing status'), findsOneWidget);
    expect(find.text('Your Current Balance'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Good Evening, Nadia Resident'), findsOneWidget);
    expect(find.text('Tower Asteria'), findsOneWidget);
    expect(find.text('Unit A-1808'), findsOneWidget);
    expect(find.text('Pay Bill'), findsNothing);
    expect(find.text('Need help from concierge or security?'), findsNothing);

    final balanceTopLeft = tester.getTopLeft(find.text('Your Current Balance'));
    final quickAccessTopLeft = tester.getTopLeft(find.text('Quick Access'));
    expect(balanceTopLeft.dy, lessThan(quickAccessTopLeft.dy));
  });

  testWidgets('monthly billing widget opens hidden billing page', (
    tester,
  ) async {
    final api = FakeApiService(
      meResult: _residentUser(token: 'resident-token'),
    );

    await tester.pumpWidget(MaterialApp(home: ResidentShell(apiService: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('monthly-billing-button')));
    await tester.pumpAndSettle();

    expect(find.byType(BillingPage), findsOneWidget);
    expect(find.text('Billing'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Community'), findsAtLeastNWidgets(1));
    expect(find.text('Profile'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const ValueKey('billing-back-button')));
    await tester.pumpAndSettle();

    expect(find.byType(BillingPage), findsNothing);
    await tester.dragUntilVisible(
      find.text('Quick Access'),
      find.byKey(const ValueKey('resident-home-page')),
      const Offset(0, -180),
    );
    expect(find.text('Quick Access'), findsOneWidget);
  });

  testWidgets('current balance widget uses billing callback', (tester) async {
    var opened = false;

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(
          body: ResidentHomePage(
            resident: _residentUser(),
            apiService: FakeApiService(
              residentAnnouncements: _communityAnnouncements(),
            ),
            onNavigate: (_) {},
            onOpenBilling: () => opened = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('current-balance-billing-button')),
      find.byKey(const ValueKey('resident-home-page')),
      const Offset(0, -220),
    );
    final billingButton = tester.widget<LuxuryButton>(
      find.byKey(const ValueKey('current-balance-billing-button')),
    );
    billingButton.onPressed.call();
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'home today highlights loads api announcements and prioritizes pinned items',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final completer = Completer<List<CommunityAnnouncement>>();
      final api = FakeApiService(announcementListCompleter: completer);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightLuxuryTheme,
          home: Scaffold(
            body: ResidentHomePage(
              resident: _residentUser(),
              apiService: api,
              onNavigate: (_) {},
              onOpenBilling: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading highlights...'), findsOneWidget);

      completer.complete(_homeHighlightAnnouncements());
      await tester.pumpAndSettle();

      expect(find.text('Water meter inspection this Friday'), findsOneWidget);
      expect(find.text('Weekend acoustic evening confirmed'), findsOneWidget);
      expect(find.text('Lobby parcel counter service update'), findsOneWidget);
      expect(find.text('Sky garden deep cleaning schedule'), findsNothing);

      final pinnedTop = tester.getTopLeft(
        find.text('Water meter inspection this Friday'),
      );
      final newerTop = tester.getTopLeft(
        find.text('Weekend acoustic evening confirmed'),
      );
      expect(pinnedTop.dy, lessThan(newerTop.dy));
      expect(api.getAnnouncementsCalls, 1);
    },
  );

  testWidgets('home today highlights opens shared announcement detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(
          body: ResidentHomePage(
            resident: _residentUser(),
            apiService: FakeApiService(
              residentAnnouncements: _homeHighlightAnnouncements(),
              announcementDetail: _communityAnnouncementDetail(),
            ),
            onNavigate: (_) {},
            onOpenBilling: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final highlightTitle = find
        .text('Water meter inspection this Friday')
        .first;
    await tester.ensureVisible(highlightTitle);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Water meter inspection this Friday').hitTestable(),
    );
    await tester.pump();

    expect(find.text('Loading latest details...'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Management Office'), findsOneWidget);
    expect(
      find.textContaining('routine water meter inspection in Tower A'),
      findsOneWidget,
    );
  });

  testWidgets('home today highlights shows error and retry state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(
          body: ResidentHomePage(
            resident: _residentUser(),
            apiService: FakeApiService(
              residentAnnouncementsError: const ApiServiceException(
                'Pengumuman belum bisa dimuat. Coba lagi.',
              ),
            ),
            onNavigate: (_) {},
            onOpenBilling: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Pengumuman belum bisa dimuat. Coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('home today highlights shows empty state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(
          body: ResidentHomePage(
            resident: _residentUser(),
            apiService: FakeApiService(residentAnnouncements: const []),
            onNavigate: (_) {},
            onOpenBilling: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No highlights available yet.'), findsOneWidget);
  });

  testWidgets('home highlight detail failure shows friendly snackbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(
          body: ResidentHomePage(
            resident: _residentUser(),
            apiService: FakeApiService(
              residentAnnouncements: _homeHighlightAnnouncements(),
              announcementDetailError: const ApiServiceException(
                'Detail pengumuman belum bisa dimuat. Coba lagi.',
              ),
            ),
            onNavigate: (_) {},
            onOpenBilling: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final highlightTitle = find
        .text('Water meter inspection this Friday')
        .first;
    await tester.ensureVisible(highlightTitle);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Water meter inspection this Friday').hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Detail pengumuman belum bisa dimuat. Coba lagi.'),
      findsOneWidget,
    );
  });

  testWidgets('access hub is visitor only', (tester) async {
    await _pumpAccessPage(tester);

    expect(find.text('Visitor Access'), findsOneWidget);
    expect(find.text('Register Visitor'), findsWidgets);
    expect(find.text('View History'), findsOneWidget);
    expect(find.text('Parking Access'), findsNothing);
    expect(find.text('Delivery Access'), findsNothing);
    expect(find.text('Guest Access'), findsNothing);
  });

  testWidgets('access hub opens create flow and history', (tester) async {
    await _pumpAccessPage(tester);

    await tester.ensureVisible(find.text('Register Visitor').last);
    await tester.tap(find.text('Register Visitor').last);
    await tester.pumpAndSettle();

    expect(find.text('Register Visitor'), findsWidgets);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('View History'));
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(
      find.text('Track all visitor activity and check-in records.'),
      findsOneWidget,
    );
    expect(find.text('Raka Pratama'), findsOneWidget);
  });

  testWidgets('visitor register starts without dummy defaults', (tester) async {
    await _pumpAccessPage(tester);

    await tester.ensureVisible(find.text('Register Visitor').last);
    await tester.tap(find.text('Register Visitor').last);
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsNothing);
    expect(find.text('+62 812-3456-7890'), findsNothing);
    expect(find.text('Select visit date'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Nama visitor wajib diisi.'), findsOneWidget);
  });

  testWidgets('visitor history loads api data and opens detail by id', (
    tester,
  ) async {
    final api = FakeApiService();
    await _pumpAccessPage(tester, apiService: api);

    await tester.ensureVisible(find.text('View History'));
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(api.getVisitorsCalls, 1);
    expect(api.lastVisitorStatus, isNull);
    expect(find.text('Raka Pratama'), findsOneWidget);
    expect(find.text('Approved'), findsWidgets);

    await tester.tap(find.text('Raka Pratama'));
    await tester.pumpAndSettle();

    expect(api.getVisitorDetailCalls, 1);
    expect(api.lastVisitorDetailId, 41);
    expect(find.text('+62 812-0000-0001'), findsOneWidget);
    expect(find.text('AC-001'), findsOneWidget);

    await tester.ensureVisible(find.text('View QR Pass'));
    await tester.tap(find.text('View QR Pass'));
    await tester.pumpAndSettle();

    expect(api.getVisitorQrCalls, 1);
    expect(api.lastVisitorQrId, 41);
    expect(find.text('AC-41'), findsWidgets);
  });

  testWidgets(
    'approved visitor detail can open qr even when qr flag is false',
    (tester) async {
      final api = FakeApiService(
        visitorDetail: _visitorDetailRecord(qrAvailable: false),
      );
      await _pumpAccessPage(tester, apiService: api);

      await tester.ensureVisible(find.text('View History'));
      await tester.tap(find.text('View History'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Raka Pratama'));
      await tester.pumpAndSettle();

      expect(find.text('Approved'), findsWidgets);
      expect(find.text('View QR Pass'), findsOneWidget);

      await tester.tap(find.text('View QR Pass'));
      await tester.pumpAndSettle();

      expect(api.getVisitorQrCalls, 1);
      expect(api.lastVisitorQrId, 41);
      expect(find.text('AC-41'), findsWidgets);
    },
  );

  testWidgets('visitor history status filter calls api with selected status', (
    tester,
  ) async {
    final api = FakeApiService();
    await _pumpAccessPage(tester, apiService: api);

    await tester.ensureVisible(find.text('View History'));
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    expect(api.getVisitorsCalls, 2);
    expect(api.lastVisitorStatus, 'Pending');
  });

  testWidgets('visitor history api failure shows friendly error', (
    tester,
  ) async {
    await _pumpAccessPage(
      tester,
      apiService: FakeApiService(
        visitorsError: const ApiServiceException(
          'Data visitor belum bisa dimuat. Coba lagi.',
        ),
      ),
    );

    await tester.ensureVisible(find.text('View History'));
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(
      find.text('Data visitor belum bisa dimuat. Coba lagi.'),
      findsOneWidget,
    );
  });

  testWidgets('visitor management completes create flow to history', (
    tester,
  ) async {
    final api = FakeApiService();
    await _pumpAccessPage(tester, apiService: api);

    await tester.ensureVisible(find.text('Register Visitor').last);
    await tester.tap(find.text('Register Visitor').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('visitor-name-field')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('visitor-phone-field')),
      '+62 812-3456-7890',
    );
    await tester.tap(find.text('Visit Family'));
    expect(find.text('Vehicle Number (Optional)'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('visitor-management-page')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Schedule Visit'), findsWidgets);
    expect(find.text('Expected Duration'), findsNothing);
    expect(find.text('Select visit date'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('visitor-visit-date-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14:00'));

    await tester.drag(
      find.byKey(const ValueKey('visitor-management-page')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(api.createVisitorCalls, 1);
    expect(api.getVisitorQrCalls, 1);
    expect(api.lastVisitorQrId, 55);
    expect(api.lastCreateVisitorName, 'Alex Morgan');
    expect(api.lastCreateVisitorPhone, '+62 812-3456-7890');
    expect(
      api.lastCreateVisitDate,
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    expect(api.lastCreateEstimatedArrivalTime, '14:00');
    expect(api.lastCreateGuestCount, 1);
    expect(api.lastCreateVisitPurpose, 'Visit Family');
    expect(find.text('PASS GENERATED'), findsOneWidget);
    expect(find.text('AC-055'), findsWidgets);
    expect(find.text('Approved'), findsWidgets);

    await tester.ensureVisible(find.text('View History'));
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(find.text('Visitor History'), findsWidgets);
    expect(api.getVisitorsCalls, greaterThanOrEqualTo(1));
    expect(find.text('Raka Pratama'), findsOneWidget);
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('Michael Tan'), findsNothing);
  });

  testWidgets('visitor create shows pending message when qr unavailable', (
    tester,
  ) async {
    final api = FakeApiService(
      createdVisitor: _createdVisitorRecord(qrAvailable: false),
      visitorDetail: _createdVisitorRecord(qrAvailable: false),
    );
    await _pumpAccessPage(tester, apiService: api);

    await tester.ensureVisible(find.text('Register Visitor').last);
    await tester.tap(find.text('Register Visitor').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('visitor-name-field')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('visitor-phone-field')),
      '+62 812-3456-7890',
    );
    await tester.tap(find.text('Visit Family'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('visitor-visit-date-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14:00'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('QR pass menunggu approval management.'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(api.getVisitorQrCalls, 0);

    await tester.tap(find.text('Check Approval / Refresh QR'));
    await tester.pumpAndSettle();

    expect(api.getVisitorDetailCalls, 1);
    expect(api.lastVisitorDetailId, 55);
    expect(api.getVisitorQrCalls, 0);
  });

  testWidgets('visitor pending pass refreshes approval and loads qr', (
    tester,
  ) async {
    final api = FakeApiService(
      createdVisitor: _createdVisitorRecord(qrAvailable: false),
      visitorDetail: _createdVisitorRecord(
        qrAvailable: false,
        status: 'Approved',
      ),
    );
    await _pumpAccessPage(tester, apiService: api);

    await tester.ensureVisible(find.text('Register Visitor').last);
    await tester.tap(find.text('Register Visitor').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('visitor-name-field')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('visitor-phone-field')),
      '+62 812-3456-7890',
    );
    await tester.tap(find.text('Visit Family'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('visitor-visit-date-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14:00'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('QR pass menunggu approval management.'), findsOneWidget);
    expect(api.getVisitorQrCalls, 0);

    await tester.tap(find.text('Check Approval / Refresh QR'));
    await tester.pumpAndSettle();

    expect(api.getVisitorDetailCalls, 1);
    expect(api.lastVisitorDetailId, 55);
    expect(api.getVisitorQrCalls, 1);
    expect(api.lastVisitorQrId, 55);
    expect(find.text('AC-055'), findsWidgets);
  });

  testWidgets('visitor create shows qr retry when qr endpoint fails', (
    tester,
  ) async {
    final api = FakeApiService(
      visitorQrError: const ApiServiceException(
        'QR visitor belum bisa dimuat. Coba lagi.',
      ),
    );
    await _pumpAccessPage(tester, apiService: api);

    await tester.ensureVisible(find.text('Register Visitor').last);
    await tester.tap(find.text('Register Visitor').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('visitor-name-field')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('visitor-phone-field')),
      '+62 812-3456-7890',
    );
    await tester.tap(find.text('Visit Family'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('visitor-visit-date-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14:00'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(api.createVisitorCalls, 1);
    expect(api.getVisitorQrCalls, 1);
    expect(
      find.text('QR visitor belum bisa dimuat. Coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('visitor create failure shows friendly snackbar', (tester) async {
    await _pumpAccessPage(
      tester,
      apiService: FakeApiService(
        createVisitorError: const ApiServiceException(
          'Registrasi visitor belum bisa dibuat. Coba lagi.',
        ),
      ),
    );

    await tester.ensureVisible(find.text('Register Visitor').last);
    await tester.tap(find.text('Register Visitor').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('visitor-name-field')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('visitor-phone-field')),
      '+62 812-3456-7890',
    );
    await tester.tap(find.text('Visit Family'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('visitor-visit-date-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14:00'));
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(
      find.text('Registrasi visitor belum bisa dibuat. Coba lagi.'),
      findsOneWidget,
    );
  });

  testWidgets('services hub shows request and history only', (tester) async {
    await _pumpServicesPage(tester, apiService: FakeApiService());

    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Service Request'), findsOneWidget);
    expect(find.text('Buat Service\nRequest'), findsOneWidget);
    expect(find.text('Riwayat\nLaporan'), findsOneWidget);
    expect(find.text('Facility Booking'), findsNothing);
    expect(find.text('New facility booking'), findsNothing);
  });

  testWidgets('services hub opens request flow and history', (tester) async {
    await _pumpServicesPage(
      tester,
      apiService: FakeApiService(
        serviceCatalog: _serviceCatalog(),
        serviceTickets: _serviceTickets(),
      ),
    );

    await tester.tap(find.text('Buat Laporan'));
    await tester.pumpAndSettle();

    expect(find.text('What type of service do you need?'), findsOneWidget);
    expect(find.text('Plumbing'), findsAtLeastNWidgets(1));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Lihat Riwayat'));
    await tester.tap(find.text('Lihat Riwayat'));
    await tester.pumpAndSettle();

    expect(
      find.text('Review every service request and its progress.'),
      findsOneWidget,
    );
    expect(find.textContaining('SR-2401'), findsOneWidget);
  });

  testWidgets(
    'service request flow submits real-style ticket and opens history',
    (tester) async {
      final api = FakeApiService(
        serviceCatalog: _serviceCatalog(),
        serviceTickets: _serviceTickets(),
        createdServiceTicket: _createdServiceTicket(),
      );

      await _pumpServicesPage(tester, apiService: api);

      await tester.tap(find.text('Buat Laporan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plumbing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kitchen Fixture'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Continue to Description'),
        find.byKey(const ValueKey('service-request-page')),
        const Offset(0, -220),
      );
      final continueButton = tester.widget<LuxuryButton>(
        find.byKey(const ValueKey('continue-to-description-button')),
      );
      continueButton.onPressed.call();
      await tester.pumpAndSettle();

      expect(find.text('Describe Issue'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('service-title-field')),
        'Leaky faucet',
      );
      await tester.enterText(
        find.byKey(const ValueKey('service-description-field')),
        'Water dripping under the sink.',
      );
      await tester.drag(
        find.byKey(const ValueKey('service-request-page')),
        const Offset(0, -520),
      );
      await tester.pumpAndSettle();
      final submitButton = tester.widget<LuxuryButton>(
        find.byKey(const ValueKey('submit-service-request-button')),
      );
      submitButton.onPressed.call();
      await tester.pumpAndSettle();

      expect(find.text('Tiket Berhasil Dibuat!'), findsOneWidget);
      expect(find.text('SR-2450'), findsOneWidget);

      await tester.tap(find.text('View History'));
      await tester.pumpAndSettle();

      expect(find.text('Service History'), findsOneWidget);
      expect(find.textContaining('Kitchen faucet leakage'), findsOneWidget);
      expect(api.createServiceCalls, 1);
    },
  );

  testWidgets('describe issue renders schedule and attachment inputs', (
    tester,
  ) async {
    await _pumpServiceRequestPage(
      tester,
      apiService: FakeApiService(serviceCatalog: _serviceCatalog()),
    );

    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen Fixture'));
    await tester.pumpAndSettle();
    final continueButton = tester.widget<LuxuryButton>(
      find.byKey(const ValueKey('continue-to-description-button')),
    );
    continueButton.onPressed.call();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('automatic-schedule-info')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('preferred-schedule-field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('attachment-add-button')), findsOneWidget);
  });

  testWidgets(
    'service request submit passes preferred schedule and attachments',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeApiService(
        serviceCatalog: _serviceCatalog(),
        createdServiceTicket: _createdServiceTicket(),
      );

      await _pumpServiceRequestPage(
        tester,
        apiService: api,
        attachmentPicker: (_) async => 'C:/temp/service-photo.jpg',
      );

      await tester.tap(find.text('Plumbing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kitchen Fixture'));
      await tester.pumpAndSettle();
      final continueButton = tester.widget<LuxuryButton>(
        find.byKey(const ValueKey('continue-to-description-button')),
      );
      continueButton.onPressed.call();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('service-title-field')),
        'AC bocor',
      );
      await tester.enterText(
        find.byKey(const ValueKey('service-description-field')),
        'Air menetes dari unit indoor.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('preferred-schedule-field')),
        'Morning after 09:00',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('attachment-add-button')),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-add-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          ValueKey(
            Platform.isWindows
                ? 'attachment-source-file'
                : 'attachment-source-gallery',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('attachment-remove-0')), findsOneWidget);

      final submitButton = tester.widget<LuxuryButton>(
        find.byKey(const ValueKey('submit-service-request-button')),
      );
      submitButton.onPressed.call();
      await tester.pumpAndSettle();

      expect(api.lastCreatePreferredSchedule, 'Morning after 09:00');
      expect(api.lastCreateAttachmentPaths, ['C:/temp/service-photo.jpg']);
      expect(find.text('Tiket Berhasil Dibuat!'), findsOneWidget);
    },
  );

  testWidgets('attachment section supports remove interaction', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpServiceRequestPage(
      tester,
      apiService: FakeApiService(serviceCatalog: _serviceCatalog()),
      attachmentPicker: (_) async => 'C:/temp/remove-photo.jpg',
    );

    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen Fixture'));
    await tester.pumpAndSettle();
    final continueButton = tester.widget<LuxuryButton>(
      find.byKey(const ValueKey('continue-to-description-button')),
    );
    continueButton.onPressed.call();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('attachment-add-button')),
    );
    await tester.tap(find.byKey(const ValueKey('attachment-add-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey(
          Platform.isWindows
              ? 'attachment-source-file'
              : 'attachment-source-camera',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('attachment-remove-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('attachment-remove-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('attachment-remove-0')), findsNothing);
    expect(find.byKey(const ValueKey('attachment-add-button')), findsOneWidget);
  });

  testWidgets('windows attachment chooser uses file picker action', (
    tester,
  ) async {
    if (!Platform.isWindows) {
      return;
    }

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpServiceRequestPage(
      tester,
      apiService: FakeApiService(serviceCatalog: _serviceCatalog()),
      attachmentPicker: (_) async => null,
    );

    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen Fixture'));
    await tester.pumpAndSettle();
    final continueButton = tester.widget<LuxuryButton>(
      find.byKey(const ValueKey('continue-to-description-button')),
    );
    continueButton.onPressed.call();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('attachment-add-button')),
    );
    await tester.tap(find.byKey(const ValueKey('attachment-add-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('attachment-source-file')),
      findsOneWidget,
    );
    expect(find.text('Pilih Foto'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('attachment-source-camera')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attachment-source-gallery')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('attachment-source-file')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('attachment-remove-0')), findsNothing);
  });

  testWidgets('tracking detail shows operational time', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeApiService(
      serviceCatalog: _serviceCatalog(),
      createdServiceTicket: _createdServiceTicket(),
      serviceDetail: _serviceDetailTicket(),
    );

    await _pumpServicesPage(tester, apiService: api);

    await tester.tap(find.text('Buat Laporan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen Fixture'));
    await tester.pumpAndSettle();
    final continueButton = tester.widget<LuxuryButton>(
      find.byKey(const ValueKey('continue-to-description-button')),
    );
    continueButton.onPressed.call();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('service-title-field')),
      'Leaky faucet',
    );
    await tester.enterText(
      find.byKey(const ValueKey('service-description-field')),
      'Water dripping under the sink.',
    );
    final submitButton = tester.widget<LuxuryButton>(
      find.byKey(const ValueKey('submit-service-request-button')),
    );
    submitButton.onPressed.call();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('View Detail'));
    await tester.tap(find.text('View Detail'));
    await tester.pumpAndSettle();

    expect(find.text('Operational Time'), findsOneWidget);
    expect(find.text('24 Jun 2026, 08:45'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('service-attachment-image-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('service-attachment-file-2')),
      findsOneWidget,
    );
  });

  testWidgets('service attachment url resolver repairs localhost urls', (
    tester,
  ) async {
    final origin = _apiOrigin();

    expect(
      resolveServiceAttachmentUrl(
        'http://localhost/storage/service-requests/attachments/photo.jpg',
      ),
      '$origin/storage/service-requests/attachments/photo.jpg',
    );
    expect(
      resolveServiceAttachmentUrl('/storage/service-requests/photo.jpg'),
      '$origin/storage/service-requests/photo.jpg',
    );
    expect(
      resolveServiceAttachmentUrl('https://cdn.example.com/photo.jpg'),
      'https://cdn.example.com/photo.jpg',
    );
  });

  testWidgets('service history opens detail sheet from real-style ticket', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeApiService(
      serviceCatalog: _serviceCatalog(),
      serviceTickets: _serviceTickets(),
      serviceDetail: _serviceDetailTicket(),
    );
    await _pumpServicesPage(tester, apiService: api);

    await tester.ensureVisible(find.text('Lihat Riwayat'));
    await tester.tap(find.text('Lihat Riwayat'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('SR-2401'));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen sink leakage'), findsOneWidget);
    expect(api.lastDetailTicketId, 2401);
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('24 Jun 2026, 08:45'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('service-attachment-image-1')),
      findsOneWidget,
    );
    expect(find.text('inspection-photo.jpg'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('service-attachment-file-2')),
      findsOneWidget,
    );
    expect(find.text('Operational Time'), findsOneWidget);
  });

  testWidgets('service history detail follows sparse detail-by-id response', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeApiService(
      serviceCatalog: _serviceCatalog(),
      serviceTickets: _richServiceTickets(),
      serviceDetail: _sparseServiceDetailTicket(),
    );

    await _pumpServicesPage(tester, apiService: api);

    await tester.ensureVisible(find.text('Lihat Riwayat'));
    await tester.tap(find.text('Lihat Riwayat'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('SR-2026-012'));
    await tester.pumpAndSettle();

    expect(api.lastDetailTicketId, 12);
    expect(find.text('hajavaj'), findsOneWidget);
    expect(find.text('Within SLA'), findsOneWidget);
    expect(find.text('23 Jun 2026, 21:03'), findsAtLeastNWidgets(1));
    expect(find.text('No attachments available.'), findsOneWidget);
    expect(find.text('rich-list-photo.jpg'), findsNothing);
    expect(
      find.byKey(const ValueKey('service-attachment-image-12')),
      findsNothing,
    );
  });

  testWidgets('service attachment preview fallback handles empty url safely', (
    tester,
  ) async {
    await _pumpServicesPage(
      tester,
      apiService: FakeApiService(
        serviceCatalog: _serviceCatalog(),
        serviceTickets: _serviceTickets(),
        serviceDetail: _serviceDetailTicketWithBrokenImage(),
      ),
    );

    await tester.tap(find.text('Lihat Riwayat'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('SR-2401'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('service-attachment-image-3')),
    );
    await tester.tap(find.byKey(const ValueKey('service-attachment-image-3')));
    await tester.pumpAndSettle();

    expect(find.text('Preview is unavailable for this image.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service request api failure shows user-friendly error', (
    tester,
  ) async {
    await _pumpServicesPage(
      tester,
      apiService: FakeApiService(
        serviceCatalogError: const ApiServiceException(
          'Data layanan belum bisa dimuat. Coba lagi.',
        ),
      ),
    );

    await tester.tap(find.text('Buat Laporan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Data layanan belum bisa dimuat. Coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('community page renders announcements directly', (tester) async {
    await _pumpCommunityPage(
      tester,
      apiService: FakeApiService(
        residentAnnouncements: _communityAnnouncements(),
      ),
    );

    expect(find.text('Announcement Center'), findsOneWidget);
    expect(find.text('Resident feedback'), findsNothing);
    expect(find.text('Water meter inspection this Friday'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Weekend acoustic evening confirmed'),
      find.byKey(const ValueKey('community-page')),
      const Offset(0, -220),
    );
    expect(find.text('Weekend acoustic evening confirmed'), findsOneWidget);
  });

  testWidgets('community filters and opens announcement detail', (
    tester,
  ) async {
    await _pumpCommunityPage(
      tester,
      apiService: FakeApiService(
        residentAnnouncements: _communityAnnouncements(),
        announcementDetail: _communityAnnouncementDetail(),
      ),
    );

    expect(find.widgetWithText(ActionChip, 'Pinned'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Pinned'));
    await tester.pumpAndSettle();

    expect(find.text('Water meter inspection this Friday'), findsOneWidget);
    expect(find.text('Sky garden deep cleaning schedule'), findsNothing);
    expect(find.text('Weekend acoustic evening confirmed'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, 'Maintenance'));
    await tester.pumpAndSettle();

    expect(find.text('Water meter inspection this Friday'), findsOneWidget);
    expect(find.text('Sky garden deep cleaning schedule'), findsOneWidget);
    expect(find.text('Weekend acoustic evening confirmed'), findsNothing);

    await tester.tap(find.text('Water meter inspection this Friday'));
    await tester.pump();

    expect(find.text('Loading latest details...'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Management Office'), findsOneWidget);
    expect(find.text('Affected area'), findsOneWidget);
    expect(
      find.textContaining('routine water meter inspection in Tower A'),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Announcement Center'), findsOneWidget);
  });

  testWidgets('community page shows loading then renders api announcements', (
    tester,
  ) async {
    final completer = Completer<List<CommunityAnnouncement>>();
    final api = FakeApiService(announcementListCompleter: completer);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(body: CommunityPage(apiService: api)),
      ),
    );
    await tester.pump();

    expect(find.text('Loading announcements...'), findsOneWidget);

    completer.complete(_communityAnnouncements());
    await tester.pumpAndSettle();

    expect(find.text('Water meter inspection this Friday'), findsOneWidget);
    expect(api.getAnnouncementsCalls, 1);
  });

  testWidgets('community page shows retry on api failure', (tester) async {
    await _pumpCommunityPage(
      tester,
      apiService: FakeApiService(
        residentAnnouncementsError: const ApiServiceException(
          'Pengumuman belum bisa dimuat. Coba lagi.',
        ),
      ),
    );

    expect(
      find.text('Pengumuman belum bisa dimuat. Coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('community page shows empty state when api returns no items', (
    tester,
  ) async {
    await _pumpCommunityPage(
      tester,
      apiService: FakeApiService(residentAnnouncements: const []),
    );

    expect(find.text('No announcements available yet.'), findsOneWidget);
  });

  testWidgets('community detail failure shows friendly snackbar', (
    tester,
  ) async {
    await _pumpCommunityPage(
      tester,
      apiService: FakeApiService(
        residentAnnouncements: _communityAnnouncements(),
        announcementDetailError: const ApiServiceException(
          'Detail pengumuman belum bisa dimuat. Coba lagi.',
        ),
      ),
    );

    await tester.tap(find.text('Water meter inspection this Friday'));
    await tester.pumpAndSettle();

    expect(
      find.text('Detail pengumuman belum bisa dimuat. Coba lagi.'),
      findsOneWidget,
    );
  });

  testWidgets('logout from profile returns to login', (tester) async {
    final storage = FakeAuthStorageService(token: 'resident-token');
    final api = FakeApiService(
      storage: storage,
      meResult: _residentUser(token: 'resident-token'),
      onLogout: () async {
        await storage.clearSession();
      },
    );

    await tester.pumpWidget(
      ApartHubResidenceApp(apiService: api, authStorageService: storage),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('logout-button')),
      find.byKey(const ValueKey('profile-page')),
      const Offset(0, -220),
    );
    final logoutButton = tester.widget<LuxuryButton>(
      find.byKey(const ValueKey('logout-button')),
    );
    logoutButton.onPressed.call();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(storage.clearSessionCalls, 1);
  });

  testWidgets(
    'resident shell hydrates home and profile from resident session',
    (tester) async {
      final storage = FakeAuthStorageService(
        token: 'resident-token',
        residentJson: jsonEncode(
          _residentUser(token: 'resident-token').toJson(),
        ),
      );
      final api = FakeApiService(
        storage: storage,
        meResult: _residentUser(token: 'resident-token'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightLuxuryTheme,
          home: ResidentShell(apiService: api),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Evening, Nadia Resident'), findsOneWidget);
      expect(find.text('Tower Asteria'), findsOneWidget);
      expect(find.text('Unit A-1808'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('nadia@example.com'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('Tower Asteria - Unit A-1808'), findsOneWidget);
      expect(find.text('31 Des 2027'), findsOneWidget);
      expect(api.meCalls, greaterThanOrEqualTo(1));
    },
  );

  testWidgets(
    'profile uses neutral placeholders when resident fields are empty',
    (tester) async {
      const resident = ResidentUser(
        id: 0,
        name: '',
        residentType: '',
        email: '',
        mobileNo: '',
        contractEndDate: '',
        unit: ResidentUnit(id: 0, code: '', tower: '', floor: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightLuxuryTheme,
          home: Scaffold(
            body: ProfilePage(apiService: FakeApiService(), resident: resident),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resident Profile'), findsOneWidget);
      expect(find.text('Resident Account'), findsOneWidget);
      expect(find.text('Assigned after activation'), findsOneWidget);
      expect(find.text('Information unavailable'), findsOneWidget);
      expect(find.text('Not provided'), findsAtLeastNWidgets(2));
    },
  );
}

Future<void> _pumpAccessPage(
  WidgetTester tester, {
  ApiService? apiService,
  Locale locale = const Locale('en'),
}) async {
  await initializeDateFormatting('id_ID');
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _localizedMaterialApp(
      home: Scaffold(
        body: AccessPage(apiService: apiService ?? FakeApiService()),
      ),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpServicesPage(
  WidgetTester tester, {
  ApiService? apiService,
}) async {
  await tester.pumpWidget(
    _localizedMaterialApp(
      home: Scaffold(body: ServicesPage(apiService: apiService)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpServiceRequestPage(
  WidgetTester tester, {
  required ApiService apiService,
  Future<String?> Function(ImageSource source)? attachmentPicker,
}) async {
  await tester.pumpWidget(
    _localizedMaterialApp(
      home: Scaffold(
        body: ServiceRequestPage(
          onBack: () {},
          initialMode: ServiceRequestInitialMode.create,
          apiService: apiService,
          attachmentPicker: attachmentPicker,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpCommunityPage(
  WidgetTester tester, {
  ApiService? apiService,
}) async {
  await tester.pumpWidget(
    _localizedMaterialApp(
      home: Scaffold(body: CommunityPage(apiService: apiService)),
    ),
  );
  await tester.pumpAndSettle();
}

MaterialApp _localizedMaterialApp({
  required Widget home,
  Locale locale = const Locale('id'),
}) {
  return MaterialApp(
    theme: AppTheme.lightLuxuryTheme,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

String _apiOrigin() {
  final base = Uri.parse(ApiClient.baseUrl);
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
  ).toString();
}

ResidentUser _residentUser({String? token}) {
  return ResidentUser(
    id: 12,
    name: 'Nadia Resident',
    residentType: 'Owner',
    email: 'nadia@example.com',
    mobileNo: '081234567890',
    contractEndDate: '2027-12-31',
    unit: const ResidentUnit(
      id: 18,
      code: 'A-1808',
      tower: 'Asteria',
      floor: 18,
    ),
    token: token,
  );
}

class FakeAuthStorageService implements AuthStorageService {
  FakeAuthStorageService({this.token, this.residentJson});

  String? token;
  String? residentJson;
  int clearSessionCalls = 0;

  @override
  Future<void> clearSession() async {
    clearSessionCalls += 1;
    token = null;
    residentJson = null;
  }

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  Future<String?> getResidentJson() async {
    return residentJson;
  }

  @override
  Future<String?> getToken() async {
    return token;
  }

  @override
  Future<void> saveResidentJson(String json) async {
    residentJson = json;
  }

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }
}

class FakeApiService implements ApiService {
  FakeApiService({
    this.storage,
    this.loginResult,
    this.loginError,
    this.meResult,
    this.meError,
    this.loginCompleter,
    this.onLogout,
    this.serviceCatalog,
    this.serviceCatalogError,
    this.serviceTickets,
    this.serviceTicketsError,
    this.createdServiceTicket,
    this.createServiceError,
    this.serviceDetail,
    this.serviceDetailError,
    this.residentAnnouncements,
    this.residentAnnouncementsError,
    this.announcementDetail,
    this.announcementDetailError,
    this.announcementListCompleter,
    this.announcementDetailCompleter,
    this.visitors,
    this.visitorsError,
    this.visitorDetail,
    this.visitorDetailError,
    this.createdVisitor,
    this.createVisitorError,
    this.visitorQrPass,
    this.visitorQrError,
  });

  final FakeAuthStorageService? storage;
  final ResidentUser? loginResult;
  final Object? loginError;
  final ResidentUser? meResult;
  final Object? meError;
  final Completer<ResidentUser>? loginCompleter;
  final Future<void> Function()? onLogout;
  final ServiceRequestCatalog? serviceCatalog;
  final Object? serviceCatalogError;
  final List<ServiceTicketRecord>? serviceTickets;
  final Object? serviceTicketsError;
  final ServiceTicketRecord? createdServiceTicket;
  final Object? createServiceError;
  final ServiceTicketRecord? serviceDetail;
  final Object? serviceDetailError;
  final List<CommunityAnnouncement>? residentAnnouncements;
  final Object? residentAnnouncementsError;
  final CommunityAnnouncement? announcementDetail;
  final Object? announcementDetailError;
  final Completer<List<CommunityAnnouncement>>? announcementListCompleter;
  final Completer<CommunityAnnouncement>? announcementDetailCompleter;
  final List<VisitorAccessRecord>? visitors;
  final Object? visitorsError;
  final VisitorAccessRecord? visitorDetail;
  final Object? visitorDetailError;
  final VisitorAccessRecord? createdVisitor;
  final Object? createVisitorError;
  final VisitorQrPass? visitorQrPass;
  final Object? visitorQrError;

  int loginCalls = 0;
  int meCalls = 0;
  int logoutCalls = 0;
  int createServiceCalls = 0;
  int getCatalogCalls = 0;
  int getHistoryCalls = 0;
  int getDetailCalls = 0;
  int getAnnouncementsCalls = 0;
  int getAnnouncementDetailCalls = 0;
  int getVisitorsCalls = 0;
  int getVisitorDetailCalls = 0;
  int createVisitorCalls = 0;
  int getVisitorQrCalls = 0;
  int? lastVisitorDetailId;
  int? lastVisitorQrId;
  String? lastVisitorStatus;
  String? lastCreateVisitorName;
  String? lastCreateVisitorPhone;
  String? lastCreateVisitDate;
  String? lastCreateEstimatedArrivalTime;
  int? lastCreateGuestCount;
  String? lastCreateVisitPurpose;
  int? lastDetailTicketId;
  int? lastCreateCategoryId;
  int? lastCreateSubcategoryId;
  String? lastCreateTitle;
  String? lastCreateDescription;
  String? lastCreatePriority;
  String? lastCreateRequestedDate;
  String? lastCreateRequestedTime;
  String? lastCreatePreferredSchedule;
  List<String>? lastCreateAttachmentPaths;
  List<ServiceTicketRecord>? _serviceTicketStore;

  @override
  Future<ResidentUser?> getCachedResident() async {
    final residentJson = storage?.residentJson;
    if (residentJson == null || residentJson.isEmpty) {
      return null;
    }

    return ResidentUser.fromJson(
      jsonDecode(residentJson) as Map<String, dynamic>,
    );
  }

  @override
  Future<ResidentUser> getResidentMe() async {
    meCalls += 1;
    if (meError != null) {
      throw meError!;
    }

    final resident = meResult ?? _residentUser(token: storage?.token);
    await storage?.saveResidentJson(jsonEncode(resident.toJson()));
    return resident;
  }

  @override
  Future<ResidentUser> loginResident({
    required String login,
    required String password,
  }) async {
    loginCalls += 1;
    if (loginError != null) {
      throw loginError!;
    }

    if (loginCompleter != null) {
      return loginCompleter!.future;
    }

    final resident = loginResult ?? _residentUser(token: 'resident-token');
    final token = resident.token;
    if (token != null) {
      await storage?.saveToken(token);
    }
    await storage?.saveResidentJson(jsonEncode(resident.toJson()));
    return resident;
  }

  @override
  Future<void> logoutResident() async {
    logoutCalls += 1;
    if (onLogout != null) {
      await onLogout!();
      return;
    }
    await storage?.clearSession();
  }

  @override
  Future<ServiceRequestCatalog> getServiceRequestCatalog() async {
    getCatalogCalls += 1;
    if (serviceCatalogError != null) {
      throw serviceCatalogError!;
    }
    return serviceCatalog ?? _serviceCatalog();
  }

  @override
  Future<List<ServiceTicketRecord>> getServiceRequests() async {
    getHistoryCalls += 1;
    if (serviceTicketsError != null) {
      throw serviceTicketsError!;
    }
    return List<ServiceTicketRecord>.of(
      _serviceTicketStore ?? serviceTickets ?? _serviceTickets(),
    );
  }

  @override
  Future<ServiceTicketRecord> createServiceRequest({
    required int categoryId,
    required int subcategoryId,
    required String title,
    required String description,
    required String priority,
    int? residentId,
    String? requestedDate,
    String? requestedTime,
    String? preferredSchedule,
    List<String>? attachmentPaths,
  }) async {
    createServiceCalls += 1;
    lastCreateCategoryId = categoryId;
    lastCreateSubcategoryId = subcategoryId;
    lastCreateTitle = title;
    lastCreateDescription = description;
    lastCreatePriority = priority;
    lastCreateRequestedDate = requestedDate;
    lastCreateRequestedTime = requestedTime;
    lastCreatePreferredSchedule = preferredSchedule;
    lastCreateAttachmentPaths = attachmentPaths == null
        ? const []
        : List<String>.of(attachmentPaths);
    if (createServiceError != null) {
      throw createServiceError!;
    }
    final created = createdServiceTicket ?? _createdServiceTicket();
    _serviceTicketStore = [
      created,
      ...(_serviceTicketStore ?? serviceTickets ?? _serviceTickets()),
    ];
    return created;
  }

  @override
  Future<ServiceTicketRecord> getServiceRequestDetail(int ticketId) async {
    getDetailCalls += 1;
    lastDetailTicketId = ticketId;
    if (serviceDetailError != null) {
      throw serviceDetailError!;
    }
    return serviceDetail ?? _serviceDetailTicket();
  }

  @override
  Future<List<CommunityAnnouncement>> getResidentAnnouncements() async {
    getAnnouncementsCalls += 1;
    if (residentAnnouncementsError != null) {
      throw residentAnnouncementsError!;
    }
    if (announcementListCompleter != null) {
      return announcementListCompleter!.future;
    }
    return List<CommunityAnnouncement>.of(
      residentAnnouncements ?? _communityAnnouncements(),
    );
  }

  @override
  Future<CommunityAnnouncement> getResidentAnnouncementDetail(
    String announcementId,
  ) async {
    getAnnouncementDetailCalls += 1;
    if (announcementDetailError != null) {
      throw announcementDetailError!;
    }
    if (announcementDetailCompleter != null) {
      return announcementDetailCompleter!.future;
    }
    return announcementDetail ?? _communityAnnouncementDetail();
  }

  @override
  Future<List<VisitorAccessRecord>> getResidentVisitors({
    String? status,
  }) async {
    getVisitorsCalls += 1;
    lastVisitorStatus = status;
    if (visitorsError != null) {
      throw visitorsError!;
    }
    return List<VisitorAccessRecord>.of(visitors ?? _visitorRecords());
  }

  @override
  Future<VisitorAccessRecord> getResidentVisitorDetail(int visitorId) async {
    getVisitorDetailCalls += 1;
    lastVisitorDetailId = visitorId;
    if (visitorDetailError != null) {
      throw visitorDetailError!;
    }
    return visitorDetail ?? _visitorDetailRecord();
  }

  @override
  Future<VisitorAccessRecord> createResidentVisitor({
    required String visitorName,
    required String visitorPhone,
    required String visitDate,
    required String estimatedArrivalTime,
    required int guestCount,
    required String visitPurpose,
  }) async {
    createVisitorCalls += 1;
    lastCreateVisitorName = visitorName;
    lastCreateVisitorPhone = visitorPhone;
    lastCreateVisitDate = visitDate;
    lastCreateEstimatedArrivalTime = estimatedArrivalTime;
    lastCreateGuestCount = guestCount;
    lastCreateVisitPurpose = visitPurpose;
    if (createVisitorError != null) {
      throw createVisitorError!;
    }
    return createdVisitor ?? _createdVisitorRecord();
  }

  @override
  Future<VisitorQrPass> getResidentVisitorQr(int visitorId) async {
    getVisitorQrCalls += 1;
    lastVisitorQrId = visitorId;
    if (visitorQrError != null) {
      throw visitorQrError!;
    }
    return visitorQrPass ?? _visitorQrPass(visitorId: visitorId);
  }
}

List<VisitorAccessRecord> _visitorRecords() {
  return const [
    VisitorAccessRecord(
      id: 41,
      visitorName: 'Raka Pratama',
      visitorPhone: '+62 812-0000-0001',
      visitDate: '2026-06-25',
      estimatedArrivalTime: '14:00',
      guestCount: 2,
      visitPurpose: 'Family Visit',
      status: 'Approved',
      registrationSource: 'Resident App',
      qrAvailable: true,
      approvedAt: '2026-06-24T10:00:00+07:00',
      rejectedAt: '',
      cancelledAt: '',
      checkedInAt: '',
      checkedOutAt: '',
      expiresAt: '2026-06-25T18:00:00+07:00',
      accessCardNumber: 'AC-001',
      identityPhotoUrl: '',
      unit: VisitorUnit(id: 1, code: 'A-1808', tower: 'Tower A', floor: 18),
      timeline: [],
      cancellationReason: '',
      rejectionReason: '',
    ),
    VisitorAccessRecord(
      id: 42,
      visitorName: 'Maya Santoso',
      visitorPhone: '+62 812-0000-0002',
      visitDate: '2026-06-24',
      estimatedArrivalTime: '10:30',
      guestCount: 1,
      visitPurpose: 'Delivery',
      status: 'Checked In',
      registrationSource: 'Resident App',
      qrAvailable: true,
      approvedAt: '2026-06-24T08:00:00+07:00',
      rejectedAt: '',
      cancelledAt: '',
      checkedInAt: '2026-06-24T10:31:00+07:00',
      checkedOutAt: '',
      expiresAt: '2026-06-24T16:00:00+07:00',
      accessCardNumber: 'AC-002',
      identityPhotoUrl: '',
      unit: VisitorUnit(id: 1, code: 'A-1808', tower: 'Tower A', floor: 18),
      timeline: [],
      cancellationReason: '',
      rejectionReason: '',
    ),
  ];
}

VisitorAccessRecord _visitorDetailRecord({
  bool qrAvailable = true,
  String status = 'Approved',
}) {
  return VisitorAccessRecord(
    id: 41,
    visitorName: 'Raka Pratama',
    visitorPhone: '+62 812-0000-0001',
    visitDate: '2026-06-25',
    estimatedArrivalTime: '14:00',
    guestCount: 2,
    visitPurpose: 'Family Visit',
    status: status,
    registrationSource: 'Resident App',
    qrAvailable: qrAvailable,
    approvedAt: '2026-06-24T10:00:00+07:00',
    rejectedAt: '',
    cancelledAt: '',
    checkedInAt: '',
    checkedOutAt: '',
    expiresAt: '2026-06-25T18:00:00+07:00',
    accessCardNumber: 'AC-001',
    identityPhotoUrl: '',
    unit: const VisitorUnit(id: 1, code: 'A-1808', tower: 'Tower A', floor: 18),
    timeline: const [
      {'label': 'Approved', 'timestamp': '2026-06-24T10:00:00+07:00'},
    ],
    cancellationReason: '',
    rejectionReason: '',
  );
}

VisitorAccessRecord _createdVisitorRecord({
  bool qrAvailable = true,
  String? status,
}) {
  final resolvedStatus = status ?? (qrAvailable ? 'Approved' : 'Pending');
  return VisitorAccessRecord(
    id: 55,
    visitorName: 'Alex Morgan',
    visitorPhone: '+62 812-3456-7890',
    visitDate: '2026-06-08',
    estimatedArrivalTime: '14:00',
    guestCount: 2,
    visitPurpose: 'Visit Family',
    status: resolvedStatus,
    registrationSource: 'Resident App',
    qrAvailable: qrAvailable,
    approvedAt: qrAvailable ? '2026-06-08T09:00:00+07:00' : '',
    rejectedAt: '',
    cancelledAt: '',
    checkedInAt: '',
    checkedOutAt: '',
    expiresAt: qrAvailable ? '2026-06-08T16:00:00+07:00' : '',
    accessCardNumber: qrAvailable ? 'AC-055' : '',
    identityPhotoUrl: '',
    unit: const VisitorUnit(id: 1, code: 'A-1808', tower: 'Tower A', floor: 18),
    timeline: const [],
    cancellationReason: '',
    rejectionReason: '',
  );
}

VisitorQrPass _visitorQrPass({int visitorId = 55}) {
  return VisitorQrPass(
    visitorId: visitorId,
    qrPayload: 'VISITOR-QR-PAYLOAD-$visitorId',
    accessCode: visitorId == 55 ? 'AC-055' : 'AC-$visitorId',
    validUntil: '2026-06-08T16:00:00+07:00',
    status: 'Approved',
  );
}

List<CommunityAnnouncement> _communityAnnouncements() {
  return const [
    CommunityAnnouncement(
      id: 'ann-1',
      title: 'Water meter inspection this Friday',
      content:
          'Routine water meter inspection will be performed for Tower A units this Friday from 10:00 until 14:00.',
      category: 'Maintenance',
      isPinned: true,
      publishedAt: '2026-06-23T09:00:00.000Z',
    ),
    CommunityAnnouncement(
      id: 'ann-2',
      title: 'Sky garden deep cleaning schedule',
      content:
          'The sky garden will be unavailable during the morning deep cleaning session and landscape refresh.',
      category: 'Maintenance',
      isPinned: false,
      publishedAt: '2026-06-19T07:00:00.000Z',
    ),
    CommunityAnnouncement(
      id: 'ann-3',
      title: 'Weekend acoustic evening confirmed',
      content:
          'Resident acoustic evening at the rooftop lounge starts at 19:30 this Saturday with limited seating.',
      category: 'General',
      isPinned: false,
      publishedAt: '2026-06-18T19:30:00.000Z',
    ),
  ];
}

List<CommunityAnnouncement> _homeHighlightAnnouncements() {
  return const [
    CommunityAnnouncement(
      id: 'ann-pinned',
      title: 'Water meter inspection this Friday',
      content:
          'Routine water meter inspection will be performed for Tower A units this Friday from 10:00 until 14:00.',
      category: 'Maintenance',
      isPinned: true,
      publishedAt: '2026-06-20T09:00:00.000Z',
    ),
    CommunityAnnouncement(
      id: 'ann-newest',
      title: 'Weekend acoustic evening confirmed',
      content:
          'Resident acoustic evening at the rooftop lounge starts at 19:30 this Saturday with limited seating.',
      category: 'General',
      isPinned: false,
      publishedAt: '2026-06-23T19:30:00.000Z',
    ),
    CommunityAnnouncement(
      id: 'ann-package',
      title: 'Lobby parcel counter service update',
      content:
          'Parcel collection hours are now extended until 22:00 every day for better resident convenience.',
      category: 'General',
      isPinned: false,
      publishedAt: '2026-06-22T08:15:00.000Z',
    ),
    CommunityAnnouncement(
      id: 'ann-old',
      title: 'Sky garden deep cleaning schedule',
      content:
          'The sky garden will be unavailable during the morning deep cleaning session and landscape refresh.',
      category: 'Maintenance',
      isPinned: false,
      publishedAt: '2026-06-19T07:00:00.000Z',
    ),
  ];
}

CommunityAnnouncement _communityAnnouncementDetail() {
  return const CommunityAnnouncement(
    id: 'ann-1',
    title: 'Water meter inspection this Friday',
    content:
        'Our engineering team will perform a routine water meter inspection in Tower A on Friday from 10:00 to 14:00. Please ensure maintenance staff can access the meter area if required.',
    category: 'Maintenance',
    isPinned: true,
    publishedAt: '2026-06-23T09:00:00.000Z',
  );
}

ServiceRequestCatalog _serviceCatalog() {
  return const ServiceRequestCatalog(
    residentId: 12,
    categories: [
      ServiceCategory(
        id: 1,
        name: 'Plumbing',
        subcategories: [
          ServiceSubcategory(
            id: 11,
            name: 'Kitchen Fixture',
            sla: ServiceSla(low: 180, medium: 120, high: 60, emergency: 30),
          ),
          ServiceSubcategory(
            id: 12,
            name: 'Bathroom Pipe',
            sla: ServiceSla(low: 240, medium: 150, high: 90, emergency: 45),
          ),
        ],
      ),
      ServiceCategory(
        id: 2,
        name: 'Electrical',
        subcategories: [
          ServiceSubcategory(
            id: 21,
            name: 'Lighting Issue',
            sla: ServiceSla(low: 240, medium: 120, high: 75, emergency: 40),
          ),
        ],
      ),
    ],
  );
}

List<ServiceTicketRecord> _serviceTickets() {
  return [
    ServiceTicketRecord(
      id: 2401,
      ticketNumber: 'SR-2401',
      title: 'Kitchen sink leakage',
      description: 'Water keeps dripping under the kitchen sink.',
      priority: 'Medium',
      status: 'Submitted',
      rawStatus: 'submitted',
      source: 'mobile',
      slaTargetMinutes: 120,
      slaDueAt: '2026-06-24T10:30:00.000Z',
      slaState: 'On SLA',
      assignedTo: 'Waiting assignment',
      operationalTimestamp: '2026-06-24T08:30:00.000Z',
      createdAt: '2026-06-24T08:30:00.000Z',
      category: const ServiceSimpleRef(
        id: 1,
        name: 'Plumbing',
        code: '',
        tower: '',
        floor: 0,
      ),
      subcategory: const ServiceSimpleRef(
        id: 11,
        name: 'Kitchen Fixture',
        code: '',
        tower: '',
        floor: 0,
      ),
      unit: const ServiceSimpleRef(
        id: 18,
        name: '',
        code: 'A-1808',
        tower: 'Asteria',
        floor: 18,
      ),
      attachments: const [],
      timeline: const [],
      completedAt: '',
    ),
  ];
}

List<ServiceTicketRecord> _richServiceTickets() {
  return [
    ServiceTicketRecord(
      id: 12,
      ticketNumber: 'SR-2026-012',
      title: 'hajavaj',
      description: 'jejaoavsksm',
      priority: 'Medium',
      status: 'Submitted',
      rawStatus: 'Submitted',
      source: 'Resident App',
      slaTargetMinutes: 240,
      slaDueAt: '2026-06-24T01:03:58+07:00',
      slaState: 'Over SLA',
      assignedTo: '',
      operationalTimestamp: '2026-06-23T21:03:58+07:00',
      createdAt: '2026-06-23T21:03:58+07:00',
      category: const ServiceSimpleRef(
        id: 1,
        name: 'Plumbing',
        code: '',
        tower: '',
        floor: 0,
      ),
      subcategory: const ServiceSimpleRef(
        id: 1,
        name: 'Leak Repair',
        code: '',
        tower: '',
        floor: 0,
      ),
      unit: const ServiceSimpleRef(
        id: 1,
        name: '',
        code: 'A-1808',
        tower: 'Tower A',
        floor: 18,
      ),
      attachments: const [
        ServiceAttachment(
          id: 12,
          fileName: 'rich-list-photo.jpg',
          mimeType: 'image/jpeg',
          fileSize: 541819,
          url:
              'http://localhost/storage/service-requests/attachments/photo.jpg',
        ),
      ],
      timeline: const [],
      completedAt: '',
    ),
  ];
}

ServiceTicketRecord _createdServiceTicket() {
  return ServiceTicketRecord(
    id: 2450,
    ticketNumber: 'SR-2450',
    title: 'Kitchen faucet leakage',
    description: 'Water dripping under the sink.',
    priority: 'Medium',
    status: 'Submitted',
    rawStatus: 'submitted',
    source: 'mobile',
    slaTargetMinutes: 120,
    slaDueAt: '2026-06-24T12:00:00.000Z',
    slaState: 'On SLA',
    assignedTo: '',
    operationalTimestamp: '2026-06-24T10:00:00.000Z',
    createdAt: '2026-06-24T10:00:00.000Z',
    category: const ServiceSimpleRef(
      id: 1,
      name: 'Plumbing',
      code: '',
      tower: '',
      floor: 0,
    ),
    subcategory: const ServiceSimpleRef(
      id: 11,
      name: 'Kitchen Fixture',
      code: '',
      tower: '',
      floor: 0,
    ),
    unit: const ServiceSimpleRef(
      id: 18,
      name: '',
      code: 'A-1808',
      tower: 'Asteria',
      floor: 18,
    ),
    attachments: const [],
    timeline: const [],
    completedAt: '',
  );
}

ServiceTicketRecord _sparseServiceDetailTicket() {
  return ServiceTicketRecord(
    id: 12,
    ticketNumber: 'SR-2026-012',
    title: 'hajavaj',
    description: 'jejaoavsksm',
    priority: 'Medium',
    status: 'Submitted',
    rawStatus: 'Submitted',
    source: 'Resident App',
    slaTargetMinutes: 0,
    slaDueAt: '',
    slaState: 'Within SLA',
    assignedTo: '',
    operationalTimestamp: '2026-06-23T21:03:58+07:00',
    createdAt: '2026-06-23T21:03:58+07:00',
    category: const ServiceSimpleRef(
      id: 0,
      name: 'Plumbing',
      code: '',
      tower: '',
      floor: 0,
    ),
    subcategory: const ServiceSimpleRef(
      id: 0,
      name: '',
      code: '',
      tower: '',
      floor: 0,
    ),
    unit: const ServiceSimpleRef(
      id: 1,
      name: '',
      code: 'A-1808',
      tower: 'Tower A',
      floor: 18,
    ),
    attachments: const [],
    timeline: const [
      {'label': 'Submitted', 'timestamp': '2026-06-23T21:03:58+07:00'},
    ],
    completedAt: '',
  );
}

ServiceTicketRecord _serviceDetailTicket() {
  return ServiceTicketRecord(
    id: 2401,
    ticketNumber: 'SR-2401',
    title: 'Kitchen sink leakage',
    description: 'Water keeps dripping under the kitchen sink.',
    priority: 'Medium',
    status: 'Assigned',
    rawStatus: 'assigned',
    source: 'mobile',
    slaTargetMinutes: 120,
    slaDueAt: '2026-06-24T10:30:00+07:00',
    slaState: 'On SLA',
    assignedTo: 'Dimas Engineering',
    operationalTimestamp: '2026-06-24T08:45:00+07:00',
    createdAt: '2026-06-24T08:30:00+07:00',
    category: const ServiceSimpleRef(
      id: 1,
      name: 'Plumbing',
      code: '',
      tower: '',
      floor: 0,
    ),
    subcategory: const ServiceSimpleRef(
      id: 11,
      name: 'Kitchen Fixture',
      code: '',
      tower: '',
      floor: 0,
    ),
    unit: const ServiceSimpleRef(
      id: 18,
      name: '',
      code: 'A-1808',
      tower: 'Asteria',
      floor: 18,
    ),
    attachments: const [
      ServiceAttachment(
        id: 1,
        fileName: 'inspection-photo.jpg',
        mimeType: 'image/jpeg',
        fileSize: 102400,
        url: 'https://example.com/inspection-photo.jpg',
      ),
      ServiceAttachment(
        id: 2,
        fileName: 'inspection-report.pdf',
        mimeType: 'application/pdf',
        fileSize: 204800,
        url: 'https://example.com/inspection-report.pdf',
      ),
    ],
    timeline: const [
      {
        'status': 'Submitted',
        'description': 'Ticket created from mobile app.',
        'created_at': '2026-06-24T08:30:00+07:00',
      },
      {
        'status': 'Assigned',
        'description': 'Assigned to Dimas Engineering.',
        'created_at': '2026-06-24T08:45:00+07:00',
      },
    ],
    completedAt: '',
  );
}

ServiceTicketRecord _serviceDetailTicketWithBrokenImage() {
  return ServiceTicketRecord(
    id: 2402,
    ticketNumber: 'SR-2402',
    title: 'Ceiling leakage inspection',
    description: 'A follow-up inspection photo is missing from the backend.',
    priority: 'High',
    status: 'Assigned',
    rawStatus: 'assigned',
    source: 'mobile',
    slaTargetMinutes: 60,
    slaDueAt: '2026-06-24T13:00:00.000Z',
    slaState: 'On SLA',
    assignedTo: 'Rafa Engineering',
    operationalTimestamp: '2026-06-24T11:15:00.000Z',
    createdAt: '2026-06-24T10:45:00.000Z',
    category: const ServiceSimpleRef(
      id: 2,
      name: 'Electrical',
      code: '',
      tower: '',
      floor: 0,
    ),
    subcategory: const ServiceSimpleRef(
      id: 21,
      name: 'Lighting Issue',
      code: '',
      tower: '',
      floor: 0,
    ),
    unit: const ServiceSimpleRef(
      id: 18,
      name: '',
      code: 'A-1808',
      tower: 'Asteria',
      floor: 18,
    ),
    attachments: const [
      ServiceAttachment(
        id: 3,
        fileName: 'broken-preview.jpg',
        mimeType: 'image/jpeg',
        fileSize: 1024,
        url: '',
      ),
    ],
    timeline: const [],
    completedAt: '',
  );
}
