import 'package:university_assets_app/core/network/dio_client.dart';
import 'package:university_assets_app/models/maintenance_order_model.dart';

/// مؤشرات لوحة التحكم، مُحسّبة من بيانات حقيقية (لا يوجد endpoint مخصّص
/// للتقارير بالباك اند، فنجلب القوائم ونحسب منها).
class DashboardStats {
  final int totalComputers;
  final int totalPrinters;
  final int totalDevices;

  final int completedCount;
  final int inProgressCount;
  final int pendingCount;
  final int cancelledCount;
  final int totalOrders;

  /// غير متاح ما دام الخادم لا يسجّل وقت إكمال الطلب.
  /// لا يصلح وقت آخر تعديل بديلاً لأنه قد يتغير بعد الإكمال.
  final Duration? averageRepairTime;

  /// عدد الأجهزة الفريدة (حسب الكود) التي أُصلحت على الأقل مرة.
  final int devicesRepairedCount;

  /// عدد طلبات الصيانة المُنشأة في كل يوم من آخر 7 أيام، من الأقدم للأحدث
  /// (آخر عنصر = اليوم الحالي). للاستخدام برسم بياني بسيط.
  final List<int> last7DaysCounts;

  const DashboardStats({
    required this.totalComputers,
    required this.totalPrinters,
    required this.completedCount,
    required this.inProgressCount,
    required this.pendingCount,
    required this.cancelledCount,
    required this.totalOrders,
    required this.averageRepairTime,
    required this.devicesRepairedCount,
    required this.last7DaysCounts,
  }) : totalDevices = totalComputers + totalPrinters;

  /// نسبة الإنجاز من إجمالي الطلبات (0..1)، للعرض كـ progress أو نسبة مئوية.
  double get completionRate =>
      totalOrders == 0 ? 0 : completedCount / totalOrders;

  /// تنسيق متوسط زمن الإصلاح كنص عربي مختصر (مثال: "3 أيام 4 ساعات").
  String get averageRepairTimeLabel {
    final d = averageRepairTime;
    if (d == null) return '—';
    if (d.inDays >= 1) {
      final hours = d.inHours % 24;
      return hours > 0 ? '${d.inDays} يوم $hours ساعة' : '${d.inDays} يوم';
    }
    if (d.inHours >= 1) return '${d.inHours} ساعة';
    return '${d.inMinutes} دقيقة';
  }
}

class DashboardStatsService {
  DashboardStatsService._();

  static Future<DashboardStats> load() async {
    final results = await Future.wait([
      ComputerService.list(),
      PrinterService.list(),
      MaintenanceOrderService.list(),
    ]);

    final computersCount = results[0].length;
    final printersCount = results[1].length;
    final orders = results[2] as List<MaintenanceOrderModel>;

    var completed = 0, inProgress = 0, pending = 0, cancelled = 0;
    final repairedDeviceIds = <(AssetType, String)>{};

    for (final o in orders) {
      switch (o.status) {
        case MaintenanceStatus.completed:
          completed++;
          if (o.deviceId.trim().isNotEmpty) {
            repairedDeviceIds.add((o.deviceType, o.deviceId));
          }
          break;
        case MaintenanceStatus.inProgress:
          inProgress++;
          break;
        case MaintenanceStatus.pending:
          pending++;
          break;
        case MaintenanceStatus.cancelled:
          cancelled++;
          break;
      }
    }

    // عدد الطلبات المُنشأة بكل يوم من آخر 7 أيام (من اليوم قبل 6 أيام إلى اليوم).
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final last7 = List<int>.filled(7, 0);
    for (final o in orders) {
      final d = o.date?.toLocal();
      if (d == null) continue;
      final day = DateTime.utc(d.year, d.month, d.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < 7) last7[6 - diff]++;
    }

    return DashboardStats(
      totalComputers: computersCount,
      totalPrinters: printersCount,
      completedCount: completed,
      inProgressCount: inProgress,
      pendingCount: pending,
      cancelledCount: cancelled,
      totalOrders: orders.length,
      averageRepairTime: null,
      devicesRepairedCount: repairedDeviceIds.length,
      last7DaysCounts: last7,
    );
  }
}
