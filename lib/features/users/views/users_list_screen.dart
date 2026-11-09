import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../providers/users_provider.dart';
import 'user_form_screen.dart';

/// شاشة إدارة المستخدمين — متاحة فقط لدور المدير (Admin).
/// مطابقة لجدول "المستخدمون" الأصلي: الاسم، البريد، الدور، إجراءات (تعديل/حذف).
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadUsers();
    });
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل أنت متأكد من حذف "${user.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<UsersProvider>();
      final success = await provider.deleteUser(user.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(provider.errorMessage),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadUsers(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserFormScreen()),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('إضافة مستخدم'),
                ),
              ),
            ),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UsersProvider provider) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return ErrorStateWidget(
            message: provider.errorMessage, onRetry: provider.loadUsers);
      case LoadStatus.loaded:
        if (provider.users.isEmpty) {
          return const EmptyState(
              message: 'لا يوجد مستخدمون', icon: Icons.people_outline);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: provider.users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _UserRow(
            user: provider.users[index],
            onEdit: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      UserFormScreen(existing: provider.users[index])),
            ),
            onDelete: () => _confirmDelete(provider.users[index]),
          ),
        );
    }
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow(
      {required this.user, required this.onEdit, required this.onDelete});
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.technician:
        return AppColors.statusMaintenance;
      case UserRole.employee:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'مدير';
      case UserRole.technician:
        return 'فني';
      case UserRole.employee:
        return 'موظف';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Text(
          user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title:
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(user.email,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _roleLabel(user.role),
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.actionEdit),
            onPressed: onEdit,
            tooltip: 'تعديل',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.error),
            onPressed: onDelete,
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }
}
