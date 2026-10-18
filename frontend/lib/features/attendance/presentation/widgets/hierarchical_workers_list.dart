import 'package:flutter/material.dart';

import '../../domain/entities/attendance.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../overtime/domain/entities/overtime.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import 'worker_hierarchy_node.dart';
import 'multi_day_attendance_selector.dart';
import 'multi_day_overtime_selector.dart';

class HierarchicalWorkersList extends StatefulWidget {
  final List<Worker> workers;
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

  const HierarchicalWorkersList({
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
  });

  @override
  State<HierarchicalWorkersList> createState() => _HierarchicalWorkersListState();
}

class _HierarchicalWorkersListState extends State<HierarchicalWorkersList> {
  List<Worker> _sortedWorkers = [];
  final Set<String> _collapsedWorkPlaces = {};

  @override
  void initState() {
    super.initState();
    _sortWorkers();
  }

  @override
  void didUpdateWidget(HierarchicalWorkersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workers != widget.workers) {
      _sortWorkers();
    }
  }

  void _sortWorkers() {
    _sortedWorkers = List.from(widget.workers);
    _sortedWorkers.sort((a, b) {
      if (a.workPlaceId != b.workPlaceId) {
        if (a.workPlaceId == null) return 1;
        if (b.workPlaceId == null) return -1;
        final workPlaceNameCompare = (a.workPlaceName ?? '').compareTo(b.workPlaceName ?? '');
        if (workPlaceNameCompare != 0) return workPlaceNameCompare;
      }
      
      final hierarchyCompare = _getRoleHierarchyLevel(a.workType)
          .compareTo(_getRoleHierarchyLevel(b.workType));
      if (hierarchyCompare != 0) return hierarchyCompare;
      
      return a.fullName.compareTo(b.fullName);
    });
    setState(() {});
  }

  int _getRoleHierarchyLevel(String? workType) {
    if (workType == null) return 999;
    final role = workType.toLowerCase();
    
    if (role.contains('site manager') || role.contains('project manager')) return 1;
    if (role.contains('supervisor') || role.contains('foreman')) return 2;
    if (role.contains('engineer')) return 3;
    if (role.contains('technician') || role.contains('skilled')) return 4;
    if (role.contains('operator')) return 5;
    if (role.contains('worker') || role.contains('laborer') || role.contains('daily')) return 6;
    
    return 7;
  }



  List<Attendance> _getAttendancesForWorker(int workerId) {
    return widget.attendances
        .where((a) => a.workerId == workerId)
        .toList()
      ..sort((a, b) => a.attendanceDate.compareTo(b.attendanceDate));
  }

  Attendance? _getAttendanceForDate(int workerId, DateTime date) {
    try {
      return widget.attendances.firstWhere((a) => 
        a.workerId == workerId && 
        a.attendanceDate.year == date.year &&
        a.attendanceDate.month == date.month &&
        a.attendanceDate.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  bool _hasAttendanceInPeriod(int workerId) {
    return widget.attendances.any((a) => a.workerId == workerId);
  }

  void _showMarkAttendanceMenu(BuildContext context, Worker worker) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Attendance for ${worker.fullName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Employee ID: ${worker.employeeId}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 24),
            _buildStatusOption(
              context,
              'Present',
              Icons.check_circle,
              Colors.green,
              'present',
              worker,
            ),
            _buildStatusOption(
              context,
              'Absent',
              Icons.cancel,
              Colors.red,
              'absent',
              worker,
            ),
            _buildStatusOption(
              context,
              'Late',
              Icons.access_time,
              Colors.orange,
              'late',
              worker,
            ),
            _buildStatusOption(
              context,
              'Excused',
              Icons.event_available,
              Colors.blue,
              'excused',
              worker,
            ),
            _buildStatusOption(
              context,
              'Leave',
              Icons.beach_access,
              Colors.purple,
              'leave',
              worker,
            ),
            _buildStatusOption(
              context,
              'Half Day',
              Icons.schedule,
              Colors.amber,
              'half_day',
              worker,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMultiDaySelector(BuildContext context, Worker worker) {
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
          onSave: (dates, status) {
            widget.onMarkMultiDayAttendance(worker, dates, status);
          },
        ),
      ),
    );
  }

  void _showMultiDayOvertimeSelector(BuildContext context, Worker worker) {
    final workerOvertimes = widget.overtimes
        .where((o) => o.workerId == worker.id)
        .toList();
    
    print('📂 Opening overtime modal for worker ${worker.id}');
    print('📂 Worker overtimes passed to modal: ${workerOvertimes.length}');
    for (final o in workerOvertimes.where((o) => o.hours > 0)) {
      print('   📂 Overtime: ${o.overtimeDate} = ${o.hours}h');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: MultiDayOvertimeSelector(
          worker: worker,
          startDate: widget.selectedDate,
          existingOvertimes: workerOvertimes,
          siteId: widget.siteId,
          mode: 'entry',
          onSave: (overtimeData) async {
            await widget.onMarkMultiDayOvertime(worker, overtimeData);
          },
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String status,
    Worker worker,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onMarkAttendance(worker, status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _showAttendanceActions(BuildContext context, Attendance attendance, Worker worker) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${worker.employeeId}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(attendance.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    attendance.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(attendance.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildActionOption(
              context,
              'Change Status',
              Icons.edit,
              Colors.blue,
              () {
                Navigator.pop(context);
                _showMarkAttendanceMenu(context, worker);
              },
            ),
            _buildActionOption(
              context,
              'Unmark Attendance',
              Icons.delete_outline,
              Colors.red,
              () {
                Navigator.pop(context);
                widget.onUnmarkAttendance(attendance);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
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
      case 'leave':
        return Colors.purple;
      case 'half_day':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(Worker worker) {
    final role = worker.workType?.toLowerCase() ?? '';
    
    if (role.contains('site manager') || role.contains('project manager')) {
      return 'Site Manager';
    } else if (role.contains('supervisor') || role.contains('foreman')) {
      return 'Supervisor';
    } else if (role.contains('engineer')) {
      return 'Engineer';
    }
    return 'Worker';
  }

  Color _getRoleBadgeColor(String roleLabel) {
    switch (roleLabel) {
      case 'Site Manager':
        return Colors.blue;
      case 'Supervisor':
        return Colors.green;
      case 'Engineer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _buildWorkplaceGroupedList() {
    final List<Widget> widgets = [];
    String? currentWorkPlace;
    int workPlaceWorkerCount = 0;
    
    for (int index = 0; index < _sortedWorkers.length; index++) {
      final worker = _sortedWorkers[index];
      final workPlaceName = worker.workPlaceName ?? 
        (worker.hierarchyLevel != null && worker.hierarchyLevel! <= 2 ? 'Site Management' : 'General Workforce');
      
      if (workPlaceName != currentWorkPlace) {
        currentWorkPlace = workPlaceName;
        
        final workPlaceWorkers = _sortedWorkers
            .where((w) => (w.workPlaceName ?? 
              (w.hierarchyLevel != null && w.hierarchyLevel! <= 2 ? 'Site Management' : 'General Workforce')) == currentWorkPlace)
            .toList();
        
        workPlaceWorkerCount = workPlaceWorkers.length;
        
        final isCollapsed = _collapsedWorkPlaces.contains(currentWorkPlace);
        
        widgets.add(_buildWorkplaceHeader(
          currentWorkPlace,
          workPlaceWorkerCount,
          worker.workPlaceSupervisorName,
          isCollapsed,
        ));
      }
      
      if (_collapsedWorkPlaces.contains(currentWorkPlace)) {
        continue;
      }
      
      final workerAttendances = _getAttendancesForWorker(worker.id!);
      final hasAttendance = _hasAttendanceInPeriod(worker.id!);
      final isSelected = widget.selectedWorkerIds.contains(worker.id);
      final roleLabel = _getRoleLabel(worker);

      widgets.add(_buildWorkerItem(
        worker: worker,
        workerAttendances: workerAttendances,
        hasAttendance: hasAttendance,
        isSelected: isSelected,
        roleLabel: roleLabel,
        index: index + 1,
      ));
    }
    
    return widgets;
  }

  Widget _buildWorkplaceHeader(String workPlaceName, int workerCount, String? managerName, bool isCollapsed) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_collapsedWorkPlaces.contains(workPlaceName)) {
            _collapsedWorkPlaces.remove(workPlaceName);
          } else {
            _collapsedWorkPlaces.add(workPlaceName);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[700]!, Colors.teal[500]!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      workPlaceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (managerName != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.supervisor_account,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          managerName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$workerCount ${workerCount == 1 ? 'worker' : 'workers'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$workerCount',
              style: TextStyle(
                color: Colors.teal[700],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No workers registered',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add workers to this site first',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: _buildWorkplaceGroupedList(),
    );
  }

  Widget _buildWorkerItem({
    required Worker worker,
    required List<Attendance> workerAttendances,
    required bool hasAttendance,
    required bool isSelected,
    required String roleLabel,
    required int index,
  }) {
    final isManager = roleLabel == 'Site Manager' || roleLabel == 'Supervisor';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: isSelected ? 4 : (isManager ? 3 : 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : isManager
                  ? BorderSide(color: Colors.grey[300]!, width: 1.5)
                  : BorderSide.none,
        ),
        color: isManager ? Colors.blue[50] : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.only(
            left: 12,
            right: 16,
            top: 8,
            bottom: 8,
          ),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      worker.fullName,
                      style: TextStyle(
                        fontWeight: isManager ? FontWeight.bold : FontWeight.w600,
                        fontSize: isManager ? 17 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleBadgeColor(roleLabel),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      roleLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${worker.employeeId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${worker.workType ?? 'No work type'}${worker.phoneNumber != null ? ' • ${worker.phoneNumber}' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          trailing: Builder(
            builder: (context) {
              final todayAttendance = _getAttendanceForDate(worker.id!, widget.selectedDate);
              final hasAttendanceToday = todayAttendance != null;
              final isVerified = todayAttendance?.isVerified ?? false;
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasAttendanceToday) ...[
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      tooltip: 'Unmark Attendance',
                      onPressed: () => _showAttendanceActions(context, todayAttendance, worker),
                    ),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 18,
                          color: Colors.green[700],
                        ),
                      ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Theme.of(context).primaryColor,
                      onPressed: () => _showMarkAttendanceMenu(context, worker),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
