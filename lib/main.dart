import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/routes.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/firebase_options.dart';
import 'package:alx_clima/providers/appointment_provider.dart';
import 'package:alx_clima/providers/auth_provider.dart';
import 'package:alx_clima/providers/dashboard_provider.dart';
import 'package:alx_clima/providers/quote_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('es');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final themeProvider = ClientThemeProvider();
  await themeProvider.loadFromPrefs();

  runApp(ALXClimaApp(themeProvider: themeProvider));
}

class ALXClimaApp extends StatefulWidget {
  final ClientThemeProvider themeProvider;

  const ALXClimaApp({super.key, required this.themeProvider});

  @override
  State<ALXClimaApp> createState() => _ALXClimaAppState();
}

class _ALXClimaAppState extends State<ALXClimaApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = buildRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: Consumer<ClientThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'ALX-Clima',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
