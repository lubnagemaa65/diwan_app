import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/maintenance_order_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';
import 'maintenance_form_screen.dart';
import 'maintenance_details_screen.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaintenanceProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaintenanceProvider>();
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.isEmployee || auth.isAdmin;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('maintenance_requests'))),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MaintenanceFormScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(context.tr('add')),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<MaintenanceProvider>().loadOrders(),
        child: Column(
          children: [
            _buildStatusFilters(context, provider),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context, MaintenanceProvider provider) {
    final statuses = <String, String>{
      'all': context.tr('all'),
      'pending': context.tr('pending'),
      'inProgress': context.tr('in_progress'),
      'completed': context.tr('completed'),
      'cancelled': context.tr('cancelled'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: statuses.entries.map((entry) {
            final selected = provider.statusFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => provider.setStatusFilter(entry.key),
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
                side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MaintenanceProvider provider) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return ErrorStateWidget(
          message: provider.errorMessage,
          onRetry: () => provider.loadOrders(),
        );
      case LoadStatus.loaded:
        final orders = provider.filteredOrders;
        if (orders.isEmpty) {
          return EmptyState(message: context.tr('no_data'), icon: Icons.build_outlined);
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: orders.length,
          itemBuilder: (context, index) => _MaintenanceCard(order: orders[index]),
        );
    }
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.order});
  final MaintenanceOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MaintenanceDetailsScreen(order: order)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.deviceCode ?? '#${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  StatusChip.maintenance(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.category_outlined, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.problemType, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(width: 14),
                  if (order.technicianName != null) ...[
                    const Icon(Icons.engineering_outlined, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(order.technicianName!, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
