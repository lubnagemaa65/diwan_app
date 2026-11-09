import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/printer_model.dart';
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

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _codeController = TextEditingController(text: p?.code ?? '');
    _type = p?.type;
    _collegeId = p?.collegeId;
    _employeeId = p?.employeeId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (!_formKey.currentState!.validate()) return;
    if (_collegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الكلية'), backgroundColor: AppColors.error),
      );
      return;
    }

    final provider = context.read<AssetsProvider>();
    final payload = {
      'code': _codeController.text.trim(),
      'type': _type,
      'collegeId': _collegeId,
      'employeeId': _employeeId,
    };

    final success = widget.isEditing
        ? await provider.updatePrinter(widget.existing!.id, payload)
        : await provider.addPrinter(payload);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'تم تحديث الطابعة' : 'تمت إضافة الطابعة'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsProvider = context.watch<AssetsProvider>();
    final collegesProvider = context.watch<CollegesProvider>();
    final employeesProvider = context.watch<EmployeesProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'تعديل طابعة' : 'إضافة طابعة جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _codeController,
                label: 'المعرّف (مثال: COL03-PR001) *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'النوع *'),
                items: const [
                  DropdownMenuItem(value: 'ليزر', child: Text('ليزر')),
                  DropdownMenuItem(value: 'نافثة للحبر', child: Text('نافثة للحبر')),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _collegeId,
                decoration: const InputDecoration(labelText: 'الكلية *'),
                items: collegesProvider.colleges
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _collegeId = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _employeeId,
                decoration: const InputDecoration(labelText: 'الموظف المسؤول (اختياري)'),
                items: employeesProvider.employees
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)))
                    .toList(),
                onChanged: (v) => setState(() => _employeeId = v),
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
