import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima_admin/config/theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  static const _items = [
    (icon: Iconsax.graph, label: 'Panel', path: '/dashboard'),
    (icon: Iconsax.calendar_1, label: 'Citas', path: '/appointments'),
    (icon: Iconsax.clock, label: 'Horario', path: '/schedule'),
    (icon: Iconsax.box_1, label: 'Catálogo', path: '/catalog'),
    (icon: Iconsax.people, label: 'Clientes', path: '/clients'),
    (icon: Iconsax.setting_2, label: 'Ajustes', path: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final idx = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: SafeArea(
          child: Row(
            children: [
              ..._items.asMap().entries.map((e) {
                final active = e.key == idx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(e.value.path),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          e.value.icon,
                          size: 20,
                          color: active ? AdminTheme.primaryColor : theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.value.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? AdminTheme.primaryColor : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? AdminTheme.primaryColor : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Expanded(
                child: GestureDetector(
                  onTap: () => themeProvider.toggle(),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          themeProvider.isDark ? Iconsax.sun_1 : Iconsax.moon,
                          key: ValueKey(themeProvider.isDark),
                          size: 20,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tema',
                        style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(width: 4, height: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
