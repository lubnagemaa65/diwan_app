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
import 'package:university_assets_app/models/printer_model.dart';

class PrinterFormScreen extends StatefulWidget {
  const PrinterFormScreen({super.key, this.existing});
  final PrinterModel? existing;

  @override
  State<PrinterFormScreen> createState() => _PrinterFormScreenState();
}

class _PrinterFormScreenState extends State<PrinterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeController;
  AssetStatus _status = AssetStatus.active;
  String? _collegeId;

  List<CollegeModel>? _colleges; // null = جاري التحميل
  String? _loadError;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.existing?.type ?? '');
    _status = widget.existing?.status ?? AssetStatus.active;
    _collegeId = widget.existing?.collegeId;
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    try {
      final data = await CollegeService.list();
      if (!mounted) return;
      setState(() => _colleges = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'تعذّر تحميل قائمة الكليات');
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
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
      if (_isEditing) {
        final updated = PrinterModel(
          id: widget.existing!.id,
          code: widget.existing!.code,
          type: _typeController.text.trim(),
          collegeId: widget.existing!.collegeId,
          status: _status,
        );
        await PrinterService.update(updated);
      } else {
        final created = PrinterModel(
          id: '',
          code: '',
          type: _typeController.text.trim(),
          collegeId: _collegeId,
          status: _status,
        );
        await PrinterService.create(created);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تحديث الطابعة' : 'تمت إضافة الطابعة'),
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
          title: Text(_isEditing ? 'تعديل الطابعة' : 'إضافة طابعة جديدة')),
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
                            child: Text('كود الطابعة: ${widget.existing!.code}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        CustomTextField(
                          controller: _typeController,
                          label: 'نوع الطابعة * (مثال: ليزر، نافثة للحبر)',
                          prefixIcon: Icons.print_outlined,
                          validator: (v) => Validators.required(v),
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
                              : (v) => setState(() => _collegeId = v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<AssetStatus>(
                          initialValue: _status,
                          decoration:
                              const InputDecoration(labelText: 'الحالة *'),
                          items: const [
                            DropdownMenuItem(
                                value: AssetStatus.active, child: Text('تعمل')),
                            DropdownMenuItem(
                                value: AssetStatus.underMaintenance,
                                child: Text('بحاجة صيانة')),
                            DropdownMenuItem(
                                value: AssetStatus.broken,
                                child: Text('معطّلة')),
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
