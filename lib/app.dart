import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';

import 'features/assets/providers/assets_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_screen.dart';
import 'features/colleges/providers/colleges_provider.dart';
import 'features/employees/providers/employees_provider.dart';
import 'features/maintenance/providers/maintenance_provider.dart';
import 'features/shared/views/splash_screen.dart';
import 'features/users/providers/users_provider.dart';

class UniversityAssetsApp extends StatefulWidget {
  const UniversityAssetsApp({super.key});

  @override
  State<UniversityAssetsApp> createState() => _UniversityAssetsAppState();
}

class _UniversityAssetsAppState extends State<UniversityAssetsApp> {
  late final AuthProvider _authProvider;
  final _navigatorKey = GlobalKey<NavigatorState>();
  AuthStatus _lastStatus = AuthStatus.unknown;
  int _navigationGeneration = 0;
  late AssetsProvider _assets;
  late MaintenanceProvider _maintenance;
  late UsersProvider _users;
  late CollegesProvider _colleges;
  late EmployeesProvider _employees;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(navigationManaged: true);
    _newSessionProviders();
    _authProvider.addListener(_onAuthChanged);
  }

  void _newSessionProviders() {
    _assets = AssetsProvider();
    _maintenance = MaintenanceProvider();
    _users = UsersProvider();
    _colleges = CollegesProvider();
    _employees = EmployeesProvider();
  }

  void _onAuthChanged() {
    final previous = _lastStatus;
    final current = _authProvider.status;
    _lastStatus = current;
    if (previous != AuthStatus.authenticated ||
        current != AuthStatus.unauthenticated) {
      return;
    }

    // The old instances are detached, not disposed while their async methods
    // may still call notifyListeners. They become collectible after those
    // operations finish; a new session never receives their cached data.
    setState(_newSessionProviders);
    final generation = ++_navigationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _navigationGeneration ||
          _authProvider.isAuthenticated) {
        return;
      }
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<AssetsProvider>.value(value: _assets),
        ChangeNotifierProvider<MaintenanceProvider>.value(value: _maintenance),
        ChangeNotifierProvider<UsersProvider>.value(value: _users),
        ChangeNotifierProvider<CollegesProvider>.value(value: _colleges),
        ChangeNotifierProvider<EmployeesProvider>.value(value: _employees),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'University Assets',
            theme: AppTheme.light,
            darkTheme: AppTheme.light,
            themeMode: ThemeMode.light,

            // ---------------- Localization / RTL ----------------
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale?.languageCode) {
                  return supported;
                }
              }
              return const Locale('ar');
            },

            builder: (context, child) {
              // يضمن اتجاه RTL/LTR الصحيح على مستوى التطبيق بالكامل
              final isArabic = localeProvider.locale.languageCode == 'ar';
              return Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
