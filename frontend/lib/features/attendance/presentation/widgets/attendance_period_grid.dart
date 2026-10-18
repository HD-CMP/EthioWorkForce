import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/attendance.dart';

class AttendancePeriodGrid extends StatefulWidget {
  final int workerId;
  final String workerName;
  final DateTime periodStartDate;
  final int periodDays;
  final List<Attendance> existingAttendances;
  final Function(DateTime date, String status) onDayStatusChanged;
  final bool readOnly;

  const AttendancePeriodGrid({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.periodStartDate,
    required this.periodDays,
    required this.existingAttendances,
    required this.onDayStatusChanged,
    this.readOnly = false,
  });

  @override
  State<AttendancePeriodGrid> createState() => _AttendancePeriodGridState();
}

class _AttendancePeriodGridState extends State<AttendancePeriodGrid> {
  final Map<DateTime, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadExistingAttendances();
  }

  @override
  void didUpdateWidget(AttendancePeriodGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingAttendances != widget.existingAttendances) {
      _loadExistingAttendances();
    }
  }

  void _loadExistingAttendances() {
    _attendanceStatus.clear();
    for (final attendance in widget.existingAttendances) {
      final dateKey = DateTime(
        attendance.attendanceDate.year,
        attendance.attendanceDate.month,
        attendance.attendanceDate.day,
      );
      _attendanceStatus[dateKey] = attendance.status;
    }
  }

  bool _isDateInFuture(DateTime date) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dateStart = DateTime(date.year, date.month, date.day);
    return dateStart.isAfter(todayStart);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.event_available;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'present':
        return 'P';
      case 'absent':
        return 'A';
      case 'late':
        return 'L';
      case 'excused':
        return 'E';
      default:
        return '-';
    }
  }

  void _showStatusPicker(DateTime date) {
    if (widget.readOnly || _isDateInFuture(date)) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark Attendance for ${DateFormat('MMM d').format(date)}',
          style: const TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('present', 'Present', Icons.check_circle, Colors.green, date),
            _buildStatusOption('absent', 'Absent', Icons.cancel, Colors.red, date),
            _buildStatusOption('late', 'Late', Icons.access_time, Colors.orange, date),
            _buildStatusOption('excused', 'Excused', Icons.event_available, Colors.blue, date),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear, color: Colors.grey),
              title: const Text('Clear'),
              onTap: () {
                setState(() {
                  _attendanceStatus.remove(date);
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    String status,
    String label,
    IconData icon,
    Color color,
    DateTime date,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        setState(() {
          _attendanceStatus[date] = status;
        });
        widget.onDayStatusChanged(date, status);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d');
    final monthFormat = DateFormat('MMM');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${DateFormat('MMM d').format(widget.periodStartDate)} - ${DateFormat('MMM d, yyyy').format(widget.periodStartDate.add(Duration(days: widget.periodDays - 1)))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSummary(),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: widget.periodDays,
              itemBuilder: (context, index) {
                final date = widget.periodStartDate.add(Duration(days: index));
                final dateKey = DateTime(date.year, date.month, date.day);
                final status = _attendanceStatus[dateKey];
                final isFuture = _isDateInFuture(date);
                final isToday = DateTime(date.year, date.month, date.day) ==
                    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                return InkWell(
                  onTap: isFuture ? null : () => _showStatusPicker(dateKey),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.grey[200]
                          : (status != null
                              ? _getStatusColor(status).withOpacity(0.1)
                              : Colors.white),
                      border: Border.all(
                        color: isToday
                            ? Theme.of(context).primaryColor
                            : (status != null
                                ? _getStatusColor(status)
                                : Colors.grey[300]!),
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (status != null)
                          Icon(
                            _getStatusIcon(status),
                            size: 16,
                            color: _getStatusColor(status),
                          )
                        else if (isFuture)
                          Icon(Icons.lock_outline, size: 14, color: Colors.grey[400])
                        else
                          Icon(Icons.circle_outlined, size: 14, color: Colors.grey[400]),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(date),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isFuture ? Colors.grey[400] : Colors.black87,
                          ),
                        ),
                        if (index < 7 || date.day == 1)
                          Text(
                            monthFormat.format(date),
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    int present = 0;
    int absent = 0;
    int late = 0;
    int excused = 0;

    for (var status in _attendanceStatus.values) {
      switch (status) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'excused':
          excused++;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryItem('P', present, Colors.green),
          const SizedBox(width: 4),
          _buildSummaryItem('A', absent, Colors.red),
          const SizedBox(width: 4),
          _buildSummaryItem('L', late, Colors.orange),
          const SizedBox(width: 4),
          _buildSummaryItem('E', excused, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildLegendItem(Icons.check_circle, 'Present', Colors.green),
        _buildLegendItem(Icons.cancel, 'Absent', Colors.red),
        _buildLegendItem(Icons.access_time, 'Late', Colors.orange),
        _buildLegendItem(Icons.event_available, 'Excused', Colors.blue),
        _buildLegendItem(Icons.lock_outline, 'Locked', Colors.grey),
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
