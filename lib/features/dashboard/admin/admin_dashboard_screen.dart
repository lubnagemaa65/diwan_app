import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

/// Admin dashboard: overview metrics, user management list, and system
/// settings links.
///
/// FUTURE API WIRING:
///   - Metrics -> GET AppConstants.adminMetricsEndpoint
///   - Users   -> GET AppConstants.adminUsersEndpoint
/// Replace `mockAdminMetrics` / `mockManagedUsers` with data loaded by an
/// `AdminRepository` (same pattern as `AuthRepository`) inside `initState`
/// or a `FutureBuilder`.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedSection = 0; // 0=Overview, 1=User Management, 2=Settings

  static const _titles = ['Overview', 'User Management', 'System Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_selectedSection],
        role: UserRole.admin,
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
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_alt_rounded),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings'),
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
        const Text('Key Metrics',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockAdminMetrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final metric = mockAdminMetrics[index];
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
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Recent Activity',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _activityTile('New work order created', 'WO-1044 · High priority'),
              const Divider(height: 1),
              _activityTile('User account updated', 'Marcus Lee · deactivated'),
              const Divider(height: 1),
              _activityTile('Employee request approved', 'REQ-2198'),
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
      itemCount: mockManagedUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = mockManagedUsers[index];
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
              label: Text(user.active ? 'Active' : 'Inactive'),
              backgroundColor: (user.active
                      ? AppColors.success
                      : AppColors.textSecondary)
                  .withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: user.active ? AppColors.success : AppColors.textSecondary,
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
      itemCount: mockSystemSettingsLinks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final label = mockSystemSettingsLinks[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded),
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
