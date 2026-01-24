import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EthioWorkforce'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuItem(
            context,
            icon: Icons.people,
            title: 'Workers',
            subtitle: 'Manage workforce',
            onTap: () => Navigator.pushNamed(context, AppRouter.workers),
          ),
          _buildMenuItem(
            context,
            icon: Icons.check_circle,
            title: 'Attendance',
            subtitle: 'Mark attendance',
            onTap: () => Navigator.pushNamed(context, AppRouter.attendance),
          ),
          _buildMenuItem(
            context,
            icon: Icons.attach_money,
            title: 'Payroll',
            subtitle: 'Process payments',
            onTap: () => Navigator.pushNamed(context, AppRouter.payroll),
          ),
          _buildMenuItem(
            context,
            icon: Icons.location_on,
            title: 'Sites',
            subtitle: 'Manage locations',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.work,
            title: 'Work Types',
            subtitle: 'Define roles',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.sync,
            title: 'Sync',
            subtitle: 'Sync data',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.assessment,
            title: 'Reports',
            subtitle: 'View analytics',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Configure app',
            onTap: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
