import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima/config/theme.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Iconsax.home_2),
              selectedIcon: Icon(Iconsax.home_25),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.calculator),
              selectedIcon: Icon(Iconsax.calculator5),
              label: 'Cotizar',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.cpu_setting),
              selectedIcon: Icon(Iconsax.cpu_setting5),
              label: 'Mi Equipo',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.more_circle),
              selectedIcon: Icon(Iconsax.more_circle5),
              label: 'Más',
            ),
          ],
        ),
      ),
    );
  }
}
