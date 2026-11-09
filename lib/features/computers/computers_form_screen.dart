import 'package:flutter/material.dart';
import 'package:university_assets_app/core/constants/app_constants.dart'
    show AssetStatus;
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/core/theme/app_colors.dart';
import 'package:university_assets_app/core/utils/validators.dart';
import 'package:university_assets_app/core/widgets/custom_button.dart';
import 'package:university_assets_app/core/widgets/custom_text_field.dart';
import 'package:university_assets_app/core/widgets/loading_indicator.dart';
import 'package:university_assets_app/models/college_model.dart';
import 'package:university_assets_app/models/computer_model.dart';
import 'package:university_assets_app/models/employee_model.dart';

const _diskTypes = ['SATA', 'IDE'];
const _graphicsCards = {'INTEGRATED': 'مدمج', 'SEPARATE': 'منفصل'};

class ComputerFormScreen extends StatefulWidget {
  const ComputerFormScreen({super.key, this.existing});
  final ComputerModel? existing;

  @override
  State<ComputerFormScreen> createState() => _ComputerFormScreenState();
}

class _ComputerFormScreenState extends State<ComputerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _processorController;
  late final TextEditingController _motherboardController;
  late final TextEditingController _diskSpaceController;
  late final TextEditingController _ramController;

  ComputerType _type = ComputerType.desktop;
  AssetStatus _status = AssetStatus.active;
  String _diskType = _diskTypes.first;
  String _graphicsCard = _graphicsCards.keys.first;
  String? _collegeId;
  String? _employeeId;

  List<CollegeModel>? _colleges;
  List<EmployeeModel> _employees = [];
  bool _loadingEmployees = false;
  String? _loadError;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _processorController = TextEditingController(text: e?.processor ?? '');
    _motherboardController = TextEditingController(text: e?.motherboard ?? '');
    _diskSpaceController = TextEditingController(text: e?.diskSize ?? '');
    _ramController = TextEditingController(text: e?.ram ?? '');
    _type = e?.type ?? ComputerType.desktop;
    _status = e?.status ?? AssetStatus.active;
    _diskType =
        (e?.diskType != null && _diskTypes.contains(e!.diskType!.toUpperCase()))
            ? e.diskType!.toUpperCase()
            : _diskTypes.first;
    _graphicsCard = (e?.graphicsCard != null &&
            _graphicsCards.containsKey(e!.graphicsCard!.toUpperCase()))
        ? e.graphicsCard!.toUpperCase()
        : _graphicsCards.keys.first;
    _collegeId = e?.collegeId;
    _employeeId = e?.employeeId;
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    try {
      final data = await CollegeService.list();
      if (!mounted) return;
      setState(() => _colleges = data);
      if (_collegeId != null) _loadEmployees(_collegeId!);
    } on ApiException catch (ex) {
      if (!mounted) return;
      setState(() => _loadError = ex.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'تعذّر تحميل قائمة الكليات');
    }
  }

  Future<void> _loadEmployees(String collegeId) async {
    setState(() {
      _loadingEmployees = true;
      _employees = [];
    });
    try {
      final data = await EmployeeService.list(collegeId: collegeId);
      if (!mounted) return;
      setState(() {
        _employees = data;
        // إن كان الموظف المختار سابقاً غير ضمن موظفي الكلية الجديدة، نلغي اختياره
        if (_employeeId != null && !data.any((emp) => emp.id == _employeeId)) {
          _employeeId = null;
        }
      });
    } on ApiException catch (ex) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ex.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _processorController.dispose();
    _motherboardController.dispose();
    _diskSpaceController.dispose();
    _ramController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _collegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يجب اختيار الكلية'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final model = ComputerModel(
        id: widget.existing?.id ?? '',
        code: widget.existing?.code ?? '',
        type: _type,
        collegeId: _isEditing ? widget.existing!.collegeId : _collegeId,
        employeeId: _employeeId,
        processor: _processorController.text.trim(),
        motherboard: _motherboardController.text.trim(),
        diskType: _diskType,
        diskSize: _diskSpaceController.text.trim(),
        ram: _ramController.text.trim(),
        graphicsCard: _graphicsCard,
        status: _status,
      );

      if (_isEditing) {
        await ComputerService.update(model);
      } else {
        await ComputerService.create(model);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تحديث الحاسوب' : 'تمت إضافة الحاسوب'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'تعديل الحاسوب' : 'إضافة حاسوب جديد')),
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: _loadColleges,
                        child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
            )
          : _colleges == null
              ? const LoadingIndicator(message: 'جاري تحميل الكليات...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text('كود الحاسوب: ${widget.existing!.code}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        DropdownButtonFormField<ComputerType>(
                          initialValue: _type,
                          decoration:
                              const InputDecoration(labelText: 'نوع الجهاز *'),
                          items: const [
                            DropdownMenuItem(
                                value: ComputerType.desktop,
                                child: Text('مكتبي')),
                            DropdownMenuItem(
                                value: ComputerType.laptop,
                                child: Text('محمول')),
                          ],
                          onChanged: (v) =>
                              setState(() => _type = v ?? ComputerType.desktop),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _processorController,
                          label: 'المعالج *',
                          prefixIcon: Icons.memory_outlined,
                          validator: (v) => Validators.required(v),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _motherboardController,
                          label: 'اللوحة الأم *',
                          prefixIcon: Icons.developer_board_outlined,
                          validator: (v) => Validators.required(v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _diskType,
                          decoration:
                              const InputDecoration(labelText: 'نوع القرص *'),
                          items: [
                            for (final t in _diskTypes)
                              DropdownMenuItem(value: t, child: Text(t)),
                          ],
                          onChanged: (v) =>
                              setState(() => _diskType = v ?? _diskTypes.first),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _diskSpaceController,
                          label: 'سعة القرص * (مثال: 512GB)',
                          prefixIcon: Icons.storage_outlined,
                          validator: (v) => Validators.required(v),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _ramController,
                          label: 'نوع الرام * (مثال: DDR4)',
                          prefixIcon: Icons.sd_card_outlined,
                          validator: (v) => Validators.required(v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _graphicsCard,
                          decoration:
                              const InputDecoration(labelText: 'كرت الشاشة *'),
                          items: [
                            for (final entry in _graphicsCards.entries)
                              DropdownMenuItem(
                                  value: entry.key, child: Text(entry.value)),
                          ],
                          onChanged: (v) => setState(() =>
                              _graphicsCard = v ?? _graphicsCards.keys.first),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _collegeId,
                          decoration: InputDecoration(
                            labelText: 'الكلية *',
                            helperText: _isEditing
                                ? 'لا يمكن تغيير الكلية بعد الإنشاء'
                                : null,
                          ),
                          items: [
                            for (final c in _colleges!)
                              DropdownMenuItem(
                                  value: c.id, child: Text(c.name)),
                          ],
                          onChanged: _isEditing
                              ? null
                              : (v) {
                                  setState(() {
                                    _collegeId = v;
                                    _employeeId = null;
                                  });
                                  if (v != null) _loadEmployees(v);
                                },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String?>(
                          initialValue: _employeeId,
                          decoration: InputDecoration(
                            labelText: 'الموظف المسؤول (اختياري)',
                            helperText: _loadingEmployees
                                ? 'جاري تحميل الموظفين...'
                                : null,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('بدون')),
                            for (final emp in _employees)
                              DropdownMenuItem(
                                  value: emp.id, child: Text(emp.fullName)),
                          ],
                          onChanged: (_collegeId == null ||
                                  _isEditing &&
                                      widget.existing!.collegeId == null)
                              ? null
                              : (v) => setState(() => _employeeId = v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<AssetStatus>(
                          initialValue: _status,
                          decoration:
                              const InputDecoration(labelText: 'الحالة *'),
                          items: const [
                            DropdownMenuItem(
                                value: AssetStatus.active, child: Text('يعمل')),
                            DropdownMenuItem(
                                value: AssetStatus.underMaintenance,
                                child: Text('بحاجة صيانة')),
                            DropdownMenuItem(
                                value: AssetStatus.broken,
                                child: Text('معطّل')),
                          ],
                          onChanged: (v) =>
                              setState(() => _status = v ?? AssetStatus.active),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('إلغاء'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                label: _isEditing ? 'حفظ' : 'إضافة',
                                isLoading: _submitting,
                                onPressed: _submit,
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
