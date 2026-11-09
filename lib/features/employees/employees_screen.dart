import 'package:flutter/material.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/core/theme/app_colors.dart';
import 'package:university_assets_app/core/widgets/data_list_screen.dart';
import 'package:university_assets_app/core/widgets/error_state.dart';
import 'package:university_assets_app/core/widgets/loading_indicator.dart';
import 'package:university_assets_app/models/college_model.dart';
import 'package:university_assets_app/models/employee_model.dart';
import 'package:university_assets_app/models/user_model.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<EmployeeModel>? _employees; // null = جاري التحميل
  List<CollegeModel> _colleges = [];
  List<UserModel> _users = [];
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _employees = null;
      _error = null;
    });
    try {
      final results = await Future.wait([
        EmployeeService.list(),
        CollegeService.list(),
        UserService.list(),
      ]);
      if (!mounted) return;
      setState(() {
        _employees = results[0] as List<EmployeeModel>;
        _colleges = results[1] as List<CollegeModel>;
        _users = results[2] as List<UserModel>;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تحميل الموظفين');
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

  Future<void> _openForm({EmployeeModel? existing}) async {
    final firstNameCtrl =
        TextEditingController(text: existing?.firstName ?? '');
    final fatherNameCtrl =
        TextEditingController(text: existing?.fatherName ?? '');
    final familyNameCtrl =
        TextEditingController(text: existing?.familyName ?? '');
    final formKey = GlobalKey<FormState>();

    String? collegeId = existing?.collegeId;
    // عند الإضافة فقط: يُعرض المستخدمون غير المرتبطين بعد بأي موظف.
    final linkedUserIds = (_employees ?? const <EmployeeModel>[])
        .map((e) => e.userId)
        .whereType<String>()
        .toSet();
    final availableUsers = existing == null
        ? _users.where((u) => !linkedUserIds.contains(u.id)).toList()
        : _users;
    String? userId = existing?.userId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'إضافة موظف' : 'تعديل الموظف'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: firstNameCtrl,
                    decoration: const InputDecoration(labelText: 'الاسم الأول'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: fatherNameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الأب'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: familyNameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم العائلة'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: collegeId,
                    decoration: const InputDecoration(labelText: 'الكلية'),
                    items: [
                      for (final c in _colleges)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setDialogState(() => collegeId = v),
                  ),
                  if (existing == null) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: userId,
                      decoration: const InputDecoration(
                        labelText: 'المستخدم المرتبط',
                        helperText: 'المستخدمون غير المرتبطين بموظف آخر فقط',
                      ),
                      items: [
                        for (final u in availableUsers)
                          DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.name} (${u.email})')),
                      ],
                      onChanged: (v) => setDialogState(() => userId = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (collegeId == null) {
                  _showMessage('يجب اختيار الكلية', isError: true);
                  return;
                }
                if (existing == null && userId == null) {
                  _showMessage('يجب اختيار المستخدم المرتبط', isError: true);
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(existing == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      if (existing == null) {
        await EmployeeService.create(EmployeeModel(
          id: '',
          firstName: firstNameCtrl.text.trim(),
          fatherName: fatherNameCtrl.text.trim(),
          familyName: familyNameCtrl.text.trim(),
          userId: userId,
          collegeId: collegeId,
        ));
      } else {
        await EmployeeService.update(EmployeeModel(
          id: existing.id,
          firstName: firstNameCtrl.text.trim(),
          fatherName: fatherNameCtrl.text.trim(),
          familyName: familyNameCtrl.text.trim(),
          userId: existing.userId,
          collegeId: collegeId,
        ));
      }
      if (!mounted) return;
      _showMessage(existing == null ? 'تمت إضافة الموظف' : 'تم تحديث الموظف');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الموظف "${employee.fullName}"؟'),
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
      await EmployeeService.delete(employee.id);
      _showMessage('تم حذف الموظف');
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

    final employees = _employees;
    if (employees == null) {
      return const Scaffold(
          body: LoadingIndicator(message: 'جاري تحميل الموظفين...'));
    }

    return DataListScreen(
      route: '/employees',
      title: 'الموظفون',
      addLabel: 'إضافة موظف',
      onAdd: _submitting ? null : () => _openForm(),
      emptyMessage: 'لا يوجد موظفون حالياً',
      columns: const [
        ListColumn('الاسم', flex: 3),
        ListColumn('الكلية', flex: 3),
      ],
      rows: [
        for (final e in employees)
          [
            Text(e.fullName),
            Text(e.collegeName ?? '—'),
          ],
      ],
      onEdit: (i) => _openForm(existing: employees[i]),
      onDelete: (i) => _confirmDelete(employees[i]),
    );
  }
}
