import '../core/constants/app_constants.dart';
import 'computer_model.dart';
import 'printer_model.dart';

/// غلاف موحّد (Unified wrapper) يجمع الحواسيب والطابعات في نموذج واحد
/// لعرضهما بسهولة في قائمة الأصول الرئيسية
class AssetItem {
  final AssetType assetType;
  final String id;
  final String code;
  final String typeLabel;
  final String? collegeName;
  final String? employeeName;
  final AssetStatus status;
  final ComputerModel? computer;
  final PrinterModel? printer;

  AssetItem._({
    required this.assetType,
    required this.id,
    required this.code,
    required this.typeLabel,
    this.collegeName,
    this.employeeName,
    required this.status,
    this.computer,
    this.printer,
  });

  factory AssetItem.fromComputer(ComputerModel c) {
    return AssetItem._(
      assetType: AssetType.computer,
      id: c.id,
      code: c.code,
      typeLabel: c.type.labelAr(),
      collegeName: c.collegeName,
      employeeName: c.employeeName,
      status: c.status,
      computer: c,
    );
  }

  factory AssetItem.fromPrinter(PrinterModel p) {
    return AssetItem._(
      assetType: AssetType.printer,
      id: p.id,
      code: p.code,
      typeLabel: p.type ?? 'طابعة',
      collegeName: p.collegeName,
      employeeName: p.employeeName,
      status: p.status,
      printer: p,
    );
  }
}
