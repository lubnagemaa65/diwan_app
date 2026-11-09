import 'package:flutter/material.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/core/theme/app_colors.dart';
import 'package:university_assets_app/core/widgets/data_list_screen.dart';
import 'package:university_assets_app/core/widgets/error_state.dart';
import 'package:university_assets_app/core/widgets/loading_indicator.dart';
import 'package:university_assets_app/models/college_model.dart';

/// شاشة "الكليات" — متصلة بالباك اند الحقيقي عبر [CollegeService]
/// (تمت إزالة _mockColleges بالكامل).
class CollegesScreen extends StatefulWidget {
  const CollegesScreen({super.key});

  @override
  State<CollegesScreen> createState() => _CollegesScreenState();
}

class _CollegesScreenState extends State<CollegesScreen> {
  List<CollegeModel>? _colleges; // null = جاري التحميل
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _colleges = null;
      _error = null;
    });
    try {
      final data = await CollegeService.list();
      if (!mounted) return;
      setState(() => _colleges = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تحميل الكليات');
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

  Future<void> _openNameDialog({CollegeModel? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة كلية' : 'تعديل الكلية'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم الكلية'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: Text(existing == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    );

    if (name == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      if (existing == null) {
        await CollegeService.create(name);
      } else {
        await CollegeService.update(existing.id, name);
      }
      if (!mounted) return;
      _showMessage(existing == null ? 'تمت إضافة الكلية' : 'تم تحديث الكلية');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete(CollegeModel college) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف كلية "${college.name}"؟\n'
            'لن تتم العملية إذا كان مرتبطاً بها موظفون أو أجهزة.'),
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
      await CollegeService.delete(college.id);
      _showMessage('تم حذف الكلية');
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

    final colleges = _colleges;
    if (colleges == null) {
      return const Scaffold(
          body: LoadingIndicator(message: 'جاري تحميل الكليات...'));
    }

    return DataListScreen(
      route: '/colleges',
      title: 'الكليات',
      addLabel: 'إضافة كلية',
      onAdd: _submitting ? null : () => _openNameDialog(),
      emptyMessage: 'لا توجد كليات حالياً',
      columns: const [
        ListColumn('الرقم', flex: 1),
        ListColumn('اسم الكلية', flex: 4),
      ],
      rows: [
        for (int i = 0; i < colleges.length; i++)
          [
            Text('${i + 1}'),
            Text(colleges[i].name),
          ],
      ],
      onEdit: (i) => _openNameDialog(existing: colleges[i]),
      onDelete: (i) => _confirmDelete(colleges[i]),
      footer: '© 2026 نظام إدارة أجهزة الجامعة — جميع الحقوق محفوظة',
    );
  }
}
