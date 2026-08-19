/// Static mock data powering the dashboards.
///
/// FUTURE: each of these lists should instead be populated by a
/// `DashboardRepository` (mirroring `AuthRepository`'s pattern) that calls
/// `http.get(AppConstants.xEndpoint)` and parses the JSON response into
/// the same model shapes used here.

// ---------------------------------------------------------------------
// Admin dashboard mock data
// ---------------------------------------------------------------------
class AdminMetric {
  final String label;
  final String value;
  final String trend; // e.g. "+4.2%"
  const AdminMetric(this.label, this.value, this.trend);
}

const List<AdminMetric> mockAdminMetrics = [
  AdminMetric('Total Users', '248', '+3.1%'),
  AdminMetric('Open Work Orders', '17', '-5.0%'),
  AdminMetric('Pending Requests', '9', '+1.2%'),
  AdminMetric('Assets Tracked', '532', '+0.4%'),
];

class ManagedUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool active;
  const ManagedUser(this.id, this.name, this.email, this.role, this.active);
}

const List<ManagedUser> mockManagedUsers = [
  ManagedUser('usr_002', 'Maintenance Tech', 'technicanusertest@local.com',
      'Technician', true),
  ManagedUser(
      'usr_003', 'Staff Employee', 'emptest@local', 'Employee', true),
  ManagedUser('usr_004', 'Dana Reyes', 'dana.reyes@local.com', 'Employee',
      true),
  ManagedUser('usr_005', 'Marcus Lee', 'marcus.lee@local.com', 'Technician',
      false),
];

const List<String> mockSystemSettingsLinks = [
  'General Settings',
  'Roles & Permissions',
  'Notification Preferences',
  'Integrations',
  'Audit Log',
];

// ---------------------------------------------------------------------
// Technician dashboard mock data
// ---------------------------------------------------------------------
enum TaskStatus { open, inProgress, completed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

class MaintenanceTask {
  final String id;
  final String title;
  final String location;
  final String priority; // Low / Medium / High
  TaskStatus status;
  MaintenanceTask({
    required this.id,
    required this.title,
    required this.location,
    required this.priority,
    required this.status,
  });
}

final List<MaintenanceTask> mockMaintenanceTasks = [
  MaintenanceTask(
    id: 'WO-1042',
    title: 'HVAC unit not cooling — 3rd floor',
    location: 'Building A / Floor 3',
    priority: 'High',
    status: TaskStatus.inProgress,
  ),
  MaintenanceTask(
    id: 'WO-1043',
    title: 'Replace flickering hallway lights',
    location: 'Building B / Floor 1',
    priority: 'Medium',
    status: TaskStatus.open,
  ),
  MaintenanceTask(
    id: 'WO-1039',
    title: 'Fix leaking faucet — break room',
    location: 'Building A / Floor 2',
    priority: 'Low',
    status: TaskStatus.completed,
  ),
  MaintenanceTask(
    id: 'WO-1044',
    title: 'Elevator inspection overdue',
    location: 'Building A / Lobby',
    priority: 'High',
    status: TaskStatus.open,
  ),
];

// ---------------------------------------------------------------------
// Employee dashboard mock data
// ---------------------------------------------------------------------
enum RequestStatus { submitted, inReview, approved, rejected }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.submitted:
        return 'Submitted';
      case RequestStatus.inReview:
        return 'In Review';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }
}

class EmployeeRequest {
  final String id;
  final String subject;
  final String category;
  final RequestStatus status;
  final String dateSubmitted;
  const EmployeeRequest({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.dateSubmitted,
  });
}

const List<EmployeeRequest> mockEmployeeRequests = [
  EmployeeRequest(
    id: 'REQ-2201',
    subject: 'New monitor for workstation',
    category: 'Equipment',
    status: RequestStatus.inReview,
    dateSubmitted: 'Aug 12, 2026',
  ),
  EmployeeRequest(
    id: 'REQ-2198',
    subject: 'Office AC too cold',
    category: 'Facilities',
    status: RequestStatus.approved,
    dateSubmitted: 'Aug 08, 2026',
  ),
  EmployeeRequest(
    id: 'REQ-2190',
    subject: 'Parking access badge replacement',
    category: 'Access',
    status: RequestStatus.rejected,
    dateSubmitted: 'Jul 29, 2026',
  ),
];

const Map<String, String> mockEmployeeProfile = {
  'name': 'Staff Employee',
  'department': 'Operations',
  'employeeId': 'EMP-0456',
  'manager': 'Dana Reyes',
};
