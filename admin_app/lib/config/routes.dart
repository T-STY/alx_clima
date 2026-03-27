import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alx_clima_admin/screens/shell_screen.dart';
import 'package:alx_clima_admin/screens/dashboard/dashboard_screen.dart';
import 'package:alx_clima_admin/screens/appointments/appointments_screen.dart';
import 'package:alx_clima_admin/screens/catalog/catalog_screen.dart';
import 'package:alx_clima_admin/screens/clients/clients_screen.dart';
import 'package:alx_clima_admin/screens/settings/settings_screen.dart';

final routerKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/dashboard',
  navigatorKey: routerKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdminShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/appointments',
              builder: (context, state) => const AppointmentsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/catalog',
              builder: (context, state) => const CatalogScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/clients',
              builder: (context, state) => const ClientsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
