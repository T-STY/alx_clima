import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Iconsax.home_2, activeIcon: Iconsax.home_25, label: 'Inicio', path: '/dashboard'),
    _NavItem(icon: Iconsax.calendar, activeIcon: Iconsax.calendar_1, label: 'Citas', path: '/appointments'),
    _NavItem(icon: Iconsax.clock, activeIcon: Iconsax.clock, label: 'Horarios', path: '/schedule'),
    _NavItem(icon: Iconsax.box_1, activeIcon: Iconsax.box_1, label: 'Catálogo', path: '/catalog'),
    _NavItem(icon: Iconsax.people, activeIcon: Iconsax.people, label: 'Clientes', path: '/clients'),
    _NavItem(icon: Iconsax.setting_2, activeIcon: Iconsax.setting_2, label: 'Ajustes', path: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 220,
              color: AdminTheme.surfaceColor,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AdminTheme.primaryColor, AdminTheme.secondaryColor],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Iconsax.wind, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ALX Admin',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AdminTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ..._navItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final isActive = index == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.go(item.path),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AdminTheme.primaryColor.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  size: 20,
                                  color: isActive
                                      ? AdminTheme.primaryColor
                                      : AdminTheme.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isActive
                                        ? AdminTheme.primaryColor
                                        : AdminTheme.textSecondary,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AdminTheme.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.user, size: 16, color: AdminTheme.primaryColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Técnico',
                              style: TextStyle(
                                color: AdminTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, color: AdminTheme.dividerColor),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AdminTheme.surfaceColor,
          border: Border(top: BorderSide(color: AdminTheme.dividerColor)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isActive = index == i;
                return GestureDetector(
                  onTap: () => context.go(item.path),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive ? AdminTheme.primaryColor : AdminTheme.textSecondary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? AdminTheme.primaryColor : AdminTheme.textSecondary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}
