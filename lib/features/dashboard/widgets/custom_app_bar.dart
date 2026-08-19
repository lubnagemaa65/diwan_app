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
  });

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthController>().logout();
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
          tooltip: 'Log out',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _confirmLogout(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
