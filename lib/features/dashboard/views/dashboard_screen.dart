import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/features/dashboard/widgets/trendStatCard.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/activity_log_model.dart';
import '../../assets/providers/assets_provider.dart';
import '../../assets/views/assets_list_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../maintenance/views/maintenance_form_screen.dart';
import '../../maintenance/views/maintenance_list_screen.dart';
import '../services/dashboard_stats_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats; // null = جاري التحميل
  List<ActivityLogModel> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetsProvider>().loadAssets();
      context.read<MaintenanceProvider>().loadOrders();
      _loadExtras();
    });
  }

  Future<void> _loadExtras() async {
    try {
      final stats = await DashboardStatsService.load();
      // سجل النشاطات متاح للمدير فقط في الباك اند (صلاحية manageUsers)،
      // فنتجاهل فشله بصمت لباقي الأدوار بدل إظهار خطأ مزعج.
      List<ActivityLogModel> activity = [];
      try {
        activity = await ActivityLogService.list(limit: 5);
      } on ApiException catch (_) {
        activity = [];
      }
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _recentActivity = activity;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _stats = null);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AssetsProvider>().loadAssets(),
      context.read<MaintenanceProvider>().loadOrders(),
      _loadExtras(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final assets = context.watch<AssetsProvider>();
    final maintenance = context.watch<MaintenanceProvider>();
    final user = auth.currentUser;
    final stats = _stats;

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
                user?.role.name ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // ==================== شبكة المؤشرات ====================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  TrendStatCard(
                    icon: Icons.computer_rounded,
                    title: context.tr('total_computers'),
                    value: '${assets.totalComputers}',
                    numericValue: assets.totalComputers,
                    color: AppColors.primary,
                  ),
                  TrendStatCard(
                    icon: Icons.print_rounded,
                    title: context.tr('total_printers'),
                    value: '${assets.totalPrinters}',
                    numericValue: assets.totalPrinters,
                    color: AppColors.secondary,
                  ),
                  TrendStatCard(
                    icon: Icons.pending_actions_rounded,
                    title: context.tr('pending_maintenance'),
                    value: '${maintenance.pendingCount}',
                    numericValue: maintenance.pendingCount,
                    color: AppColors.statusMaintenance,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MaintenanceListScreen()),
                    ),
                  ),
                  TrendStatCard(
                    icon: Icons.build_circle_outlined,
                    title: 'أجهزة تم إصلاحها',
                    value:
                        stats == null ? '…' : '${stats.devicesRepairedCount}',
                    numericValue: stats?.devicesRepairedCount,
                    color: AppColors.success,
                  ),
                  TrendStatCard(
                    icon: Icons.speed_rounded,
                    title: 'متوسط زمن الإصلاح',
                    value: stats?.averageRepairTimeLabel ?? '…',
                    color: Colors.deepPurple,
                  ),
                  TrendStatCard(
                    icon: Icons.task_alt_rounded,
                    title: 'نسبة الإنجاز',
                    value: stats == null
                        ? '…'
                        : '${(stats.completionRate * 100).round()}٪',
                    color: AppColors.success,
                  ),
                ],
              ),

              // ==================== رسم بياني لآخر 7 أيام ====================
              if (stats != null && stats.totalOrders > 0) ...[
                const SizedBox(height: 20),
                _WeeklyOrdersChart(counts: stats.last7DaysCounts),
              ],

              // ==================== آخر النشاطات ====================
              if (_recentActivity.isNotEmpty) ...[
                const SizedBox(height: 20),
                _RecentActivityCard(items: _recentActivity),
              ],

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

/// رسم بياني بسيط بأعمدة (بدون أي حزمة خارجية) لعدد الطلبات بآخر 7 أيام.
class _WeeklyOrdersChart extends StatelessWidget {
  const _WeeklyOrdersChart({required this.counts});
  final List<int> counts; // 7 عناصر، من الأقدم للأحدث

  static const _dayLabels = ['', '', '', '', '', '', 'اليوم'];

  @override
  Widget build(BuildContext context) {
    final maxVal = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('طلبات آخر 7 أيام',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('الإجمالي: ${counts.fold<int>(0, (a, b) => a + b)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < counts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 8 + (counts[i] / safeMax) * 64,
                        decoration: BoxDecoration(
                          color: i == counts.length - 1
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (int i = 0; i < _dayLabels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dayLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: i == _dayLabels.length - 1
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: i == _dayLabels.length - 1
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});
  final List<ActivityLogModel> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('آخر النشاطات',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 12),
            for (final log in items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded,
                          size: 15, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.action,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600)),
                          Text(log.userName,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
