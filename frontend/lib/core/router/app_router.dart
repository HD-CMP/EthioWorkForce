import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/workers/presentation/pages/workers_list_page.dart';
import '../../features/attendance/presentation/pages/attendance_page_new.dart';
import '../../features/attendance/presentation/pages/attendance_period_page.dart';
import '../../features/admin/presentation/pages/admin_registration_page.dart';
import '../../features/admin/presentation/pages/role_management_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/payroll/presentation/pages/payroll_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/workers/presentation/pages/site_management_page.dart';
import '../../features/workers/presentation/pages/work_type_management_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String workers = '/workers';
  static const String attendance = '/attendance';
  static const String attendancePeriod = '/attendance/period';
  static const String adminRegistration = '/admin-registration';
  static const String roleManagement = '/role-management';
  static const String notifications = '/notifications';
  static const String payroll = '/payroll';
  static const String sites = '/sites';
  static const String workTypes = '/work-types';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String reports = '/reports';
  
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case workers:
        return MaterialPageRoute(builder: (_) => const WorkersListPage());
      case attendance:
        return MaterialPageRoute(builder: (_) => const AttendancePageNew());
      case attendancePeriod:
        return MaterialPageRoute(builder: (_) => const AttendancePeriodPage());
      case adminRegistration:
        return MaterialPageRoute(builder: (_) => const AdminRegistrationPage());
      case roleManagement:
        return MaterialPageRoute(builder: (_) => const RoleManagementPage());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());
      case payroll:
        return MaterialPageRoute(builder: (_) => const PayrollListPage());
      case sites:
        return MaterialPageRoute(builder: (_) => const SiteManagementPage());
      case workTypes:
        return MaterialPageRoute(builder: (_) => const WorkTypeManagementPage());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
