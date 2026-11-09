import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../assets/views/assets_list_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../../maintenance/views/maintenance_list_screen.dart';
import 'admin_management_screen.dart';
import 'profile_screen.dart';

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
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings_rounded,
          label: 'الإدارة',
          screen: const AdminManagementScreen(),
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
        children: [
          for (int i = 0; i < destinations.length; i++)
            // HeroMode يعطّل تسجيل الـ Hero (ومنه الزر العائم الافتراضي)
            // للشاشات غير الظاهرة حالياً، لأن IndexedStack يُبقيها جميعاً
            // في الشجرة بنفس الوقت — وهذا هو الحل الموثّق من Flutter
            // تحديداً لتصادم "multiple heroes share the same tag" في هذه
            // الحالة، بدل الاضطرار لتعديل كل شاشة على حدة.
            HeroMode(
              enabled: i == _currentIndex,
              child: destinations[i].screen,
            ),
        ],
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
