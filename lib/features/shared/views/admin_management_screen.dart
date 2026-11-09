import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../colleges/views/colleges_list_screen.dart';
import '../../employees/views/employees_list_screen.dart';
import '../../users/views/users_list_screen.dart';

/// شاشة "الإدارة" (Admin فقط) — تجمع كل شاشات الإدارة الفرعية التي كانت
/// موزّعة في الشريط الجانبي بالنظام الأصلي (المستخدمون، الكليات، الموظفون).
class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ManagementItem>[
      _ManagementItem(
        icon: Icons.people_alt_rounded,
        title: 'المستخدمون',
        subtitle: 'إدارة حسابات الدخول والأدوار',
        builder: (_) => const UsersListScreen(),
      ),
      _ManagementItem(
        icon: Icons.school_rounded,
        title: 'الكليات',
        subtitle: 'إضافة وتعديل وحذف الكليات',
        builder: (_) => const CollegesListScreen(),
      ),
      _ManagementItem(
        icon: Icons.badge_rounded,
        title: 'الموظفون',
        subtitle: 'إدارة بيانات الموظفين وربطهم بالكليات',
        builder: (_) => const EmployeesListScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الإدارة')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: AppColors.primary),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: item.builder)),
            ),
          );
        },
      ),
    );
  }
}

class _ManagementItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _ManagementItem({required this.icon, required this.title, required this.subtitle, required this.builder});
}
