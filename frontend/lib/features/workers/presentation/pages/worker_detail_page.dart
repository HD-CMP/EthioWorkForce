import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/localization/app_localizations.dart';

class WorkerDetailPage extends StatelessWidget {
  final int workerId;
  final String employeeId;
  final String fullName;

  const WorkerDetailPage({
    super.key,
    required this.workerId,
    required this.employeeId,
    required this.fullName,
  });

  String _generateQRData() {
    return 'WORKER|$workerId|$employeeId|1';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      fullName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: $employeeId',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.scanQrCode ?? 'QR Code',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: QrImageView(
                              data: _generateQRData(),
                              version: QrVersions.auto,
                              size: 200,
                              gapless: false,
                              errorStateBuilder: (cxt, err) {
                                return const Center(
                                  child: Text(
                                    'QR Code Error',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Scan for attendance',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations?.fullName ?? 'Worker Information',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.badge,
                    title: localizations?.employeeId ?? 'Employee ID',
                    value: employeeId,
                  ),
                  _InfoCard(
                    icon: Icons.phone,
                    title: localizations?.phoneNumber ?? 'Phone',
                    value: '+251 911 234 567',
                  ),
                  _InfoCard(
                    icon: Icons.location_on,
                    title: localizations?.site ?? 'Site',
                    value: 'Construction Site A',
                  ),
                  _InfoCard(
                    icon: Icons.work,
                    title: localizations?.workType ?? 'Work Type',
                    value: localizations?.dailyWorker ?? 'Daily Laborer',
                  ),
                  _InfoCard(
                    icon: Icons.account_balance,
                    title: 'Bank Account',
                    value: 'CBE - 1000123456789',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Activity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    _ActivityItem(
                      date: 'Today, 08:00 AM',
                      title: 'Check In',
                      icon: Icons.login,
                      color: Colors.green,
                    ),
                    _ActivityItem(
                      date: 'Yesterday, 05:00 PM',
                      title: 'Check Out',
                      icon: Icons.logout,
                      color: Colors.orange,
                    ),
                    _ActivityItem(
                      date: 'Jan 20, 08:15 AM',
                      title: 'Check In (Late)',
                      icon: Icons.access_time,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String date;
  final String title;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.date,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(date),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }
}
