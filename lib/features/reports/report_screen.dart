import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';

class ReportStat {
  final String label;
  final String value;
  final Color color;
  const ReportStat(this.label, this.value, this.color);
}

/// Shared layout for the 3 "تقرير ..." sidebar pages. Not captured in a
/// screenshot — a simple stat-card summary is a reasonable placeholder
/// until the real reporting endpoints/shape are known.
class ReportScreen extends StatelessWidget {
  final String route;
  final String title;
  final List<ReportStat> stats;

  const ReportScreen(
      {super.key,
      required this.route,
      required this.title,
      required this.stats});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: route,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final s in stats)
                    Container(
                      width: 190,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.darkSurface),
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(s.label,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 10),
                          Text(s.value,
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: s.color)),
                        ],
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
