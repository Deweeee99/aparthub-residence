import 'package:aparthub_residance/app.dart';
import 'package:aparthub_residance/core/theme/app_theme.dart';
import 'package:aparthub_residance/features/auth/login_page.dart';
import 'package:aparthub_residance/features/resident/access/access_page.dart';
import 'package:aparthub_residance/features/resident/community/community_page.dart';
import 'package:aparthub_residance/features/resident/home/resident_home_page.dart';
import 'package:aparthub_residance/features/resident/profile/profile_page.dart';
import 'package:aparthub_residance/features/resident/resident_shell.dart';
import 'package:aparthub_residance/features/resident/services/services_page.dart';
import 'package:aparthub_residance/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('app boots into splash screen', (tester) async {
    await tester.pumpWidget(const ApartHubResidenceApp());

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
    await tester.pumpWidget(const ApartHubResidenceApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('resident tabs switch correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResidentShell()));
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
    expect(find.text('Resident feedback'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Nadia Prameswari'), findsOneWidget);
  });

  testWidgets('valid dummy login navigates to resident shell', (tester) async {
    await tester.pumpWidget(const ApartHubResidenceApp());
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
    expect(find.text('Quick Access'), findsOneWidget);
  });

  testWidgets('invalid dummy login stays on login', (tester) async {
    await tester.pumpWidget(const ApartHubResidenceApp());
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
    expect(find.text('Username atau password belum sesuai.'), findsOneWidget);
  });

  testWidgets('home header keeps billing card and removes help cta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightLuxuryTheme,
        home: Scaffold(body: ResidentHomePage(onNavigate: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monthly billing status'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Pay Bill'), findsNothing);
    expect(find.text('Need help from concierge or security?'), findsNothing);
  });

  testWidgets('access hub is visitor only', (tester) async {
    await _pumpAccessPage(tester);

    expect(find.text('Visitor Access'), findsOneWidget);
    expect(find.text('Create Visitor Access'), findsOneWidget);
    expect(find.text('Visitor History'), findsOneWidget);
    expect(find.text('Parking Access'), findsNothing);
    expect(find.text('Delivery Access'), findsNothing);
    expect(find.text('Guest Access'), findsNothing);
  });

  testWidgets('access hub opens create flow and history', (tester) async {
    await _pumpAccessPage(tester);

    await tester.tap(find.text('Create Visitor Access'));
    await tester.pumpAndSettle();

    expect(find.text('Register Visitor'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visitor History'));
    await tester.pumpAndSettle();

    expect(
      find.text('Track all visitor activity and check-in records.'),
      findsOneWidget,
    );
    expect(find.text('Michael Tan'), findsOneWidget);
  });

  testWidgets('visitor management completes create flow to history', (
    tester,
  ) async {
    await _pumpAccessPage(tester);

    await tester.tap(find.text('Create Visitor Access'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('visitor-name-field')),
      'Alex Morgan',
    );
    await tester.drag(
      find.byKey(const ValueKey('visitor-management-page')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Schedule Visit'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('visitor-management-page')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('PASS GENERATED'), findsOneWidget);

    await tester.ensureVisible(find.text('Share Visitor Pass'));
    await tester.tap(find.text('Share Visitor Pass'));
    await tester.pumpAndSettle();

    expect(find.text('Share Visitor Pass'), findsOneWidget);

    await tester.ensureVisible(find.text('Copy Link'));
    await tester.tap(find.text('Copy Link'));
    await tester.pump();

    expect(find.text('Visitor pass link copied'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue to Verification'));
    await tester.tap(find.text('Continue to Verification'));
    await tester.pump();

    expect(find.text('Scanning visitor pass...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('QR Verified'), findsOneWidget);

    await tester.tap(find.text('Access Approved'));
    await tester.pumpAndSettle();

    expect(find.text('Check-In Successful'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Visitor History'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
  });

  testWidgets('services hub shows request and history only', (tester) async {
    await _pumpServicesPage(tester);

    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Service Request'), findsOneWidget);
    expect(find.text('Service History'), findsOneWidget);
    expect(find.text('Facility Booking'), findsNothing);
    expect(find.text('New facility booking'), findsNothing);
  });

  testWidgets('services hub opens request flow and history', (tester) async {
    await _pumpServicesPage(tester);

    await tester.tap(find.text('Service Request'));
    await tester.pumpAndSettle();

    expect(find.text('What type of service do you need?'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service History'));
    await tester.pumpAndSettle();

    expect(
      find.text('Review every service request and its progress.'),
      findsOneWidget,
    );
    expect(find.textContaining('SR-2401'), findsOneWidget);
  });

  testWidgets('service request flow reaches history with new ticket', (
    tester,
  ) async {
    await _pumpServicesPage(tester);

    await tester.tap(find.text('Service Request'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();

    expect(find.text('Describe Issue'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('service-title-field')),
      'Leaky faucet',
    );
    await tester.drag(
      find.byKey(const ValueKey('service-request-page')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Request'));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.text('Ticket Created!'), findsOneWidget);

    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    expect(find.text('Assigned to Staff'), findsOneWidget);

    await tester.ensureVisible(find.text('Track Progress'));
    await tester.tap(find.text('Track Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Work In Progress'), findsOneWidget);

    await tester.ensureVisible(find.text('Mark as Completed'));
    await tester.tap(find.text('Mark as Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Request Completed'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('service-request-page')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close Request'));
    await tester.pumpAndSettle();

    expect(find.text('Rate Service'), findsOneWidget);

    await tester.ensureVisible(find.text('Submit Rating'));
    await tester.tap(find.text('Submit Rating'));
    await tester.pumpAndSettle();

    expect(find.text('Service History'), findsOneWidget);
    expect(find.textContaining('Leaky faucet'), findsOneWidget);
  });
}

Future<void> _pumpAccessPage(WidgetTester tester) async {
  await initializeDateFormatting('id_ID');
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightLuxuryTheme,
      home: const Scaffold(body: AccessPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpServicesPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightLuxuryTheme,
      home: const Scaffold(body: ServicesPage()),
    ),
  );
  await tester.pumpAndSettle();
}
