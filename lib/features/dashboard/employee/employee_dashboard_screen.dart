import 'package:flutter/material.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/core/theme/app_colors.dart';
import 'package:university_assets_app/features/auth/models/user_model.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/models/maintenance_order_model.dart';

import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

/// لوحة تحكم الموظف: تقديم طلب صيانة، ومتابعة حالة طلباته.
///
/// ملاحظة هامة: الشاشة القديمة كانت مبنية على مفهوم "طلب عام" بفئات
/// (مرافق/معدات/صلاحيات دخول) غير موجود في الباك اند إطلاقاً. تم استبدالها
/// بما يدعمه الباك اند فعلياً: طلب صيانة (MaintenanceOrder) لحاسوب أو
/// طابعة محددة. كما أن صلاحيات الموظف لا تسمح له باستعراض قائمة الأجهزة
/// (viewDevices)، لذلك يُدخل كود الجهاز يدوياً بدل اختياره من قائمة.
class EmployeeDashboardScreen extends StatelessWidget {
  /// معلومات المستخدم الحالي المسجّل دخوله (من AuthProvider).
  final AppUser currentUser;

  const EmployeeDashboardScreen({super.key, required this.currentUser});

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
            const _StatusTrackerSection(),
            _ProfileSection(currentUser: currentUser),
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
  final _deviceCodeController = TextEditingController();
  final _detailsController = TextEditingController();
  AssetType _deviceType = AssetType.computer;
  String _problemType = 'عتاد'; // عتاد / برمجيات
  bool _submitting = false;

  @override
  void dispose() {
    _deviceCodeController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final order = MaintenanceOrderModel(
      id: '',
      deviceType: _deviceType,
      deviceId: _deviceCodeController.text.trim(),
      problemType: _problemType,
      description: _detailsController.text.trim(),
      status: MaintenanceStatus.pending,
    );

    try {
      await MaintenanceOrderService.create(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب الصيانة بنجاح.'),
          backgroundColor: AppColors.success,
        ),
      );
      _deviceCodeController.clear();
      _detailsController.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
              'تقديم طلب صيانة جديد',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('نوع الجهاز',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<AssetType>(
              initialValue: _deviceType,
              items: const [
                DropdownMenuItem(
                    value: AssetType.computer, child: Text('حاسوب')),
                DropdownMenuItem(
                    value: AssetType.printer, child: Text('طابعة')),
              ],
              onChanged: (v) =>
                  setState(() => _deviceType = v ?? AssetType.computer),
            ),
            const SizedBox(height: 16),
            const Text('كود الجهاز',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _deviceCodeController,
              decoration: const InputDecoration(
                hintText: 'مثال: COL03-PC001 (موجود على ملصق الجهاز)',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'كود الجهاز مطلوب' : null,
            ),
            const SizedBox(height: 16),
            const Text('نوع المشكلة',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _problemType,
              items: const [
                DropdownMenuItem(value: 'عتاد', child: Text('عتاد')),
                DropdownMenuItem(value: 'برمجيات', child: Text('برمجيات')),
              ],
              onChanged: (v) => setState(() => _problemType = v ?? 'عتاد'),
            ),
            const SizedBox(height: 16),
            const Text('تفاصيل المشكلة',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'صِف المشكلة...',
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
  final AppUser currentUser;
  const _ProfileSection({required this.currentUser});

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
                  currentUser.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        // ملاحظة: الرقم الوظيفي والقسم والمدير المباشر كانت بيانات وهمية
        // ثابتة. الباك اند لا يوفر endpoint مباشر لجلب سجل الموظف (Employee)
        // المرتبط بالمستخدم الحالي، لذلك حُذفت بدل عرض بيانات غير حقيقية.
        // لإضافتها لاحقاً: استعلم عن /employees وابحث عن السجل الذي
        // user.email يطابق بريد المستخدم الحالي.
      ],
    );
  }
}

class _StatusTrackerSection extends StatefulWidget {
  const _StatusTrackerSection();

  @override
  State<_StatusTrackerSection> createState() => _StatusTrackerSectionState();
}

class _StatusTrackerSectionState extends State<_StatusTrackerSection> {
  List<MaintenanceOrderModel>? _orders; // null = جاري التحميل
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _orders = null;
      _error = null;
    });
    try {
      // الباك اند يُعيد تلقائياً طلبات الموظف الحالي فقط عند استدعاء هذا
      // الـ endpoint بحساب موظف (EMPLOYEE)، دون الحاجة لأي فلتر إضافي.
      final data = await MaintenanceOrderService.list();
      if (!mounted) return;
      setState(() => _orders = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تحميل الطلبات');
    }
  }

  Color _statusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return AppColors.info;
      case MaintenanceStatus.inProgress:
        return AppColors.warning;
      case MaintenanceStatus.completed:
        return AppColors.success;
      case MaintenanceStatus.cancelled:
        return AppColors.statusBroken;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'معلق';
      case MaintenanceStatus.inProgress:
        return 'قيد التنفيذ';
      case MaintenanceStatus.completed:
        return 'مكتمل';
      case MaintenanceStatus.cancelled:
        return 'ملغى';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    final orders = _orders;
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات سابقة'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = orders[index];
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
                      req.deviceCode ?? req.deviceId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(req.status),
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
                  req.problemType,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  req.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (req.date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'أُرسل بتاريخ ${req.date!.day}/${req.date!.month}/${req.date!.year}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
