import 'package:flutter/material.dart';

import '../../core/widgets/role_scaffold.dart';
import 'access/access_page.dart';
import 'community/community_page.dart';
import 'home/resident_home_page.dart';
import 'profile/profile_page.dart';
import 'services/services_page.dart';

class ResidentShell extends StatefulWidget {
  const ResidentShell({super.key});

  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ResidentHomePage(
        onNavigate: (newIndex) => setState(() => _index = newIndex),
      ),
      const AccessPage(),
      const ServicesPage(),
      const CommunityPage(),
      const ProfilePage(),
    ];

    return RoleScaffold(
      currentIndex: _index,
      onIndexChanged: (value) => setState(() => _index = value),
      roleLabel: 'Resident App',
      compactHeader: _index != 0,
      showHeader: _index != 0,
      items: const [
        RoleNavItem(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        RoleNavItem(
          label: 'Access',
          icon: Icons.qr_code_scanner_outlined,
          selectedIcon: Icons.qr_code_scanner,
        ),
        RoleNavItem(
          label: 'Services',
          icon: Icons.handyman_outlined,
          selectedIcon: Icons.handyman,
        ),
        RoleNavItem(
          label: 'Community',
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
        ),
        RoleNavItem(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: pages[_index],
      ),
    );
  }
}
