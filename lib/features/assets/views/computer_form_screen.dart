import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/computer_model.dart';
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
      'type': _type == ComputerType.laptop ? 'laptop' : 'desktop',
      'collegeId': _collegeId,
      'employeeId': _employeeId,
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
          content: Text(widget.isEditing ? 'تم تحديث الحاسوب' : 'تمت إضافة الحاسوب'),
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
      appBar: AppBar(title: Text(widget.isEditing ? 'تعديل حاسوب' : 'إضافة حاسوب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _codeController,
                label: 'المعرّف (مثال: COL03-PC001) *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ComputerType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'النوع *'),
                items: const [
                  DropdownMenuItem(value: ComputerType.desktop, child: Text('مكتبي')),
                  DropdownMenuItem(value: ComputerType.laptop, child: Text('محمول')),
                ],
                onChanged: (v) => setState(() => _type = v ?? ComputerType.desktop),
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
              const SizedBox(height: 14),
              CustomTextField(
                controller: _processorController,
                label: 'المعالج (مثال: Core i5) *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _diskType,
                decoration: const InputDecoration(labelText: 'نوع القرص الصلب *'),
                items: const [
                  DropdownMenuItem(value: 'SSD', child: Text('SSD')),
                  DropdownMenuItem(value: 'SATA', child: Text('SATA')),
                  DropdownMenuItem(value: 'HDD', child: Text('HDD')),
                ],
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
                decoration: const InputDecoration(labelText: 'الذاكرة العشوائية (RAM) *'),
                items: const [
                  DropdownMenuItem(value: 'DDR3', child: Text('DDR3')),
                  DropdownMenuItem(value: 'DDR4', child: Text('DDR4')),
                  DropdownMenuItem(value: 'DDR5', child: Text('DDR5')),
                ],
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
