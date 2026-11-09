import 'package:flutter/material.dart';
import 'package:university_assets_app/core/network/api_exception.dart';
import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/core/widgets/data_list_screen.dart';
import 'package:university_assets_app/core/widgets/error_state.dart';
import 'package:university_assets_app/core/widgets/loading_indicator.dart';
import 'package:university_assets_app/models/activity_log_model.dart';

/// سجل النشاطات — للقراءة فقط، متصل بالباك اند الحقيقي عبر
/// [ActivityLogService] (تمت إزالة البيانات الوهمية بالكامل).
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<ActivityLogModel>? _logs; // null = جاري التحميل
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _logs = null;
      _error = null;
    });
    try {
      final data = await ActivityLogService.list();
      if (!mounted) return;
      setState(() => _logs = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تحميل سجل النشاطات');
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}  ${two(local.day)}/${two(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: ErrorStateWidget(message: _error!, onRetry: _load));
    }

    final logs = _logs;
    if (logs == null) {
      return const Scaffold(
          body: LoadingIndicator(message: 'جاري تحميل سجل النشاطات...'));
    }

    return DataListScreen(
      route: '/activity-log',
      title: 'سجل النشاطات',
      showActions: false,
      emptyMessage: 'لا توجد نشاطات مسجّلة',
      columns: const [
        ListColumn('الوقت', flex: 2),
        ListColumn('المستخدم', flex: 2),
        ListColumn('الإجراء', flex: 4),
      ],
      rows: [
        for (final log in logs)
          [
            Text(_formatTime(log.timestamp)),
            Text(log.userName.isEmpty ? '—' : log.userName),
            Text(log.action),
          ],
      ],
    );
  }
}
