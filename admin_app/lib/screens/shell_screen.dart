import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

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
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                ..._navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isActive = index == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => context.go(item.path),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 20,
                              color: isActive ? AdminTheme.primaryColor : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 9,
                                color: isActive ? AdminTheme.primaryColor : Theme.of(context).textTheme.bodySmall?.color,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () => themeProvider.toggle(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          themeProvider.isDark ? Iconsax.sun_1 : Iconsax.moon,
                          size: 20,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          themeProvider.isDark ? 'Claro' : 'Oscuro',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
