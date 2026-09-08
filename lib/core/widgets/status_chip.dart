import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// رقاقة حالة موحّدة تُستخدم لعرض حالة الأصل أو طلب الصيانة بلون مناسب
class StatusChip extends StatelessWidget {
  const StatusChip.asset({super.key, required AssetStatus status, this.arabic = true})
      : _label = null,
        _color = null,
        _assetStatus = status,
        _maintenanceStatus = null;

  const StatusChip.maintenance({
    super.key,
    required MaintenanceStatus status,
    this.arabic = true,
  })  : _label = null,
        _color = null,
        _assetStatus = null,
        _maintenanceStatus = status;

  final AssetStatus? _assetStatus;
  final MaintenanceStatus? _maintenanceStatus;
  final String? _label;
  final Color? _color;
  final bool arabic;

  Color _resolveColor() {
    if (_color != null) return _color!;
    if (_assetStatus != null) {
      switch (_assetStatus!) {
        case AssetStatus.active:
          return AppColors.statusActive;
        case AssetStatus.broken:
          return AppColors.statusBroken;
        case AssetStatus.underMaintenance:
          return AppColors.statusMaintenance;
        case AssetStatus.unknown:
          return AppColors.textSecondary;
      }
    }
    if (_maintenanceStatus != null) {
      switch (_maintenanceStatus!) {
        case MaintenanceStatus.pending:
          return AppColors.statusPending;
        case MaintenanceStatus.inProgress:
          return AppColors.statusInProgress;
        case MaintenanceStatus.completed:
          return AppColors.statusCompleted;
        case MaintenanceStatus.cancelled:
          return AppColors.statusCancelled;
        case MaintenanceStatus.unknown:
          return AppColors.textSecondary;
      }
    }
    return AppColors.textSecondary;
  }

  String _resolveLabel() {
    if (_label != null) return _label!;
    if (_assetStatus != null) {
      return arabic ? _assetStatus!.labelAr() : _assetStatus!.labelEn();
    }
    if (_maintenanceStatus != null) {
      return arabic ? _maintenanceStatus!.labelAr() : _maintenanceStatus!.labelEn();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _resolveLabel(),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
