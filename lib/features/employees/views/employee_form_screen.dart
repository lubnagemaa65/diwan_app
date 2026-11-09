import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../colleges/providers/colleges_provider.dart';
import '../../users/providers/users_provider.dart';
import '../providers/employees_provider.dart';

/// شاشة "إضافة موظف جديد" — مطابقة لحقول النموذج الأصلي بالضبط:
/// الاسم الأول، اسم الأب، اسم العائلة، المستخدم (ربط بحساب دخول)، الكلية.
class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _familyNameController = TextEditingController();

  String? _selectedUserId;
  String? _selectedCollegeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadUsers();
      final colleges = context.read<CollegesProvider>();
      if (colleges.status == LoadStatus.initial) colleges.loadColleges();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الكلية'), backgroundColor: AppColors.error),
      );
      return;
    }

    final provider = context.read<EmployeesProvider>();
    final success = await provider.addEmployee(
      firstName: _firstNameController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      familyName: _familyNameController.text.trim(),
      userId: _selectedUserId,
      collegeId: _selectedCollegeId,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الإضافة بنجاح'), backgroundColor: AppColors.success),
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
    final usersProvider = context.watch<UsersProvider>();
    final collegesProvider = context.watch<CollegesProvider>();
    final employeesProvider = context.watch<EmployeesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة موظف جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _firstNameController,
                label: 'الاسم الأول *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _fatherNameController,
                label: 'اسم الأب *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _familyNameController,
                label: 'اسم العائلة *',
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                decoration: const InputDecoration(labelText: 'المستخدم *'),
                items: usersProvider.users
                    .map((u) => DropdownMenuItem(value: u.id, child: Text(u.email)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedUserId = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCollegeId,
                decoration: const InputDecoration(labelText: 'الكلية *'),
                items: collegesProvider.colleges
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCollegeId = v),
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
                      label: 'إضافة',
                      isLoading: employeesProvider.isSubmitting,
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
