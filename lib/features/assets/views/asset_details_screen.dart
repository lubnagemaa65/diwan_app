import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/asset_item.dart';
import '../../maintenance/views/maintenance_form_screen.dart';

class AssetDetailsScreen extends StatelessWidget {
  const AssetDetailsScreen({super.key, required this.asset});
  final AssetItem asset;

  @override
  Widget build(BuildContext context) {
    final isComputer = asset.assetType.name == 'computer';
    final computer = asset.computer;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('asset_details'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isComputer ? Icons.computer_rounded : Icons.print_rounded,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      asset.code,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    StatusChip.asset(status: asset.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: context.tr('asset_details'),
              rows: [
                _InfoRow(context.tr('asset_type'), asset.typeLabel),
                _InfoRow(context.tr('college'), asset.collegeName ?? '—'),
                _InfoRow(context.tr('employee'), asset.employeeName ?? '—'),
                if (isComputer && computer != null) ...[
                  _InfoRow(context.tr('processor'), computer.processor ?? '—'),
                  _InfoRow(context.tr('ram'), computer.ram ?? '—'),
                  _InfoRow(context.tr('disk'), computer.diskLabel.isEmpty ? '—' : computer.diskLabel),
                ],
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: context.tr('new_maintenance_request'),
              icon: Icons.build_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MaintenanceFormScreen(preselectedAsset: asset),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label, style: const TextStyle(color: AppColors.textSecondary)),
                    Flexible(
                      child: Text(
                        r.value,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
