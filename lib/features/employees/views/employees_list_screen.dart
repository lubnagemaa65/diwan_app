import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../models/employee_model.dart';
import '../providers/employees_provider.dart';
import 'employee_form_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeesProvider>().loadEmployees();
    });
  }

  Future<void> _confirmDelete(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الموظف'),
        content: Text('هل أنت متأكد من حذف "${employee.fullName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<EmployeesProvider>();
      final success = await provider.deleteEmployee(employee.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الموظفون')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadEmployees(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة موظف'),
                ),
              ),
            ),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EmployeesProvider provider) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return ErrorStateWidget(message: provider.errorMessage, onRetry: provider.loadEmployees);
      case LoadStatus.loaded:
        if (provider.employees.isEmpty) {
          return const EmptyState(message: 'لا يوجد موظفون مضافون بعد', icon: Icons.badge_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: provider.employees.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final employee = provider.employees[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.badge_outlined, size: 20),
              ),
              title: Text(employee.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(employee.collegeName ?? '—', style: const TextStyle(color: AppColors.textSecondary)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () => _confirmDelete(employee),
                tooltip: 'حذف',
              ),
            );
          },
        );
    }
  }
}
