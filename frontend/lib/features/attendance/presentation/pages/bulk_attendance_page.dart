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

class BulkAttendancePage extends StatefulWidget {
  final int siteId;
  final DateTime selectedDate;

  const BulkAttendancePage({
    super.key,
    required this.siteId,
    required this.selectedDate,
  });

  @override
  State<BulkAttendancePage> createState() => _BulkAttendancePageState();
}

class _BulkAttendancePageState extends State<BulkAttendancePage> {
  final _attendanceDataSource = AttendanceRemoteDataSource();
  final _overtimeDataSource = OvertimeRemoteDataSource();
  final _workerDataSource = WorkerRemoteDataSource();
  final _audioService = AudioFeedbackService();
  final _searchController = TextEditingController();

  List<Worker> _allWorkers = [];
  List<Worker> _filteredWorkers = [];
  List<Attendance> _existingAttendances = [];
  List<Overtime> _existingOvertimes = [];
  final Set<int> _selectedWorkerIds = {};
  bool _isLoading = false;
  bool _selectAll = false;
  String _selectedStatus = 'present';
  TimeOfDay? _checkInTime;
  bool _isUnmarkMode = false;
  String? _selectedWorkPlace;
  List<String> _workPlaces = [];
  late DateTime _selectedDate;
  String _bulkMode = 'attendance';
  bool _showEthiopianCalendar = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _loadData();
    _checkInTime = const TimeOfDay(hour: 8, minute: 0);
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
      final dateFrom = _selectedDate.subtract(const Duration(days: 90));
      final dateTo = _selectedDate.add(const Duration(days: 90));
      
      final results = await Future.wait([
        _workerDataSource.getWorkers(siteId: widget.siteId, status: 'active'),
        _attendanceDataSource.getAttendances(
          siteId: widget.siteId,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ),
        _overtimeDataSource.getOvertimes(
          siteId: widget.siteId,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ),
      ]);
      
      setState(() {
        // BUSINESS RULE: Hierarchy 1 & 2 (Executive & Site Management) are NOT
        // clocked by timekeepers — they are salaried and self-managed.
        // Only Hierarchy 3+ (Operational workers) appear on the attendance grid.
        final attendanceEligibleWorkers = (results[0] as List<Worker>)
            .where((w) => w.hierarchyLevel == null || w.hierarchyLevel! > 1)
            .toList();
        
        _allWorkers = attendanceEligibleWorkers;
        _filteredWorkers = _allWorkers;
        _existingAttendances = results[1] as List<Attendance>;
        _existingOvertimes = results[2] as List<Overtime>;
        
        // Extract unique workplaces
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

  bool _hasAttendance(int workerId) {
    return _existingAttendances.any((a) => 
      a.workerId == workerId &&
      a.attendanceDate.year == _selectedDate.year &&
      a.attendanceDate.month == _selectedDate.month &&
      a.attendanceDate.day == _selectedDate.day
    );
  }

  Attendance? _getAttendance(int workerId) {
    try {
      return _existingAttendances.firstWhere((a) => 
        a.workerId == workerId &&
        a.attendanceDate.year == _selectedDate.year &&
        a.attendanceDate.month == _selectedDate.month &&
        a.attendanceDate.day == _selectedDate.day
      );
    } catch (e) {
      return null;
    }
  }

  List<Worker> _getUnmarkedWorkers() {
    return _filteredWorkers.where((w) => w.id != null && !_hasAttendance(w.id!)).toList();
  }

  List<Worker> _getMarkedWorkers() {
    return _filteredWorkers.where((w) => w.id != null && _hasAttendance(w.id!)).toList();
  }

  List<Worker> _getSelectableWorkers() {
    return _isUnmarkMode ? _getMarkedWorkers() : _getUnmarkedWorkers();
  }

  bool _canBeSelected(int workerId) {
    final hasAttendance = _hasAttendance(workerId);
    if (_isUnmarkMode) {
      // In unmark mode, only marked attendance can be selected
      return hasAttendance;
    } else {
      // In mark mode, only unmarked workers can be selected
      return !hasAttendance;
    }
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
        // Apply search filter
        if (query.isNotEmpty) {
          final nameLower = worker.fullName.toLowerCase();
          final idLower = worker.employeeId.toLowerCase();
          final queryLower = query.toLowerCase();
          if (!nameLower.contains(queryLower) && !idLower.contains(queryLower)) {
            return false;
          }
        }
        
        // Apply workplace filter
        if (_selectedWorkPlace != null) {
          return worker.workPlaceName == _selectedWorkPlace;
        }
        
        return true;
      }).toList();
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        // Select all workers that can be selected based on current mode
        final selectableWorkers = _getSelectableWorkers();
        _selectedWorkerIds.clear();
        _selectedWorkerIds.addAll(
          selectableWorkers
            .where((w) => w.id != null && _canBeSelected(w.id!))
            .map((w) => w.id!)
        );
      } else {
        _selectedWorkerIds.clear();
      }
    });
  }

  void _toggleWorker(int workerId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedWorkerIds.add(workerId);
      } else {
        _selectedWorkerIds.remove(workerId);
      }
      final selectableWorkers = _getSelectableWorkers();
      final selectableCount = selectableWorkers.where((w) => w.id != null && _canBeSelected(w.id!)).length;
      _selectAll = _selectedWorkerIds.length == selectableCount && selectableCount > 0;
    });
  }

  void _toggleMode() {
    setState(() {
      _isUnmarkMode = !_isUnmarkMode;
      _selectedWorkerIds.clear();
      _selectAll = false;
    });
  }

  Future<void> _showOvertimeDialog(Worker worker) async {
    final existingOvertime = _existingOvertimes.firstWhere(
      (o) => o.workerId == worker.id && 
             o.overtimeDate.year == _selectedDate.year &&
             o.overtimeDate.month == _selectedDate.month &&
             o.overtimeDate.day == _selectedDate.day,
      orElse: () => Overtime(
        workerId: worker.id!,
        siteId: widget.siteId,
        overtimeDate: _selectedDate,
        hours: 0,
      ),
    );

    final overtimeController = TextEditingController(
      text: existingOvertime.hours > 0 ? existingOvertime.hours.toString() : '',
    );
    
    String dateText;
    if (_showEthiopianCalendar) {
      final ethiopianDate = EthiopianCalendar.fromGregorian(_selectedDate);
      dateText = EthiopianCalendar.formatEthiopian(ethiopianDate);
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(_selectedDate);
    }
    
    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Overtime Hours',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 8),
              Text(
                'Date: $dateText',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter overtime hours for this worker',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: overtimeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Hours',
                  hintText: 'Enter hours (e.g., 1.5, 2.0)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixText: 'hours',
                  helperText: 'Decimal values allowed (e.g., 0.5 for half hour)',
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          if (existingOvertime.hours > 0)
            TextButton(
              onPressed: () => Navigator.pop(context, 0.0),
              child: Text('Clear', style: TextStyle(color: Colors.red[600])),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hours = double.tryParse(overtimeController.text) ?? 0.0;
              if (hours >= 0 && hours <= 24) {
                Navigator.pop(context, hours);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a value between 0 and 24'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveOvertimeForWorker(worker, result, existingOvertime);
    }
  }

  Future<void> _saveOvertimeForWorker(
    Worker worker, 
    double hours,
    Overtime existingOvertime,
  ) async {
    setState(() => _isLoading = true);
    try {
      if (hours == 0 && existingOvertime.id != null) {
        // Delete overtime record
        await _overtimeDataSource.deleteOvertime(existingOvertime.id!);
      } else if (existingOvertime.id != null) {
        // Update existing overtime
        await _overtimeDataSource.updateOvertime(
          id: existingOvertime.id!,
          hours: hours,
        );
      } else if (hours > 0) {
        // Create new overtime record
        await _overtimeDataSource.createOvertime(
          workerId: worker.id!,
          siteId: widget.siteId,
          overtimeDate: _selectedDate,
          hours: hours,
        );
      }
      
      await _audioService.playAttendanceSuccess('Saved');
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hours > 0 
              ? 'Saved: ${worker.fullName} - ${hours}h overtime'
              : 'Overtime cleared: ${worker.fullName}'
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving overtime: $e'),
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
        _selectedWorkerIds.clear();
        _selectAll = false;
      });
      _loadData();
    }
  }

  void _selectWorkPlace(String? workPlace) {
    setState(() {
      _selectedWorkPlace = workPlace;
      _filterWorkers(_searchController.text);
      _selectedWorkerIds.clear();
      _selectAll = false;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _checkInTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _checkInTime = picked;
      });
    }
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _submitBulkAttendance() async {
    if (_selectedWorkerIds.isEmpty) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.warning,
        message: 'Please select at least one worker',
      );
      return;
    }

    if (_isUnmarkMode) {
      await _submitBulkUnmark();
    } else {
      await _submitBulkMark();
    }
  }

  Future<void> _submitBulkMark() async {
    String dateText;
    if (_showEthiopianCalendar) {
      final ethiopianDate = EthiopianCalendar.fromGregorian(_selectedDate);
      dateText = EthiopianCalendar.formatEthiopian(ethiopianDate);
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(_selectedDate);
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Mark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $dateText'),
            Text('Workers: ${_selectedWorkerIds.length}'),
            Text('Status: ${_selectedStatus.toUpperCase()}'),
            if (_checkInTime != null)
              Text('Check-in Time: ${_checkInTime!.format(context)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _attendanceDataSource.createBulkAttendance(
        siteId: widget.siteId,
        attendanceDate: _selectedDate,
        workerIds: _selectedWorkerIds.toList(),
        method: 'manual_entry',
        status: _selectedStatus,
        checkInTime: _checkInTime != null ? _timeToString(_checkInTime!) : null,
      );

      await _audioService.playAttendanceSuccess('Bulk Registered');

      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.success,
          message: 'Successfully marked attendance for ${_selectedWorkerIds.length} workers',
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

  Future<void> _submitBulkUnmark() async {
    final attendancesToDelete = <Attendance>[];

    for (final workerId in _selectedWorkerIds) {
      final attendance = _getAttendance(workerId);
      if (attendance != null) {
        attendancesToDelete.add(attendance);
      }
    }

    if (attendancesToDelete.isEmpty) {
      return;
    }

    String dateText;
    if (_showEthiopianCalendar) {
      final ethiopianDate = EthiopianCalendar.fromGregorian(_selectedDate);
      dateText = EthiopianCalendar.formatEthiopian(ethiopianDate);
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(_selectedDate);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Confirm Bulk Unmark'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete ${attendancesToDelete.length} attendance record(s).',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Date: $dateText'),
            Text('Workers: ${attendancesToDelete.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      int deletedCount = 0;
      for (final attendance in attendancesToDelete) {
        if (attendance.id != null) {
          await _attendanceDataSource.deleteAttendance(attendance.id!);
          deletedCount++;
        }
      }

      await _audioService.playAttendanceSuccess('Unmarked');

      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.success,
          message: 'Successfully unmarked $deletedCount attendance record(s)',
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
        title: Text(localizations?.markAttendance ?? 'Mark Attendance'),
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
      body: _buildScrollableBody(),
      bottomNavigationBar: _bulkMode == 'attendance' ? _buildBottomBar() : null,
    );
  }

  Widget _buildScrollableBody() {
    if (_isLoading && _filteredWorkers.isEmpty) {
      return Column(
        children: [
          _buildSettingsCard(),
          if (_workPlaces.isNotEmpty) _buildWorkPlaceFilters(),
          if (_bulkMode == 'attendance') _buildSelectAllBar(),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    // Build all items into one unified scrollable list
    return CustomScrollView(
      slivers: [
        // Settings card
        SliverToBoxAdapter(child: _buildSettingsCard()),
        // Workplace filter chips
        if (_workPlaces.isNotEmpty)
          SliverToBoxAdapter(child: _buildWorkPlaceFilters()),
        // Select-all bar
        if (_bulkMode == 'attendance')
          SliverToBoxAdapter(child: _buildSelectAllBar()),
        // Worker cards - all in the same scroll view
        if (_filteredWorkers.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No workers found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildWorkerCard(index),
                childCount: _filteredWorkers.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkerCard(int index) {
    final worker = _filteredWorkers[index];
    final isSelected = _selectedWorkerIds.contains(worker.id);
    final hasAttendance = worker.id != null && _hasAttendance(worker.id!);
    final attendance = hasAttendance ? _getAttendance(worker.id!) : null;
    final canBeSelected = worker.id != null && _canBeSelected(worker.id!);
    final overtime = worker.id != null ? _existingOvertimes.firstWhere(
      (o) => o.workerId == worker.id &&
             o.overtimeDate.year == _selectedDate.year &&
             o.overtimeDate.month == _selectedDate.month &&
             o.overtimeDate.day == _selectedDate.day,
      orElse: () => Overtime(workerId: worker.id!, siteId: widget.siteId, overtimeDate: _selectedDate, hours: 0),
    ) : null;
    final hasOvertime = overtime != null && overtime.hours > 0;

    if (_bulkMode == 'overtime') {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        color: hasOvertime ? Colors.orange[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasOvertime
              ? BorderSide(color: Colors.orange[300]!, width: 1.5)
              : BorderSide.none,
        ),
        child: ListTile(
          onTap: () => _showOvertimeDialog(worker),
          leading: CircleAvatar(
            backgroundColor: hasOvertime ? Colors.orange[700] : Theme.of(context).primaryColor,
            child: Text(
              worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(worker.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (hasOvertime) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange[700], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${overtime!.hours}h', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text('ID: ${worker.employeeId}'),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: hasAttendance
          ? (_isUnmarkMode && isSelected ? Colors.red[50] : Colors.green[50])
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: _isUnmarkMode ? Colors.red : Theme.of(context).primaryColor, width: 2)
            : hasAttendance
                ? BorderSide(color: Colors.green[300]!, width: 1.5)
                : BorderSide.none,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: canBeSelected && worker.id != null
            ? (value) => _toggleWorker(worker.id!, value)
            : null,
        enabled: canBeSelected,
        title: Row(
          children: [
            Expanded(
              child: Text(worker.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: hasAttendance && !_isUnmarkMode ? Colors.grey[600] : null,
                  )),
            ),
            if (hasAttendance && attendance != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(attendance.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(attendance.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('ID: ${worker.employeeId}',
                style: TextStyle(color: hasAttendance && !_isUnmarkMode ? Colors.grey[600] : null)),
            if (hasAttendance && attendance != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(attendance.checkInTime ?? 'No check-in time',
                        style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500)),
                    if (attendance.isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.verified, size: 12, color: Colors.green[900]),
                    ],
                  ],
                ),
              ),
          ],
        ),
        secondary: CircleAvatar(
          backgroundColor: _isUnmarkMode
              ? (isSelected ? Colors.red[600] : (hasAttendance ? Colors.green[600] : Colors.grey[300]))
              : (hasAttendance
                  ? Colors.green[600]
                  : isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]),
          child: Icon(
            _isUnmarkMode && hasAttendance
                ? (isSelected ? Icons.remove_circle : Icons.check)
                : hasAttendance
                    ? Icons.check
                    : Icons.person,
            color: hasAttendance || isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    final totalWorkers = _filteredWorkers.length;
    final markedCount = _filteredWorkers.where((w) => w.id != null && _hasAttendance(w.id!)).length;
    final unmarkedCount = totalWorkers - markedCount;
    
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
                    'Attendance Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (totalWorkers > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: unmarkedCount == 0 ? Colors.green[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: unmarkedCount == 0 ? Colors.green[300]! : Colors.blue[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          unmarkedCount == 0 ? Icons.check_circle : Icons.pending_actions,
                          size: 16,
                          color: unmarkedCount == 0 ? Colors.green[700] : Colors.blue[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$markedCount/$totalWorkers marked',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: unmarkedCount == 0 ? Colors.green[700] : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (markedCount > 0)
                    InkWell(
                      onTap: _toggleMode,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isUnmarkMode ? Colors.red[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isUnmarkMode ? Colors.red[300]! : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isUnmarkMode ? Icons.undo : Icons.edit,
                              size: 16,
                              color: _isUnmarkMode ? Colors.red[700] : Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isUnmarkMode ? 'Unmark' : 'Mark',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isUnmarkMode ? Colors.red[700] : Colors.grey[700],
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showEthiopianCalendar
                                ? () {
                                    final ethiopianDate = EthiopianCalendar.fromGregorian(_selectedDate);
                                    final weekday = _selectedDate.weekday;
                                    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                                    return '${weekdays[weekday - 1]}, ${EthiopianCalendar.formatEthiopian(ethiopianDate)}';
                                  }()
                                : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _showEthiopianCalendar ? 'Ethiopian Calendar' : 'Gregorian Calendar',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
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
                          _selectedWorkerIds.clear();
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
                          _selectedWorkerIds.clear();
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
            if (unmarkedCount == 0 && totalWorkers > 0 && !_isUnmarkMode && _bulkMode == 'attendance') ...[
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
                    Icon(Icons.info_outline, size: 20, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All workers have been marked for this date',
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
            if (_isUnmarkMode && markedCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unmark mode: Select marked workers to remove their attendance',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_bulkMode == 'attendance' && !_isUnmarkMode) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'present', child: Text('Present')),
                        DropdownMenuItem(value: 'absent', child: Text('Absent')),
                        DropdownMenuItem(value: 'late', child: Text('Late')),
                        DropdownMenuItem(value: 'leave', child: Text('Leave')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Check-in Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _checkInTime?.format(context) ?? 'Not Set',
                          style: TextStyle(
                            color: _checkInTime != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                        'Overtime mode: Click on workers to enter overtime and set attendance status. Workers can have overtime without being present for regular hours.',
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
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllBar() {
    final selectableWorkers = _getSelectableWorkers();
    final selectableCount = selectableWorkers.where((w) => w.id != null && _canBeSelected(w.id!)).length;
    final otherCount = _filteredWorkers.length - selectableCount;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isUnmarkMode ? Colors.red[50] : Colors.grey[100],
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
                  'Select All (${_selectedWorkerIds.length}/$selectableCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (otherCount > 0)
                  Text(
                    _isUnmarkMode 
                      ? '$otherCount not marked yet'
                      : '$otherCount already marked',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isUnmarkMode ? Colors.grey[600] : Colors.green[700],
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedWorkerIds.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _selectedWorkerIds.clear();
                _selectAll = false;
              }),
              child: const Text('Clear'),
            ),
        ],
      ),
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
            blurRadius: 4,
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
                    '${_selectedWorkerIds.length} Worker(s) Selected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isUnmarkMode)
                    Text(
                      'Status: ${_selectedStatus.toUpperCase()}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    )
                  else
                    Text(
                      'Action: UNMARK',
                      style: TextStyle(fontSize: 14, color: Colors.red[600], fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitBulkAttendance,
              style: _isUnmarkMode
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_isUnmarkMode ? Icons.delete : Icons.check),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(_isUnmarkMode ? 'Unmark Attendance' : 'Mark Attendance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
