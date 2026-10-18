import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/attendance_remote_datasource.dart';
import '../../domain/entities/attendance.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../workers/data/datasources/worker_remote_datasource.dart';
import '../../../overtime/domain/entities/overtime.dart';
import '../../../overtime/data/datasources/overtime_remote_datasource.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import '../../../../core/widgets/ethiopian_date_picker.dart';
import '../../../../core/utils/ethiopian_calendar.dart';

class BulkVerifyPage extends StatefulWidget {
  final int siteId;
  final DateTime selectedDate;

  const BulkVerifyPage({
    super.key,
    required this.siteId,
    required this.selectedDate,
  });

  @override
  State<BulkVerifyPage> createState() => _BulkVerifyPageState();
}

class _BulkVerifyPageState extends State<BulkVerifyPage> {
  final _attendanceDataSource = AttendanceRemoteDataSource();
  final _workerDataSource = WorkerRemoteDataSource();
  final _overtimeDataSource = OvertimeRemoteDataSource();
  final _audioService = AudioFeedbackService();
  final _searchController = TextEditingController();

  List<Worker> _allWorkers = [];
  List<Worker> _filteredWorkers = [];
  List<Attendance> _allAttendances = [];
  List<Overtime> _allOvertimes = [];
  final Set<int> _selectedAttendanceIds = {};
  bool _isLoading = false;
  bool _selectAll = false;
  String _currentMode = 'verify'; // 'verify', 'unverify'
  String? _selectedWorkPlace;
  List<String> _workPlaces = [];
  String _statusFilter = 'all';
  late DateTime _selectedDate;
  String _bulkMode = 'attendance';
  bool _showEthiopianCalendar = true;

  bool get _isUnverifyMode => _currentMode == 'unverify';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _workerDataSource.getWorkers(siteId: widget.siteId, status: 'active'),
        _attendanceDataSource.getAttendances(
          siteId: widget.siteId,
          dateFrom: _selectedDate,
          dateTo: _selectedDate,
          limit: 5000,
        ),
        _overtimeDataSource.getOvertimes(
          siteId: widget.siteId,
          dateFrom: _selectedDate,
          dateTo: _selectedDate,
        ),
      ]);
      
      setState(() {
        // BUSINESS RULE: Hierarchy 1 & 2 do not use the daily attendance clock.
        final attendanceEligibleWorkers = (results[0] as List<Worker>)
            .where((w) => w.hierarchyLevel == null || w.hierarchyLevel! > 1)
            .toList();
        
        _allWorkers = attendanceEligibleWorkers;
        _filteredWorkers = _allWorkers;
        _allAttendances = results[1] as List<Attendance>;
        _allOvertimes = results[2] as List<Overtime>;
        
        final workPlaceSet = <String>{};
        for (final worker in _allWorkers) {
          if (worker.workPlaceName != null && worker.workPlaceName!.isNotEmpty) {
            workPlaceSet.add(worker.workPlaceName!);
          }
        }
        _workPlaces = workPlaceSet.toList()..sort();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error loading data: ${e.toString()}',
        );
      }
    }
  }

  Attendance? _getAttendance(int workerId) {
    try {
      return _allAttendances.firstWhere((a) => a.workerId == workerId);
    } catch (e) {
      return null;
    }
  }

  Overtime? _getOvertime(int workerId) {
    try {
      return _allOvertimes.firstWhere((o) => o.workerId == workerId);
    } catch (e) {
      return null;
    }
  }

  List<Attendance> _getFilteredAttendances() {
    List<Attendance> filtered = _allAttendances;
    
    if (_statusFilter != 'all') {
      filtered = filtered.where((a) => a.status == _statusFilter).toList();
    }
    
    return filtered;
  }

  List<Worker> _getWorkersWithAttendance() {
    final attendances = _getFilteredAttendances();
    final workerIds = attendances.map((a) => a.workerId).toSet();
    
    return _filteredWorkers.where((w) => w.id != null && workerIds.contains(w.id!)).toList();
  }

  bool _canBeSelected(int attendanceId) {
    final attendance = _allAttendances.firstWhere((a) => a.id == attendanceId);
    if (_isUnverifyMode) {
      return attendance.isVerified;
    } else {
      return !attendance.isVerified;
    }
  }

  List<Worker> _getVerifiedWorkers() {
    final verifiedAttendances = _getFilteredAttendances().where((a) => a.isVerified).toList();
    final workerIds = verifiedAttendances.map((a) => a.workerId).toSet();
    return _filteredWorkers.where((w) => w.id != null && workerIds.contains(w.id!)).toList();
  }

  List<Worker> _getUnverifiedWorkers() {
    final unverifiedAttendances = _getFilteredAttendances().where((a) => !a.isVerified).toList();
    final workerIds = unverifiedAttendances.map((a) => a.workerId).toSet();
    return _filteredWorkers.where((w) => w.id != null && workerIds.contains(w.id!)).toList();
  }

  List<Worker> _getDisplayWorkers() {
    if (_bulkMode == 'overtime') {
      return _getWorkersWithOvertime();
    } else if (_isUnverifyMode) {
      return _getVerifiedWorkers();
    } else {
      return _getWorkersWithAttendance();
    }
  }

  List<Worker> _getWorkersWithOvertime() {
    return _filteredWorkers.where((worker) {
      if (worker.id == null) return false;
      return _allOvertimes.any((o) => o.workerId == worker.id && o.hours > 0);
    }).toList();
  }

  List<Worker> _getSelectableWorkers() {
    return _isUnverifyMode ? _getVerifiedWorkers() : _getUnverifiedWorkers();
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

  void _filterWorkers(String query) {
    setState(() {
      _filteredWorkers = _allWorkers.where((worker) {
        if (query.isNotEmpty) {
          final nameLower = worker.fullName.toLowerCase();
          final idLower = worker.employeeId.toLowerCase();
          final queryLower = query.toLowerCase();
          if (!nameLower.contains(queryLower) && !idLower.contains(queryLower)) {
            return false;
          }
        }
        
        if (_selectedWorkPlace != null) {
          return worker.workPlaceName == _selectedWorkPlace;
        }
        
        return true;
      }).toList();
      _selectedAttendanceIds.clear();
      _selectAll = false;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        final selectableWorkers = _getSelectableWorkers();
        _selectedAttendanceIds.clear();
        
        for (final worker in selectableWorkers) {
          final attendance = _getAttendance(worker.id!);
          if (attendance != null && attendance.id != null && _canBeSelected(attendance.id!)) {
            _selectedAttendanceIds.add(attendance.id!);
          }
        }
      } else {
        _selectedAttendanceIds.clear();
      }
    });
  }

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == 'verify' ? 'unverify' : 'verify';
      _selectedAttendanceIds.clear();
      _selectAll = false;
    });
  }

  Future<void> _showOvertimeDialog(Worker worker) async {
    final overtime = _allOvertimes.firstWhere(
      (o) => o.workerId == worker.id,
      orElse: () => Overtime(
        workerId: worker.id!,
        siteId: widget.siteId,
        overtimeDate: _selectedDate,
        hours: 0,
      ),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Verify Overtime'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              worker.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${worker.employeeId}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (overtime.hours > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Current Overtime: ${overtime.hours} hours',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              overtime.isVerified 
                  ? 'This overtime has already been verified.'
                  : 'Verify this overtime for payroll processing?',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (!overtime.isVerified)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify'),
            ),
        ],
      ),
    );

    if (result != null && overtime.id != null) {
      await _verifyOvertimeForWorker(overtime.id!);
    }
  }

  Future<void> _verifyOvertimeForWorker(int overtimeId) async {
    setState(() => _isLoading = true);
    try {
      await _overtimeDataSource.verifyOvertimes(
        siteId: widget.siteId,
        overtimeIds: [overtimeId],
      );
      
      await _audioService.playAttendanceSuccess('Verified');
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overtime verified successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying overtime: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showEthiopianDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      showEthiopian: _showEthiopianCalendar,
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedAttendanceIds.clear();
        _selectAll = false;
      });
      _loadData();
    }
  }

  void _toggleAttendance(int attendanceId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedAttendanceIds.add(attendanceId);
      } else {
        _selectedAttendanceIds.remove(attendanceId);
      }
      
      final selectableWorkers = _getSelectableWorkers();
      final selectableCount = selectableWorkers.where((w) {
        final attendance = _getAttendance(w.id!);
        return attendance != null && attendance.id != null && _canBeSelected(attendance.id!);
      }).length;
      
      _selectAll = _selectedAttendanceIds.length == selectableCount && selectableCount > 0;
    });
  }

  void _selectWorkPlace(String? workPlace) {
    setState(() {
      _selectedWorkPlace = workPlace;
      _filterWorkers(_searchController.text);
    });
  }

  Future<void> _submitBulkVerify() async {
    if (_selectedAttendanceIds.isEmpty) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.warning,
        message: 'Please select at least one attendance record',
      );
      return;
    }

    if (_isUnverifyMode) {
      await _submitBulkUnverify();
    } else {
      await _submitVerify();
    }
  }

  Future<void> _submitVerify() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Verify'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_showEthiopianCalendar ? EthiopianCalendar.formatEthiopian(EthiopianCalendar.fromGregorian(_selectedDate)) : DateFormat('MMMM d, yyyy').format(_selectedDate)}'),
            Text('Records: ${_selectedAttendanceIds.length}'),
            const SizedBox(height: 12),
            const Text(
              '⚠️ This will verify the selected attendance records.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _attendanceDataSource.verifyAttendances(
        attendanceIds: _selectedAttendanceIds.toList(),
      );

      await _audioService.playAttendanceSuccess('Verified');

      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.success,
          message: 'Successfully verified ${_selectedAttendanceIds.length} record(s)',
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await _audioService.playAttendanceError();
      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _submitBulkUnverify() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Confirm Bulk Unverify'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will unverify ${_selectedAttendanceIds.length} attendance record(s).',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Date: ${_showEthiopianCalendar ? EthiopianCalendar.formatEthiopian(EthiopianCalendar.fromGregorian(_selectedDate)) : DateFormat('MMMM d, yyyy').format(_selectedDate)}'),
            Text('Records: ${_selectedAttendanceIds.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unverify'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _attendanceDataSource.unverifyAttendances(
        attendanceIds: _selectedAttendanceIds.toList(),
      );

      await _audioService.playAttendanceSuccess('Unverified');

      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.success,
          message: 'Successfully unverified ${_selectedAttendanceIds.length} record(s)',
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await _audioService.playAttendanceError();
      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.verifyAttendance ?? 'Verify Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              setState(() {
                _showEthiopianCalendar = !_showEthiopianCalendar;
              });
            },
            tooltip: 'Toggle Calendar Type',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search workers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterWorkers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterWorkers,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildFilterBar(),
          if (_workPlaces.isNotEmpty) _buildWorkPlaceFilters(),
          if (_bulkMode == 'attendance') _buildSelectAllBar(),
          Expanded(child: _buildWorkerList()),
        ],
      ),
      bottomNavigationBar: _bulkMode == 'attendance' ? _buildBottomBar() : null,
    );
  }

  Widget _buildSummaryCard() {
    final totalAttendances = _getFilteredAttendances().length;
    final verifiedCount = _getFilteredAttendances().where((a) => a.isVerified).length;
    final unverifiedCount = totalAttendances - verifiedCount;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Attendance Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (totalAttendances > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: unverifiedCount == 0 ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: unverifiedCount == 0 ? Colors.green[300]! : Colors.orange[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          unverifiedCount == 0 ? Icons.verified : Icons.pending,
                          size: 16,
                          color: unverifiedCount == 0 ? Colors.green[700] : Colors.orange[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$verifiedCount/$totalAttendances verified',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: unverifiedCount == 0 ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (verifiedCount > 0)
                    InkWell(
                      onTap: _toggleMode,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isUnverifyMode ? Colors.orange[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isUnverifyMode ? Colors.orange[300]! : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isUnverifyMode ? Icons.undo : Icons.verified,
                              size: 16,
                              color: _isUnverifyMode ? Colors.orange[700] : Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isUnverifyMode ? 'Unverify' : 'Verify',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isUnverifyMode ? Colors.orange[700] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      _showEthiopianCalendar
                          ? () {
                              final ethiopianDate = EthiopianCalendar.fromGregorian(_selectedDate);
                              final weekday = _selectedDate.weekday;
                              final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                              return '${weekdays[weekday - 1]}, ${EthiopianCalendar.formatEthiopian(ethiopianDate)}';
                            }()
                          : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _bulkMode = 'attendance';
                          _selectedAttendanceIds.clear();
                          _selectAll = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _bulkMode == 'attendance' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _bulkMode == 'attendance'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: _bulkMode == 'attendance' ? Theme.of(context).primaryColor : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _bulkMode == 'attendance' ? FontWeight.bold : FontWeight.normal,
                                color: _bulkMode == 'attendance' ? Theme.of(context).primaryColor : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _bulkMode = 'overtime';
                          _selectedAttendanceIds.clear();
                          _selectAll = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _bulkMode == 'overtime' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _bulkMode == 'overtime'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: _bulkMode == 'overtime' ? Colors.orange[700] : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Overtime',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _bulkMode == 'overtime' ? FontWeight.bold : FontWeight.normal,
                                color: _bulkMode == 'overtime' ? Colors.orange[700] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_bulkMode == 'overtime') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Overtime verification mode: Select records with overtime to verify.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isUnverifyMode && verifiedCount > 0 && _bulkMode == 'attendance') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unverify mode: Select verified records to remove verification',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (unverifiedCount == 0 && totalAttendances > 0 && !_isUnverifyMode && _bulkMode == 'attendance') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All attendance records have been verified',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _statusFilter == 'all',
              onSelected: (_) => setState(() {
                _statusFilter = 'all';
                _selectedAttendanceIds.clear();
                _selectAll = false;
              }),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Present'),
              selected: _statusFilter == 'present',
              onSelected: (_) => setState(() {
                _statusFilter = 'present';
                _selectedAttendanceIds.clear();
                _selectAll = false;
              }),
              selectedColor: Colors.green.withOpacity(0.2),
              checkmarkColor: Colors.green,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Absent'),
              selected: _statusFilter == 'absent',
              onSelected: (_) => setState(() {
                _statusFilter = 'absent';
                _selectedAttendanceIds.clear();
                _selectAll = false;
              }),
              selectedColor: Colors.red.withOpacity(0.2),
              checkmarkColor: Colors.red,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Late'),
              selected: _statusFilter == 'late',
              onSelected: (_) => setState(() {
                _statusFilter = 'late';
                _selectedAttendanceIds.clear();
                _selectAll = false;
              }),
              selectedColor: Colors.orange.withOpacity(0.2),
              checkmarkColor: Colors.orange,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Excused'),
              selected: _statusFilter == 'excused',
              onSelected: (_) => setState(() {
                _statusFilter = 'excused';
                _selectedAttendanceIds.clear();
                _selectAll = false;
              }),
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkPlaceFilters() {
    final allCount = _allWorkers.length;
    final workPlaceCounts = <String, int>{};
    
    for (final worker in _allWorkers) {
      final place = worker.workPlaceName ?? 
        (worker.hierarchyLevel != null && worker.hierarchyLevel! <= 2 ? 'Site Management' : 'General Workforce');
      workPlaceCounts[place] = (workPlaceCounts[place] ?? 0) + 1;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: Text('All ($allCount)'),
              selected: _selectedWorkPlace == null,
              onSelected: (_) => _selectWorkPlace(null),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            ..._workPlaces.map((place) {
              final count = workPlaceCounts[place] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('$place ($count)'),
                  selected: _selectedWorkPlace == place,
                  onSelected: (_) => _selectWorkPlace(place),
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllBar() {
    final selectableWorkers = _getSelectableWorkers();
    final selectableCount = selectableWorkers.where((w) {
      final attendance = _getAttendance(w.id!);
      return attendance != null && attendance.id != null && _canBeSelected(attendance.id!);
    }).length;
    final workersWithAttendance = _getWorkersWithAttendance();
    final otherCount = workersWithAttendance.length - selectableCount;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isUnverifyMode ? Colors.orange[50] : Colors.blue[50],
      child: Row(
        children: [
          Checkbox(
            value: _selectAll,
            onChanged: selectableCount > 0 ? _toggleSelectAll : null,
            tristate: true,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select All (${_selectedAttendanceIds.length}/$selectableCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (otherCount > 0)
                  Text(
                    _isUnverifyMode
                        ? '$otherCount locked or not verified'
                        : '$otherCount already verified or locked',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isUnverifyMode ? Colors.orange[700] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedAttendanceIds.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _selectedAttendanceIds.clear();
                _selectAll = false;
              }),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayWorkers = _getDisplayWorkers();

    if (displayWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isUnverifyMode 
                  ? 'No verified attendance records found'
                  : 'No attendance records found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: displayWorkers.length,
      itemBuilder: (context, index) {
        final worker = displayWorkers[index];
        
        if (_bulkMode == 'overtime') {
          final overtime = _getOvertime(worker.id!);
          if (overtime != null && overtime.hours > 0) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              color: overtime.isVerified ? Colors.green[50] : Colors.orange[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: overtime.isVerified
                    ? BorderSide(color: Colors.green[300]!, width: 1.5)
                    : BorderSide(color: Colors.orange[300]!, width: 1.5),
              ),
              child: ListTile(
                onTap: () => _showOvertimeDialog(worker),
                leading: CircleAvatar(
                  backgroundColor: overtime.isVerified ? Colors.green[700] : Colors.orange[700],
                  child: Text(
                    worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        worker.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: overtime.isVerified ? Colors.green[700] : Colors.orange[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${overtime.hours}h',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (overtime.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Text('ID: ${worker.employeeId}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }
        }

        final attendance = _getAttendance(worker.id!)!;
        final isSelected = _selectedAttendanceIds.contains(attendance.id);
        final canBeSelected = attendance.id != null && _canBeSelected(attendance.id!);
        final isVerified = attendance.isVerified;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          color: _isUnverifyMode
              ? (isSelected ? Colors.orange[50] : Colors.green[50])
              : (isVerified 
                  ? Colors.green[50] 
                  : (isSelected ? Colors.blue[50] : null)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(
                    color: _isUnverifyMode ? Colors.orange : Theme.of(context).primaryColor, 
                    width: 2
                  )
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Checkbox(
              value: isSelected,
              onChanged: canBeSelected ? (value) => _toggleAttendance(attendance.id!, value) : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${worker.employeeId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (worker.workType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      worker.workType!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(attendance.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(attendance.status),
                      ),
                    ),
                    child: Text(
                      attendance.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(attendance.status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (attendance.checkInTime != null)
                    Text(
                      attendance.checkInTime!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  const Spacer(),
                  if (isVerified)
                    Icon(Icons.verified, size: 20, color: Colors.green[700])
                  else
                    Icon(Icons.pending, size: 20, color: Colors.orange[700]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected: ${_selectedAttendanceIds.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedAttendanceIds.isNotEmpty)
                    Text(
                      _isUnverifyMode ? 'Ready to unverify' : 'Ready to verify',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _selectedAttendanceIds.isEmpty || _isLoading ? null : _submitBulkVerify,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isUnverifyMode ? Icons.undo : Icons.verified),
              label: Text(_isLoading 
                  ? (_isUnverifyMode ? 'Unverifying...' : 'Verifying...') 
                  : (_isUnverifyMode ? 'Unverify' : 'Verify')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: _isUnverifyMode ? Colors.orange : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
