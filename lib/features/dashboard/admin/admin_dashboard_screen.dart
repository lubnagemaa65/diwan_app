import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

class _AdminMetric {
  const _AdminMetric({
    required this.label,
    required this.value,
    required this.trend,
  });

  final String label;
  final String value;
  final String trend;
}

class _ManagedUserSummary {
  const _ManagedUserSummary({
    required this.name,
    required this.email,
    required this.role,
    required this.active,
  });

  final String name;
  final String email;
  final String role;
  final bool active;
}

const List<_AdminMetric> _adminMetrics = [
  _AdminMetric(label: 'إجمالي المستخدمين', value: '1,284', trend: '+12.4%'),
  _AdminMetric(label: 'الطلبات النشطة', value: '86', trend: '+8.1%'),
  _AdminMetric(label: 'المخزون', value: '94%', trend: '-2.3%'),
  _AdminMetric(label: 'المراجعات', value: '312', trend: '+15.6%'),
];

const List<_ManagedUserSummary> _managedUsers = [
  _ManagedUserSummary(
    name: 'محمد علي',
    email: 'm.ali@facility.com',
    role: 'مدير',
    active: true,
  ),
  _ManagedUserSummary(
    name: 'سارة محمد',
    email: 's.mohammed@facility.com',
    role: 'موظفة',
    active: true,
  ),
  _ManagedUserSummary(
    name: 'خالد ياسر',
    email: 'k.yaser@facility.com',
    role: 'مشرف',
    active: false,
  ),
  _ManagedUserSummary(
    name: 'أمينة حمد',
    email: 'a.hamad@facility.com',
    role: 'مستندات',
    active: true,
  ),
];

const List<String> _systemSettingsLinks = [
  'إعدادات الحسابات',
  'إعدادات النظام',
  'إعدادات الأمان',
  'سجل المراجعات',
];

/// لوحة تحكم المدير: مؤشرات عامة، قائمة إدارة المستخدمين، وروابط إعدادات النظام.
///
/// FUTURE API WIRING:
///   - Metrics -> GET AppConstants.adminMetricsEndpoint
///   - Users   -> GET AppConstants.adminUsersEndpoint
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedSection = 0; // 0=نظرة عامة، 1=إدارة المستخدمين، 2=الإعدادات

  static const _titles = ['نظرة عامة', 'إدارة المستخدمين', 'إعدادات النظام'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_selectedSection],
        role: UserRole.admin,
        bottom: const TabBar(
          tabs: [
            Tab(text: 'One'),
            Tab(text: 'Two'),
          ],
        ),
      ),
      drawer: AppDrawer(
        role: UserRole.admin,
        selectedIndex: _selectedSection,
        onSelect: (i) => setState(() => _selectedSection = i),
      ),
      body: IndexedStack(
        index: _selectedSection,
        children: const [
          _OverviewSection(),
          _UserManagementSection(),
          _SystemSettingsSection(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedSection,
        onDestinationSelected: (i) => setState(() => _selectedSection = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'نظرة عامة'),
          NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_alt_rounded),
              label: 'المستخدمون'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('المؤشرات الرئيسية',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _adminMetrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final metric = _adminMetrics[index];
            final isPositive = metric.trend.startsWith('+');
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metric.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(metric.value,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      metric.trend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? AppColors.success
                            : AppColors.statusBroken,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('النشاط الأخير',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _activityTile(
                  'تم إنشاء كتاب صادر جديد', 'WO-1044 · أولوية عالية'),
              const Divider(height: 1),
              _activityTile('تم تحديث حساب مستخدم', 'محمد علي · تم إيقافه'),
              const Divider(height: 1),
              _activityTile('تمت الموافقة على طلب موظف', 'REQ-2198'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityTile(String title, String subtitle) {
    return ListTile(
      leading: const Icon(Icons.history_rounded, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

class _UserManagementSection extends StatelessWidget {
  const _UserManagementSection();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _managedUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _managedUsers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                user.name.substring(0, 1),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(user.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${user.email} · ${user.role}'),
            trailing: Chip(
              label: Text(user.active ? 'نشط' : 'غير نشط'),
              backgroundColor:
                  (user.active ? AppColors.success : AppColors.textSecondary)
                      .withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color:
                    user.active ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              side: BorderSide.none,
            ),
            onTap: () {
              // FUTURE: navigate to user detail / edit screen backed by
              // GET AppConstants.adminUsersEndpoint/{user.id}
            },
          ),
        );
      },
    );
  }
}

class _SystemSettingsSection extends StatelessWidget {
  const _SystemSettingsSection();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _systemSettingsLinks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final label = _systemSettingsLinks[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
            title: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () {
              // FUTURE: route to the relevant settings sub-screen, each
              // backed by its own GET/PUT endpoint.
            },
          ),
        );
      },
    );
  }
}
