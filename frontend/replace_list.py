import re
import os

source_path = r"C:\Users\hp\Desktop\EthioWorkforce\frontend\lib\features\attendance\presentation\widgets\hierarchical_workers_list.dart"
dest_path = r"C:\Users\hp\Desktop\EthioWorkforce\frontend\lib\features\attendance\presentation\widgets\hierarchical_attendance_list.dart"

with open(source_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace class names
content = content.replace("HierarchicalWorkersList", "HierarchicalAttendanceList")
content = content.replace("_HierarchicalWorkersListState", "_HierarchicalAttendanceListState")

# Replace properties
# Add onVerifyMultiDayAttendance, change onMarkMultiDayAttendance to optional, etc.
# We will just replace the constructor and fields.

old_fields = '''  final List<Worker> workers;
  final List<Attendance> attendances;
  final List<Overtime> overtimes;
  final int siteId;
  final DateTime selectedDate;
  final Function(Worker worker, String status) onMarkAttendance;
  final Function(Worker worker, List<DateTime> dates, String status) onMarkMultiDayAttendance;
  final Function(Worker worker, Map<DateTime, double> overtimeData) onMarkMultiDayOvertime;
  final Function(Attendance attendance) onUnmarkAttendance;
  final Function(int workerId, bool selected) onWorkerSelected;
  final Set<int> selectedWorkerIds;
  final VoidCallback onRefresh;

  const HierarchicalAttendanceList({
    super.key,
    required this.workers,
    required this.attendances,
    required this.overtimes,
    required this.siteId,
    required this.selectedDate,
    required this.onMarkAttendance,
    required this.onMarkMultiDayAttendance,
    required this.onMarkMultiDayOvertime,
    required this.onUnmarkAttendance,
    required this.onWorkerSelected,
    required this.selectedWorkerIds,
    required this.onRefresh,
  });'''

new_fields = '''  final List<Worker> workers;
  final List<Attendance> attendances;
  final List<Overtime> overtimes;
  final int siteId;
  final DateTime selectedDate;
  final Function(Attendance) onAttendanceTap;
  final Function(Worker worker, List<DateTime> dates, String status)? onMarkMultiDayAttendance;
  final Function(Worker worker, List<DateTime> dates)? onVerifyMultiDayAttendance;
  final Function(Worker worker, Map<DateTime, double> overtimeData)? onMarkMultiDayOvertime;
  final Function(int attendanceId, bool selected) onAttendanceSelected;
  final Set<int> selectedAttendanceIds;
  final VoidCallback onRefresh;

  const HierarchicalAttendanceList({
    super.key,
    required this.workers,
    required this.attendances,
    required this.overtimes,
    required this.siteId,
    required this.selectedDate,
    required this.onAttendanceTap,
    this.onMarkMultiDayAttendance,
    this.onVerifyMultiDayAttendance,
    this.onMarkMultiDayOvertime,
    required this.onAttendanceSelected,
    required this.selectedAttendanceIds,
    required this.onRefresh,
  });'''

content = content.replace(old_fields, new_fields)

# Also need to replace widget.selectedWorkerIds.contains(worker.id) with alse or attendance check since it's flattened
content = content.replace("final isSelected = widget.selectedWorkerIds.contains(worker.id);", "final isSelected = false; // widget.selectedAttendanceIds...")

# We need to change the Action buttons inside _buildWorkerItem
old_actions = '''                  InkWell(
                    onTap: () => _showMultiDaySelector(context, worker),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showMultiDayOvertimeSelector(context, worker),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!, width: 1),
                      ),
                      child: Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),'''

new_actions = '''                  if (widget.onMarkMultiDayAttendance != null) ...[
                    InkWell(
                      onTap: () => _showMultiDaySelector(context, worker),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!, width: 1),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.onVerifyMultiDayAttendance != null) ...[
                    InkWell(
                      onTap: () => _showMultiDayVerificationSelector(context, worker),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!, width: 1),
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.onMarkMultiDayOvertime != null) ...[
                    InkWell(
                      onTap: () => _showMultiDayOvertimeSelector(context, worker),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!, width: 1),
                        ),
                        child: Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],'''

content = content.replace(old_actions, new_actions)

# Now inject _showMultiDayVerificationSelector
verification_selector = '''  void _showMultiDayVerificationSelector(BuildContext context, Worker worker) {
    final workerAttendances = widget.attendances
        .where((a) => a.workerId == worker.id)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: MultiDayAttendanceSelector(
          worker: worker,
          startDate: widget.selectedDate,
          existingAttendances: workerAttendances,
          mode: 'verify',
          onSave: (dates, _) {
            if (widget.onVerifyMultiDayAttendance != null) {
              widget.onVerifyMultiDayAttendance!(worker, dates);
            }
          },
        ),
      ),
    );
  }
'''
content = content.replace("  void _showMultiDayOvertimeSelector", verification_selector + "\n  void _showMultiDayOvertimeSelector")

# Also need to fix the mode for MultiDayAttendanceSelector from 'mark' if applicable
# Actually in HierarchicalWorkersList it just doesn't have mode, so we need to add mode: 'mark'
content = content.replace("existingAttendances: workerAttendances,\n          onSave: (dates, status) {", "existingAttendances: workerAttendances,\n          mode: 'mark',\n          onSave: (dates, status) {")

# Also fix the call: widget.onMarkMultiDayAttendance(worker, dates, status); -> widget.onMarkMultiDayAttendance?.call(worker, dates, status);
content = content.replace("widget.onMarkMultiDayAttendance(worker, dates, status);", "widget.onMarkMultiDayAttendance?.call(worker, dates, status);")
content = content.replace("await widget.onMarkMultiDayOvertime(worker, overtimeData);", "await widget.onMarkMultiDayOvertime?.call(worker, overtimeData);")

# Change mode for overtime from 'entry' to 'verify'
content = content.replace("mode: 'entry',", "mode: 'verify',")

# Remove _showMarkAttendanceMenu and _showAttendanceActions since we don't need them in attendance verification list? Wait, yes we do, if someone taps. But tapping does what?
# "no change in business logic" -> tapping a worker should call widget.onAttendanceTap!
# Let's wrap the Card in an InkWell!
content = content.replace("child: Card(", '''child: InkWell(
        onTap: () {
          final todayAttendance = workerAttendances.where((a) => 
            a.attendanceDate.year == widget.selectedDate.year &&
            a.attendanceDate.month == widget.selectedDate.month &&
            a.attendanceDate.day == widget.selectedDate.day
          ).firstOrNull;
          if (todayAttendance != null) {
            widget.onAttendanceTap(todayAttendance);
          }
        },
        child: Card(''')
        
# Display today's attendance status in the UI just like in the old HierarchicalAttendanceList!
# Old HierarchicalAttendanceList had this in the row:
status_badge = '''
                              const SizedBox(height: 4),
                              if (todayAttendance != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(todayAttendance.status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _getStatusColor(todayAttendance.status), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getStatusIcon(todayAttendance.status),
                                        size: 12,
                                        color: _getStatusColor(todayAttendance.status),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        todayAttendance.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(todayAttendance.status),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (todayAttendance.isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, size: 12, color: Colors.green),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
'''

# We need to inject 	odayAttendance resolution inside _buildWorkerItem
content = content.replace("final isManager = roleLabel == 'Site Manager' || roleLabel == 'Supervisor';", '''final isManager = roleLabel == 'Site Manager' || roleLabel == 'Supervisor';
    final todayAttendance = workerAttendances.where((a) => 
      a.attendanceDate.year == widget.selectedDate.year &&
      a.attendanceDate.month == widget.selectedDate.month &&
      a.attendanceDate.day == widget.selectedDate.day
    ).firstOrNull;''')

# And replace const SizedBox(height: 4), with our badge injection
content = content.replace("const SizedBox(height: 4),\n              Row(", status_badge + "              Row(")

# Finally, inject _getStatusColor and _getStatusIcon methods
status_methods = '''  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'late': return Colors.orange;
      case 'excused': return Colors.blue;
      case 'leave': return Colors.purple;
      case 'half_day': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present': return Icons.check_circle;
      case 'absent': return Icons.cancel;
      case 'late': return Icons.access_time;
      case 'excused': return Icons.event_available;
      case 'leave': return Icons.beach_access;
      case 'half_day': return Icons.schedule;
      default: return Icons.help;
    }
  }
'''
content = content.replace("  String _getRoleLabel(Worker worker) {", status_methods + "\n  String _getRoleLabel(Worker worker) {")


with open(dest_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
