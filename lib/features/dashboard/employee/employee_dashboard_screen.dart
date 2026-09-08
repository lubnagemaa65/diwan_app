import 'package:flutter/material.dart';
import 'package:university_assets_app/features/auth/models/user_model.dart';

import 'package:university_assets_app/core/enums/request_status.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

// =============================================================================
// MISSING DEFINITIONS (Fixes "Undefined class" and "getter 'label' isn't defined")
// =============================================================================

/// Request model representing employee asset/facility requests.
class EmployeeRequest {
  final String id;
  final String subject;
  final String category;
  final String details;
  final String dateSubmitted;
  final RequestStatus status;

  const EmployeeRequest({
    required this.id,
    required this.subject,
    required this.category,
    required this.details,
    required this.dateSubmitted,
    required this.status,
  });
}

/// Extension providing display labels for RequestStatus enum values.
extension RequestStatusExtension on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.submitted:
        return 'تم الإرسال';
      case RequestStatus.inReview:
        return 'قيد المراجعة';
      case RequestStatus.approved:
        return 'مقبول';
      case RequestStatus.rejected:
        return 'مرفوض';
      case RequestStatus.loading:
        return 'جاري التحميل';
      case RequestStatus.success:
        return 'تم بنجاح';
      case RequestStatus.failure:
        return 'فشل';
      case RequestStatus.idle:
      default:
        return 'معلق';
    }
  }
}

// =============================================================================
// SCREEN & WIDGET IMPLEMENTATION
// =============================================================================

const Map<String, String> mockEmployeeProfile = {
  'name': '.زينة مرشد',
  'department': 'مديرية نظم المعلومات',
  'employeeId': 'EMP-1001',
  'manager': 'نغم الغضة',
};

/// لوحة تحكم الموظف: تقديم طلب، عرض الملف الشخصي، ومتابعة حالة الطلبات.
class EmployeeDashboardScreen extends StatelessWidget {
  final List<EmployeeRequest> mockEmployeeRequests;

  const EmployeeDashboardScreen({
    super.key,
    required this.mockEmployeeRequests,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const CustomAppBar(
          role: UserRole.employee,
          title: 'لوحة تحكم الموظف',
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_task), text: 'طلب جديد'),
              Tab(icon: Icon(Icons.track_changes), text: 'حالة الطلبات'),
              Tab(icon: Icon(Icons.person), text: 'الملف الشخصي'),
            ],
          ),
        ),
        drawer: AppDrawer(
          role: UserRole.employee,
          selectedIndex: 0,
          onSelect: (int _) {},
        ),
        body: TabBarView(
          children: [
            const _NewRequestForm(),
            _StatusTrackerSection(requests: mockEmployeeRequests),
            const _ProfileSection(),
          ],
        ),
      ),
    );
  }
}

class _NewRequestForm extends StatefulWidget {
  const _NewRequestForm();

  @override
  State<_NewRequestForm> createState() => _NewRequestFormState();
}

class _NewRequestFormState extends State<_NewRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  String _category = 'مرافق';
  bool _submitting = false;

  static const _categories = [
    'مرافق',
    'معدات',
    'تقنية المعلومات',
    'صلاحيات الدخول',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // MOCK: simulate submission latency
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال الطلب بنجاح.'),
        backgroundColor: AppColors.success,
      ),
    );
    _subjectController.clear();
    _detailsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تقديم طلب جديد',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'الموضوع',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'مثال: لوحة مفاتيح جديدة',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الموضوع مطلوب' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'الفئة',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            const Text(
              'التفاصيل',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'صِف طلبك...',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'التفاصيل مطلوبة' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('إرسال الطلب'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  mockEmployeeProfile['name']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mockEmployeeProfile['department']!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _profileTile('الرقم الوظيفي', mockEmployeeProfile['employeeId']!),
              const Divider(height: 1),
              _profileTile('القسم', mockEmployeeProfile['department']!),
              const Divider(height: 1),
              _profileTile('المدير المباشر', mockEmployeeProfile['manager']!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileTile(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusTrackerSection extends StatelessWidget {
  final List<EmployeeRequest> requests;

  const _StatusTrackerSection({required this.requests});

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.submitted:
        return AppColors.info;
      case RequestStatus.inReview:
        return AppColors.warning;
      case RequestStatus.approved:
        return AppColors.success;
      case RequestStatus.rejected:
        return AppColors.statusBroken;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('لا توجد طلبات سابقة'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = requests[index];
        final color = _statusColor(req.status);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      req.id,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        RequestStatusExtension(req.status).label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  req.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${req.category} · أُرسل بتاريخ ${req.dateSubmitted}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
