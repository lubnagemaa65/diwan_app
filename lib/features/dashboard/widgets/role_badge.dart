import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';

/// Small pill badge showing the current user's role, used in the
/// custom app bar and profile sections.
class RoleBadge extends StatelessWidget {
  final UserRole role;
  const RoleBadge({super.key, required this.role});

  Color get _color {
    switch (role) {
      case UserRole.admin:
        return AppColors.statusActive;
      case UserRole.technician:
        return AppColors.statusInProgress;
      case UserRole.employee:
        return AppColors.statusBroken;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        role.name,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
