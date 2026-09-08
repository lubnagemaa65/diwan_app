import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/asset_item.dart';
import '../providers/assets_provider.dart';
import 'asset_details_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('assets_title'))),
      body: RefreshIndicator(
        onRefresh: () => context.read<AssetsProvider>().loadAssets(),
        child: Column(
          children: [
            _buildSearchAndFilters(context, provider),
            Expanded(child: _buildBody(context, provider)),
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
            decoration: InputDecoration(
              hintText: context.tr('search'),
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: provider.setSearchQuery,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  context,
                  label: context.tr('all'),
                  selected: provider.typeFilter == 'all',
                  onTap: () => provider.setTypeFilter('all'),
                ),
                _filterChip(
                  context,
                  label: context.tr('computers'),
                  selected: provider.typeFilter == 'computer',
                  onTap: () => provider.setTypeFilter('computer'),
                ),
                _filterChip(
                  context,
                  label: context.tr('printers'),
                  selected: provider.typeFilter == 'printer',
                  onTap: () => provider.setTypeFilter('printer'),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: AppColors.divider),
                const SizedBox(width: 8),
                _filterChip(
                  context,
                  label: context.tr('active'),
                  selected: provider.statusFilter == 'active',
                  onTap: () => provider.setStatusFilter(
                    provider.statusFilter == 'active' ? 'all' : 'active',
                  ),
                ),
                _filterChip(
                  context,
                  label: context.tr('broken'),
                  selected: provider.statusFilter == 'broken',
                  onTap: () => provider.setStatusFilter(
                    provider.statusFilter == 'broken' ? 'all' : 'broken',
                  ),
                ),
                _filterChip(
                  context,
                  label: context.tr('under_maintenance'),
                  selected: provider.statusFilter == 'underMaintenance',
                  onTap: () => provider.setStatusFilter(
                    provider.statusFilter == 'underMaintenance' ? 'all' : 'underMaintenance',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        ),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AssetsProvider provider) {
    switch (provider.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => const _AssetSkeletonCard(),
        );
      case LoadStatus.error:
        return ErrorStateWidget(
          message: provider.errorMessage,
          onRetry: () => provider.loadAssets(),
        );
      case LoadStatus.loaded:
        final assets = provider.filteredAssets;
        if (assets.isEmpty) {
          return EmptyState(message: context.tr('no_assets_found'), icon: Icons.devices_other);
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: assets.length,
          itemBuilder: (context, index) => _AssetCard(asset: assets[index]),
        );
    }
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset});
  final AssetItem asset;

  @override
  Widget build(BuildContext context) {
    final isComputer = asset.assetType.name == 'computer';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AssetDetailsScreen(asset: asset)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isComputer ? Icons.computer_rounded : Icons.print_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.code,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [asset.typeLabel, asset.collegeName].where((e) => e != null && e.isNotEmpty).join(' • '),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusChip.asset(status: asset.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetSkeletonCard extends StatelessWidget {
  const _AssetSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 100, color: AppColors.divider),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 160, color: AppColors.divider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
