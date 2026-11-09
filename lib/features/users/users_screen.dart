import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:university_assets_app/features/users/providers/users_provider.dart';
import 'package:university_assets_app/features/users/views/user_form_screen.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/load_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_list_screen.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/user_model.dart';

/// شاشة "المستخدمون" — متصلة بالباك اند الحقيقي عبر [UsersProvider]

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UsersProvider>(
      create: (_) => UsersProvider()..loadUsers(),
      child: const _UsersScreenBody(),
    );
  }
}

class _UsersScreenBody extends StatelessWidget {
  const _UsersScreenBody();

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'مدير';
      case UserRole.technician:
        return 'فني';
      case UserRole.employee:
        return 'موظف';
    }
  }

  Future<void> _openForm(BuildContext context, {UserModel? existing}) async {
    final provider = context.read<UsersProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: UserFormScreen(existing: existing),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المستخدم "${user.name}"؟'),
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
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<UsersProvider>();
    final ok = await provider.deleteUser(user.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حذف المستخدم' : provider.errorMessage),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();

    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Scaffold(
            body: LoadingIndicator(message: 'جاري تحميل المستخدمين...'));

      case LoadStatus.error:
        return Scaffold(
          body: ErrorStateWidget(
            message: provider.errorMessage,
            onRetry: () => context.read<UsersProvider>().loadUsers(),
          ),
        );

      case LoadStatus.loaded:
        final users = provider.users;

        if (users.isEmpty) {
          return DataListScreen(
            route: '/users',
            title: 'المستخدمون',
            addLabel: 'إضافة مستخدم',
            onAdd: () => _openForm(context),
            columns: const [
              ListColumn('الاسم', flex: 3),
              ListColumn('البريد الإلكتروني', flex: 4),
              ListColumn('الدور', flex: 2),
            ],
            rows: const [],
            emptyMessage: 'لا يوجد مستخدمون حالياً',
            onEdit: null,
            onDelete: null,
          );
        }

        return DataListScreen(
          route: '/users',
          title: 'المستخدمون',
          addLabel: 'إضافة مستخدم',
          onAdd: () => _openForm(context),
          columns: const [
            ListColumn('الاسم', flex: 3),
            ListColumn('البريد الإلكتروني', flex: 4),
            ListColumn('الدور', flex: 2),
          ],
          rows: [
            for (final u in users)
              [
                Text(u.name),
                Text(u.email),
                StatusPill(label: _roleLabel(u.role)),
              ],
          ],
          onEdit: (i) => _openForm(context, existing: users[i]),
          onDelete: (i) => _confirmDelete(context, users[i]),
        );
    }
  }
}
