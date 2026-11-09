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

  /// متوسط زمن الإصلاح للطلبات "المكتملة" فقط (آخر تعديل - تاريخ الإنشاء).
  /// null إذا لم تتوفر طلبات مكتملة بتواريخ صالحة بعد.
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
    final repairDurations = <Duration>[];
    final repairedDeviceIds = <String>{};

    for (final o in orders) {
      switch (o.status) {
        case MaintenanceStatus.completed:
          completed++;
          repairedDeviceIds.add(o.deviceId);

          final dynamicOrder = o as dynamic;
          final completedAt = dynamicOrder.completedAt ??
              dynamicOrder.updatedAt ??
              dynamicOrder.updatedDate ??
              dynamicOrder.lastUpdatedAt;

          if (o.date != null && completedAt is DateTime) {
            final dur = completedAt.difference(o.date!);
            if (!dur.isNegative) repairDurations.add(dur);
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

    Duration? avg;
    if (repairDurations.isNotEmpty) {
      final totalMs =
          repairDurations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
      avg = Duration(milliseconds: totalMs ~/ repairDurations.length);
    }

    // عدد الطلبات المُنشأة بكل يوم من آخر 7 أيام (من اليوم قبل 6 أيام إلى اليوم).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7 = List<int>.filled(7, 0);
    for (final o in orders) {
      final d = o.date;
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
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
      averageRepairTime: avg,
      devicesRepairedCount: repairedDeviceIds.length,
      last7DaysCounts: last7,
    );
  }
}
