import 'package:flutter/material.dart';

/// One entry in the sidebar drawer, matching the order shown in the
/// screenshots: Users, Colleges, Employees, Computers, Printers,
/// Maintenance Requests, then the three report pages, then Activity Log.
class NavItem {
  final String label;
  final IconData icon;
  final String route;
  const NavItem({required this.label, required this.icon, required this.route});
}

const List<NavItem> kNavItems = [
  NavItem(label: 'المستخدمون', icon: Icons.people_alt_rounded, route: '/users'),
  NavItem(label: 'الكليات', icon: Icons.school_rounded, route: '/colleges'),
  NavItem(label: 'الموظفون', icon: Icons.badge_rounded, route: '/employees'),
  NavItem(label: 'الحواسيب', icon: Icons.computer_rounded, route: '/computers'),
  NavItem(label: 'الطابعات', icon: Icons.print_rounded, route: '/printers'),
  NavItem(label: 'طلبات الصيانة', icon: Icons.build_rounded, route: '/maintenance-requests'),
  NavItem(label: 'تقرير الحواسيب', icon: Icons.bar_chart_rounded, route: '/reports/computers'),
  NavItem(label: 'تقرير الطابعات', icon: Icons.bar_chart_rounded, route: '/reports/printers'),
  NavItem(label: 'تقرير طلبات الصيانة', icon: Icons.bar_chart_rounded, route: '/reports/maintenance'),
  NavItem(label: 'سجل النشاطات', icon: Icons.history_rounded, route: '/activity-log'),
];
