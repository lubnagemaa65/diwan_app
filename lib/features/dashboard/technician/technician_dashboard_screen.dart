import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

/// Technician dashboard: maintenance task list with status toggles and a
/// work order detail sheet.
///
/// FUTURE API WIRING:
///   - Load tasks -> GET AppConstants.maintenanceTasksEndpoint
///   - Update status -> PUT/PATCH AppConstants.maintenanceTasksEndpoint/{id}
class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState
    extends State<TechnicianDashboardScreen> {
  int _selectedSection = 0; // 0 = My Tasks, 1 = Work Orders (same list here)

  // Local mutable copy so status toggles can update the UI immediately.
  // FUTURE: this list should come from a repository call and toggles
  // should optimistically update the UI, then confirm via the PATCH call.
  late List<MaintenanceTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = mockMaintenanceTasks;
  }

  void _updateStatus(MaintenanceTask task, TaskStatus newStatus) {
    setState(() => task.status = newStatus);

    // ---------------------------------------------------------------
    // FUTURE REAL API CALL:
    // ---------------------------------------------------------------
    // await http.patch(
    //   Uri.parse('${AppConstants.maintenanceTasksEndpoint}/${task.id}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'status': newStatus.name}),
    // );
  }

  void _openWorkOrderDetail(MaintenanceTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _WorkOrderDetailSheet(
        task: task,
        onStatusChanged: (status) => _updateStatus(task, status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _selectedSection == 0 ? 'My Tasks' : 'Work Orders',
        role: UserRole.technician,
      ),
      drawer: AppDrawer(
        role: UserRole.technician,
        selectedIndex: _selectedSection,
        onSelect: (i) => setState(() => _selectedSection = i),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _TaskCard(
            task: task,
            onStatusChanged: (status) => _updateStatus(task, status),
            onTap: () => _openWorkOrderDetail(task),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedSection,
        onDestinationSelected: (i) => setState(() => _selectedSection = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build_rounded),
              label: 'My Tasks'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Work Orders'),
        ],
      ),
    );
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'High':
      return AppColors.danger;
    case 'Medium':
      return AppColors.warning;
    default:
      return AppColors.info;
  }
}

Color _statusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.open:
      return AppColors.textSecondary;
    case TaskStatus.inProgress:
      return AppColors.warning;
    case TaskStatus.completed:
      return AppColors.success;
  }
}

class _TaskCard extends StatelessWidget {
  final MaintenanceTask task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(task.id,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor(task.priority)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        color: _priorityColor(task.priority),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(task.location,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              // Status toggle — segmented control mirroring web dashboard
              // status pills.
              Wrap(
                spacing: 8,
                children: TaskStatus.values.map((status) {
                  final selected = task.status == status;
                  return ChoiceChip(
                    label: Text(status.label),
                    selected: selected,
                    onSelected: (_) => onStatusChanged(status),
                    selectedColor: _statusColor(status).withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      color: selected
                          ? _statusColor(status)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selected
                          ? _statusColor(status)
                          : AppColors.border,
                    ),
                    backgroundColor: Colors.transparent,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkOrderDetailSheet extends StatelessWidget {
  final MaintenanceTask task;
  final ValueChanged<TaskStatus> onStatusChanged;

  const _WorkOrderDetailSheet({
    required this.task,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(task.id,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(task.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _detailRow(Icons.location_on_outlined, 'Location', task.location),
          _detailRow(Icons.priority_high_rounded, 'Priority', task.priority),
          _detailRow(Icons.flag_outlined, 'Status', task.status.label),
          const SizedBox(height: 20),
          const Text('Update status',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskStatus.values.map((status) {
              final selected = task.status == status;
              return ChoiceChip(
                label: Text(status.label),
                selected: selected,
                onSelected: (_) => onStatusChanged(status),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
