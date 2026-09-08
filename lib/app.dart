import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';

import 'features/assets/providers/assets_provider.dart';
import 'features/auth/providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();

    // يربط DioClient بحدث "انتهاء الجلسة" حتى يتم تسجيل خروج المستخدم
    // تلقائيًا في كل التطبيق عند فشل تجديد التوكن (401)
    DioClient().onSessionExpired = () async {
      await _authProvider.handleSessionExpired();
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<AssetsProvider>(create: (_) => AssetsProvider()),
        ChangeNotifierProvider<MaintenanceProvider>(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider<UsersProvider>(create: (_) => UsersProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'University Assets',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,

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
