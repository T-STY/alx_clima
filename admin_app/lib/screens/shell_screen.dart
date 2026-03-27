import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:alx_clima_admin/config/theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _items = [
    _Nav(icon: Iconsax.home_2, activeIcon: Iconsax.home_25, label: 'Inicio', path: '/dashboard'),
    _Nav(icon: Iconsax.calendar, activeIcon: Iconsax.calendar_1, label: 'Citas', path: '/appointments'),
    _Nav(icon: Iconsax.clock, activeIcon: Iconsax.clock, label: 'Horarios', path: '/schedule'),
    _Nav(icon: Iconsax.box_1, activeIcon: Iconsax.box_1, label: 'Catálogo', path: '/catalog'),
    _Nav(icon: Iconsax.people, activeIcon: Iconsax.people, label: 'Clientes', path: '/clients'),
    _Nav(icon: Iconsax.setting_2, activeIcon: Iconsax.setting_2, label: 'Ajustes', path: '/settings'),
  ];

  int _activeIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _items.length; i++) { if (loc.startsWith(_items[i].path)) return i; }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _activeIndex(context);
    final tp = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5))),
        child: SafeArea(child: SizedBox(height: 60, child: Row(children: [
          ..._items.asMap().entries.map((e) {
            final i = e.key; final item = e.value; final active = idx == i;
            return Expanded(child: GestureDetector(
              onTap: () => context.go(item.path), behavior: HitTestBehavior.opaque,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(color: active ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                  child: Icon(active ? item.activeIcon : item.icon, size: 20, color: active ? theme.colorScheme.primary : muted),
                ),
                const SizedBox(height: 3),
                Text(item.label, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? theme.colorScheme.primary : muted, letterSpacing: 0.2)),
              ]),
            ));
          }),
          GestureDetector(
            onTap: () => tp.toggle(), behavior: HitTestBehavior.opaque,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Icon(tp.isDark ? Iconsax.sun_1 : Iconsax.moon, key: ValueKey(tp.isDark), size: 20, color: muted)),
              const SizedBox(height: 3),
              Text(tp.isDark ? 'Claro' : 'Oscuro', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 0.2)),
            ])),
          ),
        ]))),
      ),
    );
  }
}

class _Nav {
  final IconData icon; final IconData activeIcon; final String label; final String path;
  const _Nav({required this.icon, required this.activeIcon, required this.label, required this.path});
}
