import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/computer_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../colleges/providers/colleges_provider.dart';
import '../../employees/providers/employees_provider.dart';
import '../providers/assets_provider.dart';

/// نموذج "إضافة حاسوب جديد" / تعديل — مطابق لحقول النظام الأصلي بالضبط:
/// المعرّف، النوع، الكلية، الموظف، المعالج، نوع القرص، حجم القرص، الرام.
class ComputerFormScreen extends StatefulWidget {
  const ComputerFormScreen({super.key, this.existing});
  final ComputerModel? existing;

  bool get isEditing => existing != null;

  @override
  State<ComputerFormScreen> createState() => _ComputerFormScreenState();
}

class _ComputerFormScreenState extends State<ComputerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _processorController;
  late final TextEditingController _diskSizeController;

  late ComputerType _type;
  String? _diskType;
  String? _ram;
  String? _collegeId;
  String? _employeeId;
  int _collegeFieldVersion = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeController = TextEditingController(text: e?.code ?? '');
    _processorController = TextEditingController(text: e?.processor ?? '');
    _diskSizeController = TextEditingController(text: e?.diskSize ?? '');
    _type = e?.type ?? ComputerType.desktop;
    _diskType = e?.diskType;
    _ram = e?.ram;
    _collegeId = e?.collegeId;
    _employeeId = e?.employeeId;

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
    _processorController.dispose();
    _diskSizeController.dispose();
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
    if (!widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'تعذّر إنشاء الحاسوب: يتطلب الخادم اللوحة الأم وبطاقة الرسوميات، وهما غير متاحتين في هذا النموذج.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_collegeId != widget.existing!.collegeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'لا يدعم الخادم تغيير كلية الحاسوب بعد إنشائه؛ أعد اختيار الكلية الأصلية.'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    final provider = context.read<AssetsProvider>();
    final payload = {
      'type': _type == ComputerType.laptop ? 'laptop' : 'desktop',
      if (_employeeId != widget.existing?.employeeId) 'employeeId': _employeeId,
      'processor': _processorController.text.trim(),
      'diskType': _diskType,
      'diskSize': _diskSizeController.text.trim(),
      'ram': _ram,
    };

    final success = widget.isEditing
        ? await provider.updateComputer(widget.existing!.id, payload)
        : await provider.addComputer(payload);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.isEditing ? 'تم تحديث الحاسوب' : 'تمت إضافة الحاسوب'),
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
        _employeeId!: _employeeId == widget.existing?.employeeId
            ? widget.existing?.employeeName ?? _employeeId!
            : _employeeId!,
    };
    final ramOptions = <String>{
      'DDR3',
      'DDR4',
      'DDR5',
      if (_ram != null) _ram!
    };
    final diskOptions = <String>{
      'SATA',
      'IDE',
      if (_diskType != null) _diskType!
    };

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isEditing ? 'تعديل حاسوب' : 'إضافة حاسوب جديد')),
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
              DropdownButtonFormField<ComputerType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'النوع *'),
                items: [
                  const DropdownMenuItem(
                      value: ComputerType.desktop, child: Text('مكتبي')),
                  const DropdownMenuItem(
                      value: ComputerType.laptop, child: Text('محمول')),
                  if (_type == ComputerType.unknown)
                    const DropdownMenuItem(
                        value: ComputerType.unknown, child: Text('غير معروف')),
                ],
                validator: (v) => v == null || v == ComputerType.unknown
                    ? 'يرجى اختيار نوع الحاسوب'
                    : null,
                onChanged: (v) =>
                    setState(() => _type = v ?? ComputerType.desktop),
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
                      content:
                          Text('لا يدعم الخادم تغيير كلية الحاسوب بعد إنشائه.'),
                      backgroundColor: AppColors.error,
                    ));
                    return;
                  }
                  setState(() => _collegeId = v);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _employeeId,
                decoration: const InputDecoration(
                    labelText: 'الموظف المسؤول (اختياري)'),
                items: employeeOptions.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _employeeId = v),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _processorController,
                label: 'المعالج (مثال: Core i5) *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _diskType,
                decoration:
                    const InputDecoration(labelText: 'نوع القرص الصلب *'),
                items: diskOptions
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                validator: (v) => v == 'SATA' || v == 'IDE'
                    ? null
                    : 'يرجى اختيار SATA أو IDE',
                onChanged: (v) => setState(() => _diskType = v),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _diskSizeController,
                label: 'حجم القرص (مثال: 512 أو 1TB) *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _ram,
                decoration: const InputDecoration(
                    labelText: 'الذاكرة العشوائية (RAM) *'),
                items: ramOptions
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'يرجى اختيار الذاكرة'
                    : null,
                onChanged: (v) => setState(() => _ram = v),
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
