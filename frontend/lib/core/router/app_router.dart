import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/workers/presentation/pages/workers_list_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/payroll/presentation/pages/payroll_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String workers = '/workers';
  static const String attendance = '/attendance';
  static const String payroll = '/payroll';
  static const String settings = '/settings';
  
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
        return MaterialPageRoute(builder: (_) => const AttendancePage());
      case payroll:
        return MaterialPageRoute(builder: (_) => const PayrollListPage());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
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
