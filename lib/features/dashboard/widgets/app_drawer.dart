import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/models/user_model.dart';
import 'role_badge.dart';

class _DrawerItem {
  final IconData icon;
  final String label;
  const _DrawerItem(this.icon, this.label);
}

/// Role-aware side drawer. Each role sees a different set of menu items,
/// mirroring the web dashboard's sidebar navigation.
class AppDrawer extends StatelessWidget {
  final UserRole role;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AppDrawer({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onSelect,
  });

  List<_DrawerItem> get _items {
    switch (role) {
      case UserRole.admin:
        return const [
          _DrawerItem(Icons.dashboard_rounded, 'نظرة عامة'),
          _DrawerItem(Icons.people_alt_rounded, 'إدارة المستخدمين'),
          _DrawerItem(Icons.settings_rounded, 'إعدادات النظام'),
        ];
      case UserRole.technician:
        return const [
          _DrawerItem(Icons.menu_book_rounded, 'الكتب الصادرة والواردة'),
          _DrawerItem(Icons.assignment_rounded, 'سجل الكتب'),
        ];
      case UserRole.employee:
        return const [
          _DrawerItem(Icons.add_circle_rounded, 'طلب جديد'),
          _DrawerItem(Icons.person_rounded, 'الملف الشخصي'),
          _DrawerItem(Icons.timeline_rounded, 'متابعة الحالة'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  RoleBadge(role: role),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    leading: Icon(item.icon,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor:
                        AppColors.primary.withValues(alpha: 0.08),
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      onSelect(index);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.statusBroken),
              title: const Text('تسجيل الخروج',
                  style: TextStyle(color: AppColors.statusBroken)),
              onTap: () async {
                context.read<AuthController>().logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (_) => false);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
