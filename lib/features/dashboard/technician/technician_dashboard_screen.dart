import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

/// شاشة الكتب الصادرة والواردة.
///
/// FUTURE API WIRING:
///   - Load books -> GET AppConstants.maintenanceTasksEndpoint
///   - Update status -> PUT/PATCH AppConstants.maintenanceTasksEndpoint/{id}
///   - Create book  -> POST AppConstants.maintenanceTasksEndpoint
class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  int _selectedSection = 0; // 0 = الكتب الصادرة والواردة، 1 = سجل الكتب

  // نسخة محلية قابلة للتعديل لتحديث الواجهة فورًا عند تبديل الحالة أو الإضافة.
  // FUTURE: يجب أن تُحمَّل هذه القائمة من مستودع بيانات حقيقي، وتحدَّث
  // بشكل متفائل في الواجهة قبل تأكيد الحفظ عبر طلب PATCH/POST.
  late List<MaintenanceTask> _tasks;

  static const List<String> _priorities = ['عالي', 'متوسط', 'منخفض'];
  static const List<String> _sectionTitles = [
    'الكتب الصادرة والواردة',
    'سجل الكتب',
  ];

  @override
  void initState() {
    super.initState();
    _tasks = [];
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
      builder: (context) => _BookDetailSheet(
        task: task,
        onStatusChanged: (status) => _updateStatus(task, status),
      ),
    );
  }

  Future<void> _openAddBookDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final dueDateController = TextEditingController();
    String selectedPriority = _priorities[1]; // متوسط كافتراضي

    final created = await showDialog<MaintenanceTask>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة كتاب جديد'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('عنوان الكتاب',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                            hintText: 'مثال: كتاب صادر - طلب صيانة'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'هذا الحقل مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const Text('الجهة / الموقع',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                            hintText: 'مثال: المبنى أ / الطابق 2'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'هذا الحقل مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const Text('تاريخ الكتاب / الإنجاز',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: dueDateController,
                        decoration:
                            const InputDecoration(hintText: 'مثال: 2026/09/01'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'هذا الحقل مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const Text('الأولوية',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _priorities.map((p) {
                          final selected = selectedPriority == p;
                          return ChoiceChip(
                            label: Text(p),
                            selected: selected,
                            onSelected: (_) =>
                                setDialogState(() => selectedPriority = p),
                            selectedColor:
                                _priorityColor(p).withValues(alpha: 0.18),
                            labelStyle: TextStyle(
                              color: selected
                                  ? _priorityColor(p)
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? _priorityColor(p)
                                  : AppColors.darkSurface,
                            ),
                            backgroundColor: Colors.transparent,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final newTask = MaintenanceTask(
                      id: 'WO-${1000 + _tasks.length + 50}',
                      title: titleController.text.trim(),
                      location: locationController.text.trim(),
                      priority: selectedPriority,
                      dueDate: dueDateController.text.trim(),
                      status: TaskStatus.open,
                    );
                    Navigator.pop(context, newTask);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    // ---------------------------------------------------------------
    // FUTURE REAL API CALL:
    // ---------------------------------------------------------------
    // final response = await http.post(
    //   Uri.parse(AppConstants.maintenanceTasksEndpoint),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'title': newTask.title,
    //     'location': newTask.location,
    //     'priority': newTask.priority,
    //     'dueDate': newTask.dueDate,
    //   }),
    // );

    if (created != null) {
      setState(() => _tasks = [created, ..._tasks]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _sectionTitles[_selectedSection],
        role: UserRole.technician,
        bottom: const TabBar(
          tabs: [
            Tab(text: 'One'),
            Tab(text: 'Two'),
          ],
        ),
      ),
      drawer: AppDrawer(
        role: UserRole.technician,
        selectedIndex: _selectedSection,
        onSelect: (i) => setState(() => _selectedSection = i),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBookDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة كتاب جديد'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _BookCard(
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
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'الكتب'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'السجل'),
        ],
      ),
    );
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'عالي':
      return AppColors.statusBroken;
    case 'متوسط':
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

enum TaskStatus {
  open('مفتوح'),
  inProgress('قيد التنفيذ'),
  completed('مكتمل');

  const TaskStatus(this.label);
  final String label;
}

class MaintenanceTask {
  final String id;
  final String title;
  final String location;
  final String priority;
  final String dueDate;
  TaskStatus status;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.location,
    required this.priority,
    required this.dueDate,
    required this.status,
  });
}

class _BookCard extends StatelessWidget {
  final MaintenanceTask task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onTap;

  const _BookCard({
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
                  // شارة الأولوية المختارة تظهر على بطاقة الكتاب.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          _priorityColor(task.priority).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'الأولوية: ${task.priority}',
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
              const SizedBox(height: 2),
              Text('تاريخ الكتاب/الإنجاز: ${task.dueDate}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              // شرائح تبديل الحالة.
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
                          : AppColors.darkSurface,
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

class _BookDetailSheet extends StatelessWidget {
  final MaintenanceTask task;
  final ValueChanged<TaskStatus> onStatusChanged;

  const _BookDetailSheet({
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
                color: AppColors.darkSurface,
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
          _detailRow(Icons.location_on_outlined, 'الجهة/الموقع', task.location),
          _detailRow(
              Icons.event_outlined, 'تاريخ الكتاب/الإنجاز', task.dueDate),
          _detailRow(Icons.priority_high_rounded, 'الأولوية', task.priority),
          _detailRow(Icons.flag_outlined, 'الحالة', task.status.label),
          const SizedBox(height: 20),
          const Text('تحديث الحالة',
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
