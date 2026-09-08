import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nav_items.dart';

/// Shared scaffold used by every screen: the blue app bar (title + menu
/// icon on the right, user avatar on the left — matching the screenshots)
/// and the sidebar drawer listing all sections.
///
/// FUTURE: replace the hardcoded avatar initial with the logged-in user's
/// real initial/name once auth state is wired to a real backend session.
class AppShell extends StatelessWidget {
  final String currentRoute;
  final Widget body;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'نظام إدارة أجهزة الجامعة',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: false,
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text('A',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        // In RTL, "actions" render at the visual left, matching the
        // screenshot's menu icon placement next to the title on the right.
        actions: const [
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.menu_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final item in kNavItems)
                ListTile(
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: item.route == currentRoute
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: item.route == currentRoute
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: Icon(
                    item.icon,
                    color: item.route == currentRoute
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  selected: item.route == currentRoute,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.06),
                  onTap: () {
                    Navigator.pop(context);
                    if (item.route != currentRoute) {
                      Navigator.of(context).pushReplacementNamed(item.route);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
