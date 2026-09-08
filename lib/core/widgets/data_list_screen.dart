import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_shell.dart';

class ListColumn {
  final String header;
  final int flex;
  const ListColumn(this.header, {this.flex = 1});
}

/// Generic table-list screen shared by Users, Colleges, Employees,
/// Computers, Printers, Maintenance Requests, and Activity Log — the
/// screenshots showed this exact layout (title top-right, blue "add"
/// button top-left, header row, bordered data rows, optional footer),
/// so it's built once here and reused everywhere for consistency and
/// easy future editing.
///
/// [columns] / each row's cell list are given in logical RTL reading
/// order (first = rightmost on screen, matching Arabic reading order);
/// the actions column (edit/delete) is appended automatically at the end,
/// which renders at the visual left — matching the screenshots.
class DataListScreen extends StatelessWidget {
  final String route;
  final String title;
  final String? addLabel;
  final VoidCallback? onAdd;
  final List<ListColumn> columns;
  final List<List<Widget>> rows;
  final bool showActions;
  final void Function(int rowIndex)? onEdit;
  final void Function(int rowIndex)? onDelete;
  final String? footer;
  final String? emptyMessage;

  const DataListScreen({
    super.key,
    required this.route,
    required this.title,
    required this.columns,
    required this.rows,
    this.addLabel,
    this.onAdd,
    this.showActions = true,
    this.onEdit,
    this.onDelete,
    this.footer,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: route,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (addLabel != null)
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(addLabel!),
                    ),
                  const Spacer(),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(emptyMessage ?? 'لا توجد بيانات لعرضها',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.darkSurface),
                        borderRadius: BorderRadius.circular(4)),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _HeaderRow(
                              columns: columns, showActions: showActions),
                          for (int i = 0; i < rows.length; i++)
                            _DataRow(
                              cells: rows[i],
                              flexes: columns.map((c) => c.flex).toList(),
                              showActions: showActions,
                              onEdit: onEdit == null ? null : () => onEdit!(i),
                              onDelete:
                                  onDelete == null ? null : () => onDelete!(i),
                              isLast: i == rows.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (footer != null) ...[
                const SizedBox(height: 16),
                Center(
                    child: Text(footer!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<ListColumn> columns;
  final bool showActions;
  const _HeaderRow({required this.columns, required this.showActions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.textSecondary))),
      child: Row(
        children: [
          if (showActions)
            const SizedBox(
              width: 90,
              child: Text('إجراءات',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
          for (final c in columns)
            Expanded(
              flex: c.flex,
              child: Text(c.header,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final List<Widget> cells;
  final List<int> flexes;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isLast;

  const _DataRow({
    required this.cells,
    required this.flexes,
    required this.showActions,
    required this.onEdit,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.darkSurface))),
      child: Row(
        children: [
          if (showActions)
            SizedBox(
              width: 90,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.statusBroken),
                    onPressed: onDelete,
                    tooltip: 'حذف',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 19, color: AppColors.textSecondary),
                    onPressed: onEdit,
                    tooltip: 'تعديل',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes[i],
              child: Center(child: cells[i]),
            ),
        ],
      ),
    );
  }
}
