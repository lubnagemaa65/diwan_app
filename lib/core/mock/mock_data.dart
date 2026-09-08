// mock.dart
//
// Static mock data for development/testing.
// This file does NOT connect to a real database or API.
//
// Mock login accounts:
//   Admin:      admintest@local.com / 123456
//   Technician: technicanusertest@local.com / 123456
//   Employee:   emptest@local.com / 123456

// ---------------------------------------------------------------------
// Mock Account
// ---------------------------------------------------------------------

class MockAccount {
  final String email;
  final String password;
  final String name;
  final String role;

  const MockAccount({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });
}

// ---------------------------------------------------------------------
// Mock Login Accounts
// ---------------------------------------------------------------------

const List<MockAccount> mockAccounts = [
  MockAccount(
    email: 'admin@university.edu',
    password: '123456',
    name: '—',
    role: 'مدير',
  ),
  MockAccount(
    email: 'technicanusertest@local.com',
    password: '123456',
    name: 'technicanusertest',
    role: 'فني',
  ),
  MockAccount(
    email: 'admintest@local.com',
    password: '123456',
    name: 'admintest',
    role: 'مدير',
  ),
  MockAccount(
    email: 'emptest@local.com',
    password: '123456',
    name: 'emptest',
    role: 'موظف',
  ),
  MockAccount(
    email: 'ali@gmail.com',
    password: '123456',
    name: 'ali',
    role: 'موظف',
  ),
  MockAccount(
    email: 'maintenance@gmail.com',
    password: '123456',
    name: 'فني صيانة',
    role: 'فني',
  ),
];

// ---------------------------------------------------------------------
// Mock Authentication
// ---------------------------------------------------------------------

MockAccount? authenticateMockUser(
  String email,
  String password,
) {
  final normalizedEmail = email.trim().toLowerCase();

  for (final account in mockAccounts) {
    if (account.email.toLowerCase() == normalizedEmail &&
        account.password == password) {
      return account;
    }
  }

  return null;
}

// ---------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------

class UserRow {
  final String name;
  final String email;
  final String role; // مدير / فني / موظف

  const UserRow(
    this.name,
    this.email,
    this.role,
  );
}

const List<UserRow> mockUsers = [
  UserRow(
    '—',
    'admin@university.edu',
    'مدير',
  ),
  UserRow(
    'technicanusertest',
    'technicanusertest@local.com',
    'فني',
  ),
  UserRow(
    'admintest',
    'admintest@local.com',
    'مدير',
  ),
  UserRow(
    'emptest',
    'emptest@local.com',
    'موظف',
  ),
  UserRow(
    'ali',
    'ali@gmail.com',
    'موظف',
  ),
  UserRow(
    'فني صيانة',
    'maintenance@gmail.com',
    'فني',
  ),
];

// ---------------------------------------------------------------------
// Colleges
// ---------------------------------------------------------------------

class CollegeRow {
  final int number;
  final String name;

  const CollegeRow(
    this.number,
    this.name,
  );
}

const List<CollegeRow> mockColleges = [
  CollegeRow(
    1,
    'مديرية نظم المعلومات',
  ),
  CollegeRow(
    2,
    'كلية السياحة',
  ),
  CollegeRow(
    3,
    'كلية الأداب',
  ),
];

// ---------------------------------------------------------------------
// Employees
// ---------------------------------------------------------------------

class EmployeeRow {
  final String name;
  final String college;
  final String position;
  final String phone;

  const EmployeeRow(
    this.name,
    this.college,
    this.position,
    this.phone,
  );
}

const List<EmployeeRow> mockEmployees = [
  EmployeeRow(
    'محمد سامي',
    'مديرية نظم المعلومات',
    'مبرمج',
    '0999111222',
  ),
  EmployeeRow(
    'لينا خالد',
    'كلية السياحة',
    'سكرتيرة',
    '0999333444',
  ),
  EmployeeRow(
    'يوسف عمر',
    'كلية الأداب',
    'محاضر',
    '0999555666',
  ),
];

// ---------------------------------------------------------------------
// Computers
// ---------------------------------------------------------------------

class ComputerRow {
  final String name;
  final String college;
  final String status; // يعمل / بحاجة صيانة / خارج الخدمة

  const ComputerRow(
    this.name,
    this.college,
    this.status,
  );
}

const List<ComputerRow> mockComputers = [
  ComputerRow(
    'PC-101',
    'مديرية نظم المعلومات',
    'يعمل',
  ),
  ComputerRow(
    'PC-102',
    'كلية السياحة',
    'بحاجة صيانة',
  ),
  ComputerRow(
    'PC-103',
    'كلية الأداب',
    'خارج الخدمة',
  ),
  ComputerRow(
    'PC-104',
    'مديرية نظم المعلومات',
    'يعمل',
  ),
];

// ---------------------------------------------------------------------
// Printers
// ---------------------------------------------------------------------

class PrinterRow {
  final String name;
  final String college;
  final String status;

  const PrinterRow(
    this.name,
    this.college,
    this.status,
  );
}

const List<PrinterRow> mockPrinters = [
  PrinterRow(
    'PR-01',
    'مديرية نظم المعلومات',
    'يعمل',
  ),
  PrinterRow(
    'PR-02',
    'كلية السياحة',
    'يعمل',
  ),
  PrinterRow(
    'PR-03',
    'كلية الأداب',
    'بحاجة صيانة',
  ),
];

// ---------------------------------------------------------------------
// Maintenance Requests
// ---------------------------------------------------------------------

class MaintenanceRow {
  final String device;
  final String description;
  final String status; // قيد الانتظار / قيد المعالجة / مكتمل
  final String date;

  const MaintenanceRow(
    this.device,
    this.description,
    this.status,
    this.date,
  );
}

const List<MaintenanceRow> mockMaintenanceRequests = [
  MaintenanceRow(
    'PC-102',
    'الجهاز بطيء جدًا عند الإقلاع',
    'قيد المعالجة',
    '2026/08/20',
  ),
  MaintenanceRow(
    'PR-03',
    'انحشار الورق بشكل متكرر',
    'قيد الانتظار',
    '2026/08/25',
  ),
  MaintenanceRow(
    'PC-103',
    'لا يعمل الجهاز نهائيًا',
    'مكتمل',
    '2026/08/10',
  ),
];

// ---------------------------------------------------------------------
// Activity Log
// ---------------------------------------------------------------------

class ActivityRow {
  final String time;
  final String user;
  final String action;

  const ActivityRow(
    this.time,
    this.user,
    this.action,
  );
}

const List<ActivityRow> mockActivityLog = [
  ActivityRow(
    '2026/08/31 11:20',
    'admintest',
    'أضاف كلية جديدة: كلية الأداب',
  ),
  ActivityRow(
    '2026/08/30 09:05',
    'فني صيانة',
    'أنهى طلب صيانة PC-103',
  ),
  ActivityRow(
    '2026/08/29 16:40',
    'admintest',
    'حذف مستخدم غير نشط',
  ),
];
