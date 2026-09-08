import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(email: _emailController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() => _sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? context.tr('error_generic')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('forgot_password_title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                _sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                _sent ? context.tr('reset_link_sent') : context.tr('forgot_password_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 28),
              if (!_sent) ...[
                Form(
                  key: _formKey,
                  child: CustomTextField(
                    controller: _emailController,
                    label: context.tr('email'),
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => Validators.email(
                      v,
                      requiredMsg: context.tr('field_required'),
                      invalidMsg: context.tr('invalid_email'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: context.tr('send_reset_link'),
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
              ] else
                CustomButton(
                  label: context.tr('back_to_login'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
