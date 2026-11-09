import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart' as app_constants;
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/maintenance_order_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';

class MaintenanceDetailsScreen extends StatelessWidget {
  const MaintenanceDetailsScreen({super.key, required this.order});
  final MaintenanceOrderModel order;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManage = auth.isTechnician || auth.isAdmin;

    return Scaffold(
      appBar:
          AppBar(title: Text('${context.tr('request_number')} ${order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.deviceCode ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        // order.status من models/maintenance_order_model.dart نوعه enum
                        // مختلف (بنفس الاسم) عن الذي في app_constants. نطابق بالاسم.
                        StatusChip.maintenance(
                            status: app_constants.MaintenanceStatus.values
                                .firstWhere(
                          (e) => e.name == _mapStatusByName(order.status),
                          orElse: () => app_constants.MaintenanceStatus.pending,
                        )),
                      ],
                    ),
                    const Divider(height: 24),
                    _row(
                        context, context.tr('problem_type'), order.problemType),
                    _row(context, context.tr('requester'),
                        order.requesterName ?? '—'),
                    _row(context, context.tr('technician'),
                        order.technicianName ?? '—'),
                    if (order.date != null)
                      _row(context, context.tr('request_date'),
                          _formatDate(order.date!)),
                    const SizedBox(height: 8),
                    Text(context.tr('problem_description'),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(order.description),
                  ],
                ),
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 20),
              Text(context.tr('status'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _StatusActions(order: order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

/// يطابق حالة من enum الطلب إلى اسم نصي بسيط (String). بعض الـ enums في
/// المشروع تختلف بالنوع لكنها تتشارك نفس الأسماء، فـ StatusChip.maintenance
/// يقدر يستخدم الاسم لتحديد القيمة الصحيحة.
String _mapStatusByName(dynamic status) {
  try {
    final name = (status as dynamic).name;
    if (name is String && name.isNotEmpty) return name;
  } catch (_) {}
  final s = status?.toString() ?? '';
  final parts = s.split('.');
  return parts.isNotEmpty ? parts.last : s;
}

class _StatusActions extends StatefulWidget {
  const _StatusActions({required this.order});
  final MaintenanceOrderModel order;

  @override
  State<_StatusActions> createState() => _StatusActionsState();
}

class _StatusActionsState extends State<_StatusActions> {
  bool _updating = false;

  Future<void> _update(String status) async {
    setState(() => _updating = true);
    final provider = context.read<MaintenanceProvider>();
    final auth = context.read<AuthProvider>();
    // AppUser لا يحمل id رقمياً؛ نستخرجه من التوكن (JWT) عبر AuthProvider.
    final technicianId =
        auth.isTechnician ? auth.currentUserId?.toString() : null;
    final success = await provider.updateStatus(widget.order.id, status,
        technicianId: technicianId);
    if (!mounted) return;
    setState(() => _updating = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_updating) {
      return const Center(child: CircularProgressIndicator());
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () => _update('in_progress'),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(context.tr('in_progress')),
        ),
        OutlinedButton.icon(
          onPressed: () => _update('completed'),
          icon: const Icon(Icons.check_circle_outline,
              size: 18, color: AppColors.success),
          label: Text(context.tr('completed')),
        ),
        OutlinedButton.icon(
          onPressed: () => _update('cancelled'),
          icon: const Icon(Icons.cancel_outlined,
              size: 18, color: AppColors.error),
          label: Text(context.tr('cancelled')),
        ),
      ],
    );
  }
}
