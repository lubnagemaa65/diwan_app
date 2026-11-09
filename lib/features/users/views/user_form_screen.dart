import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/user_model.dart';
import '../providers/users_provider.dart';

/// نموذج إضافة/تعديل مستخدم.
/// ملاحظة: الباك اند لا يسمح بتعديل الدور بعد الإنشاء، لذلك يظهر حقل
/// الدور للقراءة فقط عند التعديل. ويتطلب كلمة مرور عند الإنشاء (وتصبح
/// اختيارية عند التعديل — تُرسل فقط إن أراد المستخدم تغييرها).
class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.existing});
  final UserModel? existing;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late UserRole _role;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _emailController =
        TextEditingController(text: widget.existing?.email ?? '');
    _passwordController = TextEditingController();
    _role = widget.existing?.role ?? UserRole.employee;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// كلمة المرور: مطلوبة عند الإضافة، واختيارية عند التعديل (يُسمح
  /// بتركها فارغة لعدم تغييرها؛ إن كُتبت يجب أن تحقق شرط الباك اند).
  String? _validatePassword(String? v) {
    if (!_isEditing) return Validators.required(v);
    if (v == null || v.isEmpty) return null;
    if (v.length < 8) return 'يجب ألا تقل كلمة المرور عن 8 أحرف';
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasDigit) return 'يجب أن تحتوي على حرف ورقم على الأقل';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UsersProvider>();
    final password = _passwordController.text;

    final success = _isEditing
        ? await provider.updateUser(
            widget.existing!.id,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: password.isEmpty ? null : password,
          )
        : await provider.addUser(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: password,
            role: _role,
          );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEditing ? 'تم تحديث المستخدم' : 'تمت إضافة المستخدم'),
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
    final provider = context.watch<UsersProvider>();

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'تعديل المستخدم' : 'إضافة مستخدم جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'الاسم الكامل *',
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.email(v),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _passwordController,
                label:
                    _isEditing ? 'كلمة مرور جديدة (اختياري)' : 'كلمة المرور *',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: InputDecoration(
                  labelText: 'الدور *',
                  helperText:
                      _isEditing ? 'لا يمكن تغيير الدور بعد الإنشاء' : null,
                ),
                items: const [
                  DropdownMenuItem(value: UserRole.admin, child: Text('مدير')),
                  DropdownMenuItem(
                      value: UserRole.employee, child: Text('موظف')),
                  DropdownMenuItem(
                      value: UserRole.technician, child: Text('فني')),
                ],
                // الباك اند لا يسمح بتعديل الدور، فيتم تعطيل الحقل عند التعديل
                onChanged: _isEditing
                    ? null
                    : (v) => setState(() => _role = v ?? UserRole.employee),
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
                      label: _isEditing ? 'حفظ' : 'إضافة',
                      isLoading: provider.isSubmitting,
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
