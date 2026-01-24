import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import 'qr_scanner_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AudioFeedbackService _audioService = AudioFeedbackService();
  DateTime _selectedDate = DateTime.now();
  String _calendarType = 'Gregorian';
  bool _showEthiopianCalendar = false;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _openQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (result != null && mounted) {
      final employeeId = result['employee_id'];
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.success,
        message: AppLocalizations.of(context)?.registered ?? 'Attendance Registered',
        subtitle: 'Employee: $employeeId',
      );
    }
  }

  String _formatEthiopianDate(DateTime date) {
    return 'ጥር 14, 2018';
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return _showEthiopianCalendar ? 'እንደምን አደሩ' : 'Good Morning';
    } else if (hour < 17) {
      return _showEthiopianCalendar ? 'እንደምን ዋሉ' : 'Good Afternoon';
    } else {
      return _showEthiopianCalendar ? 'እንደምን አመሹ' : 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.attendance ?? 'Attendance'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              setState(() {
                _showEthiopianCalendar = !_showEthiopianCalendar;
                _calendarType = _showEthiopianCalendar ? 'Ethiopian' : 'Gregorian';
              });
            },
            tooltip: 'Toggle Calendar Type',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreetingMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showEthiopianCalendar
                        ? _formatEthiopianDate(_selectedDate)
                        : dateFormat.format(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_calendarType Calendar',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: localizations?.present ?? 'Present',
                    value: '42',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: localizations?.absent ?? 'Absent',
                    value: '5',
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: localizations?.late ?? 'Late',
                    value: '3',
                    icon: Icons.access_time,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations?.attendance ?? 'Today\'s Attendance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.verified),
                  label: Text(localizations?.verifyAttendance ?? 'Verify All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 15,
              itemBuilder: (context, index) {
                final status = index % 3 == 0
                    ? 'Present'
                    : index % 3 == 1
                        ? 'Absent'
                        : 'Late';
                final color = status == 'Present'
                    ? Colors.green
                    : status == 'Absent'
                        ? Colors.red
                        : Colors.orange;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        status == 'Present'
                            ? Icons.check
                            : status == 'Absent'
                                ? Icons.close
                                : Icons.access_time,
                        color: color,
                      ),
                    ),
                    title: Text(
                      'Worker ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'ID: EMP${1000 + index} • ${status == "Late" ? "08:30 AM (30 min late)" : "08:00 AM"} • 8 hours',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'qr_scan',
            onPressed: _openQRScanner,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'manual_mark',
            onPressed: () {},
            icon: const Icon(Icons.people),
            label: Text(localizations?.markAttendance ?? 'Mark Attendance'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
