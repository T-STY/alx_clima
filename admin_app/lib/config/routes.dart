import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alx_clima_admin/screens/shell_screen.dart';
import 'package:alx_clima_admin/screens/dashboard/dashboard_screen.dart';
import 'package:alx_clima_admin/screens/appointments/appointments_screen.dart';
import 'package:alx_clima_admin/screens/schedule/schedule_screen.dart';
import 'package:alx_clima_admin/screens/catalog/catalog_screen.dart';
import 'package:alx_clima_admin/screens/clients/clients_screen.dart';
import 'package:alx_clima_admin/screens/settings/settings_screen.dart';

final adminRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: '/schedule',
          builder: (context, state) => const ScheduleScreen(),
        ),
        GoRoute(
          path: '/catalog',
          builder: (context, state) => const CatalogScreen(),
        ),
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
