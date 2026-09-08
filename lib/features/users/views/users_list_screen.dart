import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../providers/users_provider.dart';

/// شاشة إدارة المستخدمين — متاحة فقط لدور المدير (Admin) عبر Role-Based Access
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('users'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: فتح نموذج إضافة مستخدم جديد (يتبع نفس نمط MaintenanceFormScreen)
        },
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadUsers(),
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UsersProvider provider) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return ErrorStateWidget(message: provider.errorMessage, onRetry: provider.loadUsers);
      case LoadStatus.loaded:
        if (provider.users.isEmpty) {
          return EmptyState(message: context.tr('no_data'), icon: Icons.people_outline);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.users.length,
          itemBuilder: (context, index) => _UserTile(user: provider.users[index]),
        );
    }
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final UserModel user;

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.technician:
        return AppColors.statusMaintenance;
      case UserRole.employee:
        return AppColors.info;
      case UserRole.unknown:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            context.isArabic ? user.role.labelAr() : user.role.labelEn(),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
