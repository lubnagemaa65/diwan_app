import 'package:flutter/material.dart';
import 'package:university_assets_app/core/constants/app_constants.dart'
    show AssetStatus;
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/core/theme/app_colors.dart';
import 'package:university_assets_app/core/widgets/data_list_screen.dart';
import 'package:university_assets_app/core/widgets/error_state.dart';
import 'package:university_assets_app/core/widgets/loading_indicator.dart';
import 'package:university_assets_app/core/widgets/status_pill.dart';
import 'package:university_assets_app/features/assets/views/computer_form_screen.dart';
import 'package:university_assets_app/models/computer_model.dart';

Color _statusColor(AssetStatus status) {
  switch (status) {
    case AssetStatus.active:
      return AppColors.success;
    case AssetStatus.underMaintenance:
      return AppColors.warning;
    case AssetStatus.broken:
      return AppColors.statusBroken;
    case AssetStatus.unknown:
      return AppColors.textSecondary;
  }
}

/// شاشة "الحواسيب" — متصلة بالباك اند الحقيقي عبر [ComputerService]
/// (تمت إزالة الاعتماد على mock_data.dart بالكامل).
class ComputersScreen extends StatefulWidget {
  const ComputersScreen({super.key});

  @override
  State<ComputersScreen> createState() => _ComputersScreenState();
}

class _ComputersScreenState extends State<ComputersScreen> {
  List<ComputerModel>? _computers; // null = جاري التحميل
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _computers = null;
      _error = null;
    });
    try {
      final data = await ComputerService.list();
      if (!mounted) return;
      setState(() => _computers = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تحميل الحواسيب');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _openForm({ComputerModel? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ComputerFormScreen(existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(ComputerModel computer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الحاسوب "${computer.code}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ComputerService.delete(computer.id);
      _showMessage('تم حذف الحاسوب');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: ErrorStateWidget(message: _error!, onRetry: _load));
    }

    final computers = _computers;
    if (computers == null) {
      return const Scaffold(
          body: LoadingIndicator(message: 'جاري تحميل الحواسيب...'));
    }

    return DataListScreen(
      route: '/computers',
      title: 'الحواسيب',
      addLabel: 'إضافة حاسوب',
      onAdd: () => _openForm(),
      emptyMessage: 'لا توجد حواسيب حالياً',
      columns: const [
        ListColumn('اسم الجهاز', flex: 2),
        ListColumn('الكلية', flex: 3),
        ListColumn('الحالة', flex: 2),
      ],
      rows: [
        for (final c in computers)
          [
            Text(c.code),
            Text(c.collegeName ?? '—'),
            StatusPill(
              label: switch (c.status) {
                AssetStatus.active => 'نشط',
                AssetStatus.underMaintenance => 'قيد الصيانة',
                AssetStatus.broken => 'مكسور',
                AssetStatus.unknown => 'غير معروف',
              },
              color: _statusColor(c.status),
            ),
          ],
      ],
      onEdit: (i) => _openForm(existing: computers[i]),
      onDelete: (i) => _confirmDelete(computers[i]),
    );
  }
}
