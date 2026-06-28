import '../../models/resident_user.dart';
import '../../services/api_service.dart';
import '../../services/app_debug_logger.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/role_scaffold.dart';
import '../../l10n/generated/app_localizations.dart';
import 'access/access_page.dart';
import 'billing/billing_page.dart';
import 'community/community_page.dart';
import 'home/resident_home_page.dart';
import 'profile/profile_page.dart';
import 'services/facility_booking_page.dart';
import 'services/services_page.dart';

class ResidentShell extends StatefulWidget {
  const ResidentShell({
    super.key,
    this.apiService,
    this.currentLocale = const Locale('id'),
    this.onLocaleChanged,
  });

  final ApiService? apiService;
  final Locale currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell> {
  late final ApiService _apiService = widget.apiService ?? ApiService();
  var _index = 0;
  var _showBilling = false;
  var _showFacilityBooking = false;
  ResidentUser? _resident;
  var _isHydratingResident = false;

  @override
  void initState() {
    super.initState();
    _loadResidentSession();
  }

  Future<void> _loadResidentSession() async {
    if (_isHydratingResident) {
      return;
    }

    _isHydratingResident = true;
    appDebugLog('ResidentShell', 'Loading resident session for home/profile');

    final cachedResident = await _apiService.getCachedResident();
    if (mounted && cachedResident != null) {
      appDebugLog(
        'ResidentShell',
        'Home/Profile initialized from cached resident data',
      );
      setState(() => _resident = cachedResident);
    }

    try {
      final refreshedResident = await _apiService.getResidentMe();
      if (!mounted) {
        return;
      }

      appDebugLog(
        'ResidentShell',
        'Resident session refreshed from /resident/me',
      );
      setState(() => _resident = refreshedResident);
    } catch (error) {
      appDebugLog('ResidentShell', 'Resident session refresh failed: $error');
    } finally {
      _isHydratingResident = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ResidentHomePage(
        resident: _resident,
        apiService: _apiService,
        onNavigate: (newIndex) => setState(() {
          _showBilling = false;
          _showFacilityBooking = false;
          _index = newIndex;
        }),
        onOpenBilling: () => setState(() {
          _showBilling = true;
          _showFacilityBooking = false;
          _index = 0;
        }),
        onOpenFacilityBooking: () => setState(() {
          _showBilling = false;
          _showFacilityBooking = true;
          _index = 0;
        }),
      ),
      AccessPage(resident: _resident, apiService: _apiService),
      const ServicesPage(),
      CommunityPage(apiService: _apiService),
      ProfilePage(
        apiService: _apiService,
        resident: _resident,
        currentLocale: widget.currentLocale,
        onLocaleChanged: widget.onLocaleChanged,
      ),
    ];
    final l10n = AppLocalizations.of(context);

    return RoleScaffold(
      currentIndex: _index,
      onIndexChanged: (value) => setState(() {
        _showBilling = false;
        _showFacilityBooking = false;
        _index = value;
      }),
      roleLabel: 'Resident App',
      compactHeader: _index != 0 && !_showBilling && !_showFacilityBooking,
      showHeader: _index != 0 && !_showBilling && !_showFacilityBooking,
      items: [
        RoleNavItem(
          label: l10n.home,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        RoleNavItem(
          label: l10n.access,
          icon: Icons.qr_code_scanner_outlined,
          selectedIcon: Icons.qr_code_scanner,
        ),
        RoleNavItem(
          label: l10n.services,
          icon: Icons.handyman_outlined,
          selectedIcon: Icons.handyman,
        ),
        RoleNavItem(
          label: l10n.community,
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
        ),
        RoleNavItem(
          label: l10n.profile,
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _showBilling
            ? BillingPage(
                key: const ValueKey('resident-hidden-billing-page'),
                onBack: () => setState(() => _showBilling = false),
              )
            : _showFacilityBooking
            ? FacilityBookingPage(
                key: const ValueKey('resident-hidden-facility-booking-page'),
                onBack: () => setState(() => _showFacilityBooking = false),
              )
            : pages[_index],
      ),
    );
  }
}
