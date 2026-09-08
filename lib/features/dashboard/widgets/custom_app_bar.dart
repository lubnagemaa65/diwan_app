import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controller/auth_controller.dart';
import '../../auth/models/user_model.dart';
import 'role_badge.dart';

/// Shared app bar used on every dashboard screen: page title, the
/// current user's role badge, and a logout action.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final UserRole role;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.role,
    required TabBar bottom,
  });

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthController>().logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(child: RoleBadge(role: role)),
        ),
        IconButton(
          tooltip: 'تسجيل الخروج',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _confirmLogout(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
