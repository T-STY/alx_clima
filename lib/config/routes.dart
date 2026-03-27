import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:alx_clima/providers/auth_provider.dart';
import 'package:alx_clima/screens/auth/login_screen.dart';
import 'package:alx_clima/screens/contact/contact_screen.dart';
import 'package:alx_clima/screens/dashboard/dashboard_screen.dart';
import 'package:alx_clima/screens/dashboard/equipment_detail_screen.dart';
import 'package:alx_clima/screens/dashboard/schedule_screen.dart';
import 'package:alx_clima/screens/future_services/future_services_screen.dart';
import 'package:alx_clima/screens/home/home_screen.dart';
import 'package:alx_clima/screens/profile/profile_screen.dart';
import 'package:alx_clima/screens/quote/equipment_select_screen.dart';
import 'package:alx_clima/screens/quote/installation_details_screen.dart';
import 'package:alx_clima/screens/quote/quote_summary_screen.dart';
import 'package:alx_clima/screens/quote/quote_type_screen.dart';
import 'package:alx_clima/screens/shell_screen.dart';
import 'package:alx_clima/screens/tips/care_tips_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isSignedIn = authProvider.isSignedIn;
      final isLoading = authProvider.isLoading;
      final isOnLogin = state.matchedLocation == '/login';

      if (isLoading) return null;

      if (!isSignedIn && !isOnLogin) return '/login';
      if (isSignedIn && isOnLogin) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quote',
                builder: (context, state) => const QuoteTypeScreen(),
              ),
            ],
          ),
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
                path: '/services',
                builder: (context, state) => const FutureServicesScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quote/equipment',
        builder: (context, state) => const EquipmentSelectScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quote/installation',
        builder: (context, state) => const InstallationDetailsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quote/summary',
        builder: (context, state) => const QuoteSummaryScreen(),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dashboard/equipment/:id',
        builder: (context, state) => EquipmentDetailScreen(
          equipmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dashboard/schedule',
        builder: (context, state) {
          final equipmentIds = state.uri.queryParameters['equipmentIds'];
          final equipmentId = state.uri.queryParameters['equipmentId'];
          final fromQuote = state.uri.queryParameters['fromQuote'] == 'true';
          final rescheduleId = state.uri.queryParameters['rescheduleId'];
          List<String>? ids;
          if (equipmentIds != null && equipmentIds.isNotEmpty) {
            ids = equipmentIds.split(',');
          } else if (equipmentId != null && equipmentId.isNotEmpty) {
            ids = [equipmentId];
          }
          return ScheduleScreen(
            prefilledEquipmentIds: ids,
            fromQuote: fromQuote,
            rescheduleId: rescheduleId,
          );
        },
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tips',
        builder: (context, state) => const CareTipsScreen(),
      ),
    ],
  );
}
