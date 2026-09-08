import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small rounded pill, matching the plain gray role badges seen in the
/// Users screenshot ("مدير", "فني", "موظف"). Pass [color] to use a
/// different accent for status pills elsewhere (e.g. maintenance status).
class StatusPill extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusPill({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color == null ? AppColors.textSecondary.withValues(alpha: 0.12) : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color == null ? AppColors.textPrimary : c),
      ),
    );
  }
}
