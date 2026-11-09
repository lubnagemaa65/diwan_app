import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/asset_item.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/assets_provider.dart';
import 'asset_details_screen.dart';
import 'computer_form_screen.dart';
import 'printer_form_screen.dart';

class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key});

  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetsProvider>().loadAssets();
    });
  }

  Future<void> _showAddChooser(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.computer_rounded, color: AppColors.primary),
              title: const Text('إضافة حاسوب جديد'),
              onTap: () => Navigator.of(ctx).pop('computer'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.print_rounded, color: AppColors.primary),
              title: const Text('إضافة طابعة جديدة'),
              onTap: () => Navigator.of(ctx).pop('printer'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;

    if (choice == 'computer') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ComputerFormScreen()));
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PrinterFormScreen()));
    }
  }

  Future<void> _confirmDelete(BuildContext context, AssetItem asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الأصل'),
        content: Text('هل أنت متأكد من حذف "${asset.code}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<AssetsProvider>();
    final success = asset.computer != null
        ? await provider.deleteComputer(asset.id)
        : await provider.deletePrinter(asset.id);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _showStatusDialog(BuildContext context, AssetItem asset) async {
    AssetStatus selected = asset.status;
    final result = await showDialog<AssetStatus>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('تحديث حالة ${asset.code}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AssetStatus.values
                .where((s) => s != AssetStatus.unknown)
                .map((s) {
              return RadioListTile<AssetStatus>(
                value: s,
                groupValue: selected,
                title: Text(s.name),
                onChanged: (v) => setState(() => selected = v ?? selected),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(selected),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    final provider = context.read<AssetsProvider>();
    final payload = {'status': result.name};
    final success = asset.computer != null
        ? await provider.updateComputer(asset.id, payload)
        : await provider.updatePrinter(asset.id, payload);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetsProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.isAdmin || auth.isTechnician;

    return Scaffold(
      appBar: AppBar(title: const Text(' تقرير طلبات الصيانة')),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddChooser(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<AssetsProvider>().loadAssets(),
        child: Column(
          children: [
            _buildSearchAndFilters(context, provider),
            Expanded(child: _buildBody(context, provider, canManage)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, AssetsProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'بحث',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: provider.setSearchQuery,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(context,
                    label: 'الكل',
                    selected: provider.typeFilter == 'all',
                    onTap: () => provider.setTypeFilter('all')),
                _filterChip(context,
                    label: 'الحواسيب',
                    selected: provider.typeFilter == 'computer',
                    onTap: () => provider.setTypeFilter('computer')),
                _filterChip(context,
                    label: 'الطابعات',
                    selected: provider.typeFilter == 'printer',
                    onTap: () => provider.setTypeFilter('printer')),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: AppColors.divider),
                const SizedBox(width: 8),
                _filterChip(context,
                    label: 'نشط',
                    selected: provider.statusFilter == 'active',
                    onTap: () => provider.setStatusFilter(
                        provider.statusFilter == 'active' ? 'all' : 'active')),
                _filterChip(context,
                    label: 'معطل',
                    selected: provider.statusFilter == 'broken',
                    onTap: () => provider.setStatusFilter(
                        provider.statusFilter == 'broken' ? 'all' : 'broken')),
                _filterChip(context,
                    label: 'تحت الصيانة',
                    selected: provider.statusFilter == 'underMaintenance',
                    onTap: () => provider.setStatusFilter(
                        provider.statusFilter == 'underMaintenance'
                            ? 'all'
                            : 'underMaintenance')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context,
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        ),
        side:
            BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AssetsProvider provider, bool canManage) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return ErrorStateWidget(
            message: provider.errorMessage,
            onRetry: () => provider.loadAssets());
      case LoadStatus.loaded:
        final assets = provider.filteredAssets;
        if (assets.isEmpty) {
          return const EmptyState(
              message: 'لا توجد أصول مطابقة', icon: Icons.devices_other);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          itemCount: assets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _AssetRow(
            asset: assets[index],
            canManage: canManage,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => AssetDetailsScreen(asset: assets[index])),
            ),
            onEdit: () {
              final asset = assets[index];
              if (asset.computer != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          ComputerFormScreen(existing: asset.computer)),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          PrinterFormScreen(existing: asset.printer)),
                );
              }
            },
            onDelete: () => _confirmDelete(context, assets[index]),
            onMaintenance: () => _showStatusDialog(context, assets[index]),
          ),
        );
    }
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onMaintenance,
  });

  final AssetItem asset;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMaintenance;

  @override
  Widget build(BuildContext context) {
    final isComputer = asset.computer != null;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isComputer ? Icons.computer_rounded : Icons.print_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.code,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 3),
                        Text(
                          [
                            asset.typeLabel,
                            asset.collegeName,
                            asset.employeeName
                          ].where((e) => e != null && e.isNotEmpty).join(' • '),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatusChip.asset(status: asset.status),
                ],
              ),
              if (canManage) ...[
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.build_outlined,
                          size: 19, color: AppColors.actionMaintenance),
                      onPressed: onMaintenance,
                      tooltip: 'تحديث حالة الصيانة',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 19, color: AppColors.actionEdit),
                      onPressed: onEdit,
                      tooltip: 'تعديل',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 19, color: AppColors.error),
                      onPressed: onDelete,
                      tooltip: 'حذف',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
