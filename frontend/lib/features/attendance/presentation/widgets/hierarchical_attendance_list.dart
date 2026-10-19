import 'package:flutter/material.dart';

import '../../domain/entities/attendance.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../overtime/domain/entities/overtime.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import 'worker_hierarchy_node.dart';
import 'multi_day_attendance_selector.dart';
import 'multi_day_overtime_selector.dart';

class HierarchicalAttendanceList extends StatefulWidget {
  final List<Worker> workers;
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
  });

  @override
  State<HierarchicalAttendanceList> createState() => _HierarchicalAttendanceListState();
}

class _HierarchicalAttendanceListState extends State<HierarchicalAttendanceList> {
  List<Worker> _sortedWorkers = [];
  final Set<String> _collapsedWorkPlaces = {};

  @override
  void initState() {
    super.initState();
    _sortWorkers();
  }

  @override
  void didUpdateWidget(HierarchicalAttendanceList oldWidget) {
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
          mode: 'mark',
          onSave: (dates, status) {
            widget.onMarkMultiDayAttendance?.call(worker, dates, status);
          },
        ),
      ),
    );
  }

  void _showMultiDayVerificationSelector(BuildContext context, Worker worker) {
    final workerAttendances = widget.attendances
        .where((a) => a.workerId == worker.id)
        .toList();
        
    debugPrint("DEBUG: _showMultiDayVerificationSelector called for worker ${worker.id}");
    debugPrint("DEBUG: widget.attendances length = ${widget.attendances.length}");
    debugPrint("DEBUG: workerAttendances length = ${workerAttendances.length}");
    for (var a in workerAttendances) {
      debugPrint("DEBUG: Attendance found for date ${a.attendanceDate} (isVerified: ${a.isVerified})");
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

  void _showMultiDayOvertimeSelector(BuildContext context, Worker worker) {
    final workerOvertimes = widget.overtimes
        .where((o) => o.workerId == worker.id)
        .toList();
    
    debugPrint('?? Opening overtime modal for worker ${worker.id}');
    debugPrint('?? Worker overtimes passed to modal: ${workerOvertimes.length}');
    for (final o in workerOvertimes.where((o) => o.hours > 0)) {
      debugPrint('   ?? Overtime: ${o.overtimeDate} = ${o.hours}h');
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
          mode: 'verify',
          onSave: (overtimeData) async {
            await widget.onMarkMultiDayOvertime?.call(worker, overtimeData);
          },
        ),
      ),
    );
  }





  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF007A3D);
      case 'absent':
        return const Color(0xFFB71C1C);
      case 'late':
        return const Color(0xFFE65100);
      case 'excused':
        return const Color(0xFF1E3A5F);
      case 'leave':
        return const Color(0xFF0A192F);
      case 'half_day':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF9CA3AF);
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
        return const Color(0xFF1E3A5F);
      case 'Supervisor':
        return const Color(0xFF007A3D);
      case 'Engineer':
        return const Color(0xFF0A192F);
      default:
        return const Color(0xFF9CA3AF);
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
      final isSelected = false; // widget.selectedAttendanceIds...
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
            colors: [const Color(0xFF005C2E), const Color(0xFF007A3D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0x4D007A3D),
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
                color: const Color(0x33FFFFFF),
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
                        color: const Color(0xE6FFFFFF),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          managerName,
                          style: TextStyle(
                            color: const Color(0xE6FFFFFF),
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
                    color: const Color(0xE6FFFFFF),
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
                color: const Color(0xFF005C2E),
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
            Icon(Icons.people_outline, size: 80, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No workers registered',
              style: TextStyle(fontSize: 16, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Text(
              'Add workers to this site first',
              style: TextStyle(fontSize: 13, color: const Color(0xFF9CA3AF)),
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
    final todayAttendance = workerAttendances.where((a) => 
      a.attendanceDate.year == widget.selectedDate.year &&
      a.attendanceDate.month == widget.selectedDate.month &&
      a.attendanceDate.day == widget.selectedDate.day
    ).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
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
        child: Card(
        elevation: isSelected ? 4 : (isManager ? 3 : 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: const Color(0xFF007A3D), width: 2)
              : isManager
                  ? BorderSide(color: const Color(0xFFD1D5DB), width: 1.5)
                  : BorderSide.none,
        ),
        color: isManager ? const Color(0xFFE8EDF4) : Colors.white,
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
                color: const Color(0xFF374151),
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
                  if (widget.onMarkMultiDayAttendance != null) ...[
                    InkWell(
                      onTap: () => _showMultiDaySelector(context, worker),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF90CAF9), width: 1),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: const Color(0xFF0A192F),
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
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFB2DFCA), width: 1),
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: const Color(0xFF005C2E),
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
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFCC80), width: 1),
                        ),
                        child: Icon(
                          Icons.access_time,
                          size: 18,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
                              const SizedBox(height: 4),
                              if (todayAttendance != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(38, _getStatusColor(todayAttendance.status).red, _getStatusColor(todayAttendance.status).green, _getStatusColor(todayAttendance.status).blue),
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
                                        const Icon(Icons.verified, size: 12, color: const Color(0xFF007A3D)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
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
                      color: const Color(0xFF6B7280),
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
              '${worker.workType ?? 'No work type'}${worker.phoneNumber != null ? ' � ${worker.phoneNumber}' : ''}',
              style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
