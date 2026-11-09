import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../models/college_model.dart';
import '../providers/colleges_provider.dart';

/// شاشة إدارة الكليات (Admin فقط) — مطابقة لجدول "الكليات" في النظام الأصلي:
/// عمود الرقم، اسم الكلية، وإجراءات (تعديل/حذف)، مع زر "إضافة كلية" أعلى الشاشة.
class CollegesListScreen extends StatefulWidget {
  const CollegesListScreen({super.key});

  @override
  State<CollegesListScreen> createState() => _CollegesListScreenState();
}

class _CollegesListScreenState extends State<CollegesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollegesProvider>().loadColleges();
    });
  }

  Future<void> _showCollegeDialog({CollegeModel? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();
    final provider = context.read<CollegesProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة كلية جديدة' : 'تعديل الكلية'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم الكلية *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(ctx).pop(true);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = existing == null
          ? await provider.addCollege(controller.text.trim())
          : await provider.updateCollege(existing.id, controller.text.trim());
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(CollegeModel college) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الكلية'),
        content: Text('هل أنت متأكد من حذف "${college.name}"؟'),
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
      final provider = context.read<CollegesProvider>();
      final success = await provider.deleteCollege(college.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollegesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الكليات')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadColleges(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showCollegeDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة كلية'),
                ),
              ),
            ),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CollegesProvider provider) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return ErrorStateWidget(message: provider.errorMessage, onRetry: provider.loadColleges);
      case LoadStatus.loaded:
        if (provider.colleges.isEmpty) {
          return const EmptyState(message: 'لا توجد كليات مضافة بعد', icon: Icons.school_outlined);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: provider.colleges.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final college = provider.colleges[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
                child: Text('${index + 1}'),
              ),
              title: Text(college.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.actionEdit),
                    onPressed: () => _showCollegeDialog(existing: college),
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    onPressed: () => _confirmDelete(college),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            );
          },
        );
    }
  }
}
