import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/printer_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/providers/colleges_provider.dart';
import '../../employees/providers/employees_provider.dart';
import '../providers/assets_provider.dart';

class PrinterFormScreen extends StatefulWidget {
  const PrinterFormScreen({super.key, this.existing});
  final PrinterModel? existing;

  bool get isEditing => existing != null;

  @override
  State<PrinterFormScreen> createState() => _PrinterFormScreenState();
}

class _PrinterFormScreenState extends State<PrinterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  String? _type;
  String? _collegeId;
  String? _employeeId;
  int _employeeFieldVersion = 0;
  int _collegeFieldVersion = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _codeController = TextEditingController(text: p?.code ?? '');
    _type = p?.type;
    _collegeId = p?.collegeId;
    _employeeId = p?.employeeId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colleges = context.read<CollegesProvider>();
      if (colleges.status == LoadStatus.initial) colleges.loadColleges();
      final employees = context.read<EmployeesProvider>();
      if (employees.status == LoadStatus.initial) employees.loadEmployees();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!context.read<AuthProvider>().isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('إدارة الأصول متاحة للمدير فقط حسب صلاحيات الخادم.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (widget.isEditing && _collegeId != widget.existing!.collegeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'لا يدعم الخادم تغيير كلية الطابعة بعد إنشائها؛ أعد اختيار الكلية الأصلية.'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (!widget.isEditing && _collegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار الكلية'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    final provider = context.read<AssetsProvider>();
    final payload = {
      'type': _type,
      if (!widget.isEditing) 'collegeId': _collegeId,
    };

    final success = widget.isEditing
        ? await provider.updatePrinter(widget.existing!.id, payload)
        : await provider.addPrinter(payload);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.isEditing ? 'تم تحديث الطابعة' : 'تمت إضافة الطابعة'),
          backgroundColor: AppColors.success,
        ),
      );
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
    final assetsProvider = context.watch<AssetsProvider>();
    final collegesProvider = context.watch<CollegesProvider>();
    final employeesProvider = context.watch<EmployeesProvider>();
    final collegeOptions = <String, String>{
      for (final c in collegesProvider.colleges) c.id: c.name,
      if (_collegeId != null &&
          !collegesProvider.colleges.any((c) => c.id == _collegeId))
        _collegeId!: _collegeId == widget.existing?.collegeId
            ? widget.existing?.collegeName ?? _collegeId!
            : _collegeId!,
    };
    final employeeOptions = <String, String>{
      for (final e in employeesProvider.employees) e.id: e.fullName,
      if (_employeeId != null &&
          !employeesProvider.employees.any((e) => e.id == _employeeId))
        _employeeId!: widget.existing?.employeeName ?? _employeeId!,
    };
    final typeOptions = <String>{
      'ليزر',
      'نافثة للحبر',
      if (_type != null) _type!
    };

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isEditing ? 'تعديل طابعة' : 'إضافة طابعة جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeController,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'المعرّف (يُولّد تلقائياً)'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'النوع *'),
                items: typeOptions
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'يرجى اختيار نوع الطابعة'
                    : null,
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey('college-$_collegeFieldVersion'),
                initialValue: _collegeId,
                decoration: const InputDecoration(labelText: 'الكلية *'),
                items: collegeOptions.entries
                    .map((c) =>
                        DropdownMenuItem(value: c.key, child: Text(c.value)))
                    .toList(),
                onChanged: (v) {
                  if (widget.isEditing && v != widget.existing!.collegeId) {
                    setState(() => _collegeFieldVersion++);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'لا يدعم الخادم تغيير كلية الطابعة بعد إنشائها.'),
                      backgroundColor: AppColors.error,
                    ));
                    return;
                  }
                  setState(() => _collegeId = v);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey(_employeeFieldVersion),
                initialValue: _employeeId,
                decoration: const InputDecoration(
                    labelText: 'الموظف المسؤول (اختياري)'),
                items: employeeOptions.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (_) {
                  setState(() => _employeeFieldVersion++);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('لا يدعم الخادم ربط الطابعة بموظف.'),
                    backgroundColor: AppColors.error,
                  ));
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: widget.isEditing ? 'حفظ' : 'إضافة',
                      isLoading: assetsProvider.isSubmitting,
                      onPressed: _submit,
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
