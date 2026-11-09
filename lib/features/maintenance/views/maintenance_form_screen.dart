import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/asset_item.dart';
import '../../../models/employee_model.dart';
import '../../assets/providers/assets_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';

/// شاشة إنشاء طلب صيانة جديد.
/// إن مُرِّر [preselectedAsset] (قادمًا من شاشة تفاصيل الأصل) يتم تعبئة الجهاز مسبقًا.
class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({super.key, this.preselectedAsset});
  final AssetItem? preselectedAsset;

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  AssetItem? _selectedAsset;

  String _problemType = 'hardware';
  static const Map<String, String> _problemTypes = {
    'hardware': 'عتاد',
    'software': 'برمجيات',
  };

  // عند الإنشاء بحساب مدير، الباك اند يتطلب تحديد الموظف مقدّم الطلب
  // (Employee.id) صراحةً؛ للموظف يُتجاهل هذا الحقل تلقائياً في الباك اند.
  List<EmployeeModel>? _employees;
  EmployeeModel? _selectedEmployee;
  String? _employeesError;

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.preselectedAsset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedAsset == null) {
        final provider = context.read<AssetsProvider>();
        if (provider.status == LoadStatus.initial) {
          provider.loadAssets();
        }
      }
      if (context.read<AuthProvider>().isAdmin) {
        _loadEmployees();
      }
    });
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await EmployeeService.list();
      if (!mounted) return;
      setState(() => _employees = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _employeesError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _employeesError = 'تعذّر تحميل قائمة الموظفين');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_selectedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.tr('select_device')),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<MaintenanceProvider>();

    // للمدير: الموظف المختار مطلوب. للموظف: الباك اند يتجاهل requesterId
    // ويستخدم سجله تلقائياً، فلا داعي لإرساله.
    String? requesterId;
    if (auth.isAdmin) {
      if (_selectedEmployee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يجب اختيار الموظف مقدّم الطلب'),
              backgroundColor: AppColors.error),
        );
        return;
      }
      requesterId = _selectedEmployee!.id;
    }

    final success = await provider.submitRequest(
      deviceType: _selectedAsset!.assetType.name,
      deviceId: _selectedAsset!.id,
      problemType: _problemType,
      description: _descriptionController.text.trim(),
      requesterId: requesterId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.tr('success')),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsProvider = context.watch<AssetsProvider>();
    final maintenanceProvider = context.watch<MaintenanceProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('new_maintenance_request'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.isAdmin) ...[
                const Text('الموظف مقدّم الطلب',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_employeesError != null)
                  Text(_employeesError!,
                      style: const TextStyle(color: AppColors.error))
                else if (_employees == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<EmployeeModel>(
                    initialValue: _selectedEmployee,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined)),
                    hint: const Text('اختر الموظف'),
                    items: _employees!
                        .map((emp) => DropdownMenuItem(
                            value: emp, child: Text(emp.fullName)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedEmployee = v),
                  ),
                const SizedBox(height: 20),
              ],
              Text(context.tr('select_device'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (widget.preselectedAsset != null)
                _PreselectedAssetTile(asset: widget.preselectedAsset!)
              else if (assetsProvider.status == LoadStatus.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else
                DropdownButtonFormField<AssetItem>(
                  initialValue: _selectedAsset,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.devices_outlined)),
                  hint: Text(context.tr('select_device')),
                  items: assetsProvider.filteredAssets
                      .map((asset) => DropdownMenuItem(
                            value: asset,
                            child: Text('${asset.code} • ${asset.typeLabel}'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedAsset = value),
                ),
              const SizedBox(height: 20),
              Text(context.tr('problem_type'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _problemTypes.entries.map((entry) {
                  final selected = _problemType == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _problemType = entry.key),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _descriptionController,
                label: context.tr('describe_problem'),
                maxLines: 5,
                validator: (v) => Validators.required(v,
                    message: context.tr('field_required')),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: context.tr('submit_request'),
                isLoading: maintenanceProvider.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreselectedAssetTile extends StatelessWidget {
  const _PreselectedAssetTile({required this.asset});
  final AssetItem asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            asset.assetType.name == 'computer'
                ? Icons.computer_rounded
                : Icons.print_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text('${asset.code} • ${asset.typeLabel}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
