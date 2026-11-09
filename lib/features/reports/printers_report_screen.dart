import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart' show AssetStatus;
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../models/printer_model.dart';
import '../assets/data/assets_repository.dart';
import 'report_screen.dart';

/// تقرير الطابعات: لا يوجد endpoint مخصص للتقارير في الباك اند،
/// لذلك نجلب قائمة الطابعات ونحسب الإحصائيات داخل التطبيق.
class PrintersReportScreen extends StatefulWidget {
  const PrintersReportScreen({super.key, this.repository});

  /// اختياري (للاختبار أو الحقن). إن لم يُمرَّر يُنشأ واحد افتراضي.
  final AssetsRepository? repository;

  @override
  State<PrintersReportScreen> createState() => _PrintersReportScreenState();
}

class _PrintersReportScreenState extends State<PrintersReportScreen> {
  late final AssetsRepository _repo;
  List<PrinterModel>? _printers; // null = جاري التحميل

  @override
  void initState() {
    super.initState();
    // استخدم الـ Dio الافتراضي المتوفر في المشروع. إذا كان اسم الـ client مختلفًا
    // في مشروعك، عدّل هذا السطر في هذا الملف فقط.
    _repo = widget.repository ?? AssetsRepository(dio: ApiClient.instance.dio);
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.fetchPrinters();
      if (!mounted) return;
      setState(() => _printers = data);
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('تعذّر تحميل التقرير');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _printers = const []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final printers = _printers;
    final loading = printers == null;

    String v(int Function() count) => loading ? '…' : '${count()}';

    final list = printers ?? const <PrinterModel>[];

    return ReportScreen(
      route: '/reports/printers',
      title: 'تقرير الطابعات',
      stats: [
        ReportStat('إجمالي الطابعات', v(() => list.length), AppColors.primary),
        ReportStat(
            'تعمل',
            v(() => list.where((p) => p.status == AssetStatus.active).length),
            AppColors.success),
        ReportStat(
            'بحاجة صيانة',
            v(() => list
                .where((p) => p.status == AssetStatus.underMaintenance)
                .length),
            AppColors.warning),
        ReportStat(
            'معطّلة',
            v(() => list.where((p) => p.status == AssetStatus.broken).length),
            AppColors.error),
      ],
    );
  }
}
