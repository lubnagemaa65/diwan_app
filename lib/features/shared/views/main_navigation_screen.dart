import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../assets/views/assets_list_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../../maintenance/views/maintenance_list_screen.dart';
import '../../users/views/users_list_screen.dart';
import 'profile_screen.dart';

/// نقطة الدخول الرئيسية بعد تسجيل الدخول.
/// تبني شريط تنقل سفلي مختلف بحسب دور المستخدم (Role-Based Access):
/// - Admin: الرئيسية، الأصول، الصيانة، المستخدمون، حسابي
/// - Employee/Technician: الرئيسية، الأصول، الصيانة، حسابي
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    final destinations = <_NavDestination>[
      _NavDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: context.tr('dashboard'),
        screen: const DashboardScreen(),
      ),
      _NavDestination(
        icon: Icons.devices_other_outlined,
        selectedIcon: Icons.devices_other_rounded,
        label: context.tr('assets'),
        screen: const AssetsListScreen(),
      ),
      _NavDestination(
        icon: Icons.build_outlined,
        selectedIcon: Icons.build_rounded,
        label: context.tr('maintenance'),
        screen: const MaintenanceListScreen(),
      ),
      if (isAdmin)
        _NavDestination(
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_alt_rounded,
          label: context.tr('users'),
          screen: const UsersListScreen(),
        ),
      _NavDestination(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: context.tr('profile'),
        screen: const ProfileScreen(),
      ),
    ];

    if (_currentIndex >= destinations.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: destinations.map((d) => d.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}
