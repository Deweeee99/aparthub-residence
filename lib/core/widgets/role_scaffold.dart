import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'luxury_background.dart';

class RoleNavItem {
  const RoleNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class RoleScaffold extends StatelessWidget {
  const RoleScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    required this.child,
    required this.roleLabel,
    this.compactHeader = false,
    this.showHeader = true,
  });

  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<RoleNavItem> items;
  final Widget child;
  final String roleLabel;
  final bool compactHeader;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return LuxuryBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: showHeader
            ? AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: compactHeader ? 64 : 76,
                titleSpacing: 22,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ApartHub',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      roleLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        body: SafeArea(top: false, child: child),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.glassFillStrong,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: onIndexChanged,
                  items: [
                    for (var i = 0; i < items.length; i++)
                      BottomNavigationBarItem(
                        icon: Icon(
                          currentIndex == i
                              ? items[i].selectedIcon
                              : items[i].icon,
                        ),
                        label: items[i].label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
