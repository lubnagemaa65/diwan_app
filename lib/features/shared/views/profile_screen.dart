import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/views/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('logout_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('logout'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.primary),
              title: Text(context.tr('settings')),
              subtitle: Text(localeProvider.locale.languageCode == 'ar' ? 'العربية' : 'English'),
              trailing: Switch(
                value: localeProvider.locale.languageCode == 'en',
                onChanged: (_) => localeProvider.toggle(),
              ),
              onTap: () => localeProvider.toggle(),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(context.tr('logout'), style: const TextStyle(color: AppColors.error)),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}
