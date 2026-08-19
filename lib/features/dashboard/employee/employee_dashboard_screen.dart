import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

/// Employee dashboard: submit a request, view profile, track request
/// status.
///
/// FUTURE API WIRING:
///   - Submit request -> POST AppConstants.employeeRequestsEndpoint
///   - Load requests  -> GET  AppConstants.employeeRequestsEndpoint
class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedSection = 0; // 0=New Request, 1=Profile, 2=Status Tracker

  static const _titles = ['New Request', 'My Profile', 'Status Tracker'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_selectedSection],
        role: UserRole.employee,
      ),
      drawer: AppDrawer(
        role: UserRole.employee,
        selectedIndex: _selectedSection,
        onSelect: (i) => setState(() => _selectedSection = i),
      ),
      body: IndexedStack(
        index: _selectedSection,
        children: const [
          _NewRequestForm(),
          _ProfileSection(),
          _StatusTrackerSection(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedSection,
        onDestinationSelected: (i) => setState(() => _selectedSection = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded),
              label: 'New'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
          NavigationDestination(
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline_rounded),
              label: 'Tracker'),
        ],
      ),
    );
  }
}

class _NewRequestForm extends StatefulWidget {
  const _NewRequestForm();

  @override
  State<_NewRequestForm> createState() => _NewRequestFormState();
}

class _NewRequestFormState extends State<_NewRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  String _category = 'Facilities';
  bool _submitting = false;

  static const _categories = ['Facilities', 'Equipment', 'IT', 'Access'];

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // ---------------------------------------------------------------
    // MOCK: simulate submission latency
    // ---------------------------------------------------------------
    await Future.delayed(const Duration(milliseconds: 800));

    // ---------------------------------------------------------------
    // FUTURE REAL API CALL:
    // ---------------------------------------------------------------
    // final response = await http.post(
    //   Uri.parse(AppConstants.employeeRequestsEndpoint),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'subject': _subjectController.text,
    //     'category': _category,
    //     'details': _detailsController.text,
    //   }),
    // );

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request submitted successfully.'),
        backgroundColor: AppColors.success,
      ),
    );
    _subjectController.clear();
    _detailsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Submit a new request',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(hintText: 'e.g. New keyboard'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe your request...',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Details are required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(mockEmployeeProfile['name']!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(mockEmployeeProfile['department']!,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _profileTile('Employee ID', mockEmployeeProfile['employeeId']!),
              const Divider(height: 1),
              _profileTile('Department', mockEmployeeProfile['department']!),
              const Divider(height: 1),
              _profileTile('Manager', mockEmployeeProfile['manager']!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusTrackerSection extends StatelessWidget {
  const _StatusTrackerSection();

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.submitted:
        return AppColors.info;
      case RequestStatus.inReview:
        return AppColors.warning;
      case RequestStatus.approved:
        return AppColors.success;
      case RequestStatus.rejected:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mockEmployeeRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = mockEmployeeRequests[index];
        final color = _statusColor(req.status);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(req.id,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.status.label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(req.subject,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${req.category} · Submitted ${req.dateSubmitted}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
