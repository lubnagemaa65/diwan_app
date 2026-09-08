import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:university_assets_app/core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../assets/providers/assets_provider.dart';
import '../../assets/views/assets_list_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../maintenance/views/maintenance_form_screen.dart';
import '../../maintenance/views/maintenance_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetsProvider>().loadAssets();
      context.read<MaintenanceProvider>().loadOrders();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AssetsProvider>().loadAssets(),
      context.read<MaintenanceProvider>().loadOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final assets = context.watch<AssetsProvider>();
    final maintenance = context.watch<MaintenanceProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('dashboard'))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${context.tr('welcome')} ${user?.name ?? ''} 👋',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.isArabic
                    ? user?.role.labelAr() ?? ''
                    : user?.role.labelEn() ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.computer_rounded,
                    label: context.tr('total_computers'),
                    value: assets.totalComputers.toString(),
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    icon: Icons.print_rounded,
                    label: context.tr('total_printers'),
                    value: assets.totalPrinters.toString(),
                    color: AppColors.secondary,
                  ),
                  _StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: context.tr('active_assets'),
                    value: assets.activeCount.toString(),
                    color: AppColors.success,
                  ),
                  _StatCard(
                    icon: Icons.pending_actions_rounded,
                    label: context.tr('pending_maintenance'),
                    value: maintenance.pendingCount.toString(),
                    color: AppColors.statusMaintenance,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MaintenanceListScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(context.tr('quick_actions'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.devices_other_rounded,
                      label: context.tr('assets'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AssetsListScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (auth.isEmployee || auth.isAdmin)
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.build_rounded,
                        label: context.tr('new_maintenance_request'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MaintenanceFormScreen()),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.list_alt_rounded,
                        label: context.tr('maintenance_requests'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MaintenanceListScreen()),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
