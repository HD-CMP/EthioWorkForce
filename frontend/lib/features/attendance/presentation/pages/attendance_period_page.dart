import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/attendance.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../../workers/data/datasources/site_remote_datasource.dart';
import '../../../workers/data/datasources/worker_remote_datasource.dart';
import '../../../workers/data/datasources/work_type_remote_datasource.dart';
import '../../../workers/domain/entities/site.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../workers/domain/entities/work_type.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import '../widgets/attendance_period_grid.dart';

class AttendancePeriodPage extends StatefulWidget {
  final int? siteId;

  const AttendancePeriodPage({super.key, this.siteId});

  @override
  State<AttendancePeriodPage> createState() => _AttendancePeriodPageState();
}

class _AttendancePeriodPageState extends State<AttendancePeriodPage> {
  final AttendanceRemoteDataSource _attendanceDataSource = AttendanceRemoteDataSource();
  final SiteRemoteDataSource _siteDataSource = SiteRemoteDataSource();
  final WorkerRemoteDataSource _workerDataSource = WorkerRemoteDataSource();
  final WorkTypeRemoteDataSource _workTypeDataSource = WorkTypeRemoteDataSource();

  List<Site> _sites = [];
  List<Worker> _workers = [];
  List<WorkType> _workTypes = [];
  Map<int, List<Attendance>> _workerAttendances = {};
  int? _currentSiteId;
  bool _isLoading = false;
  DateTime _periodStartDate = DateTime.now();

  final Map<int, Map<DateTime, String>> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    _initializeSite();
  }

  Future<void> _initializeSite() async {
    if (widget.siteId != null) {
      _currentSiteId = widget.siteId;
      _loadData();
    } else {
      await _loadSites();
    }
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    try {
      final sites = await _siteDataSource.getSites(isActive: true);
      setState(() {
        _sites = sites;
        if (sites.isNotEmpty) {
          _currentSiteId = sites.first.id;
        }
        _isLoading = false;
      });
      if (_currentSiteId != null) {
        _loadData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error loading sites: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (_currentSiteId == null) return;

    setState(() => _isLoading = true);
    try {
      await _loadWorkTypes();
      await _loadWorkers();
      await _loadAttendances();
      setState(() => _isLoading = false);
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

  Future<void> _loadWorkTypes() async {
    final workTypes = await _workTypeDataSource.getWorkTypes(isActive: true);
    setState(() {
      _workTypes = workTypes;
    });
  }

  Future<void> _loadWorkers() async {
    final workers = await _workerDataSource.getWorkers(
      siteId: _currentSiteId,
      status: 'active',
    );
    setState(() {
      _workers = workers;
    });
  }

  Future<void> _loadAttendances() async {
    _workerAttendances.clear();

    for (var worker in _workers) {
      if (worker.id == null) continue;

      final workType = _workTypes.firstWhere(
        (wt) => wt.id == worker.workTypeId,
        orElse: () => WorkType(
          name: 'Unknown',
          code: 'UNK',
          paymentMode: PaymentMode.dailyRate,
          baseRate: 0,
        ),
      );
      
      final periodDays = workType.paymentPeriodDays ?? 14;
      final endDate = _periodStartDate.add(Duration(days: periodDays - 1));

      try {
        final attendances = await _attendanceDataSource.getAttendances(
          siteId: _currentSiteId,
          dateFrom: _periodStartDate,
          dateTo: endDate,
        );

        final workerAttendances = attendances
            .where((a) => a.workerId == worker.id)
            .toList();

        _workerAttendances[worker.id!] = workerAttendances;
      } catch (e) {
        _workerAttendances[worker.id!] = [];
      }
    }

    setState(() {});
  }

  void _handleDayStatusChanged(int workerId, DateTime date, String status) {
    if (!_pendingChanges.containsKey(workerId)) {
      _pendingChanges[workerId] = {};
    }
    _pendingChanges[workerId]![date] = status;
  }

  Future<void> _saveAllChanges() async {
    if (_pendingChanges.isEmpty) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.warning,
        message: 'No changes to save',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int totalSaved = 0;

      for (var entry in _pendingChanges.entries) {
        final workerId = entry.key;
        final changes = entry.value;

        for (var dateEntry in changes.entries) {
          final date = dateEntry.key;
          final status = dateEntry.value;

          final existingAttendance = _workerAttendances[workerId]
              ?.firstWhere(
                (a) =>
                    a.attendanceDate.year == date.year &&
                    a.attendanceDate.month == date.month &&
                    a.attendanceDate.day == date.day,
                orElse: () => Attendance(
                  workerId: workerId,
                  siteId: _currentSiteId!,
                  attendanceDate: date,
                  status: status,
                  method: 'manual_entry',
                ),
              );

          if (existingAttendance?.id != null) {
            continue;
          }

          await _attendanceDataSource.createAttendance(
            workerId: workerId,
            siteId: _currentSiteId!,
            attendanceDate: date,
            checkInTime: '08:00:00',
            status: status,
            method: 'manual_entry',
          );

          totalSaved++;
        }
      }

      _pendingChanges.clear();
      await _loadAttendances();

      setState(() => _isLoading = false);

      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.success,
          message: 'Saved $totalSaved attendance records',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error saving: ${e.toString()}',
        );
      }
    }
  }

  void _selectPeriodStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _periodStartDate = picked;
      });
      _loadAttendances();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Period Attendance'),
        actions: [
          if (_pendingChanges.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_pendingChanges.values.fold<int>(0, (sum, map) => sum + map.length)} changes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _pendingChanges.isEmpty ? null : _saveAllChanges,
            tooltip: 'Save All Changes',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_sites.length > 1) _buildSiteSelector(),
          _buildPeriodSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildWorkersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0x1A007A3D),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 20),
          const SizedBox(width: 8),
          const Text('Site: ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: DropdownButton<int>(
              value: _currentSiteId,
              isExpanded: true,
              underline: Container(),
              items: _sites.map((site) {
                return DropdownMenuItem<int>(
                  value: site.id,
                  child: Text(site.name),
                );
              }).toList(),
              onChanged: (siteId) {
                if (siteId != null) {
                  setState(() {
                    _currentSiteId = siteId;
                  });
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            const Color(0xCC007A3D),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Period Start',
                  style: TextStyle(
                    color: const Color(0xB3FFFFFF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_periodStartDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _selectPeriodStartDate,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersList() {
    if (_workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No workers found',
              style: TextStyle(fontSize: 18, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workers.length,
      itemBuilder: (context, index) {
        final worker = _workers[index];
        if (worker.id == null) return const SizedBox.shrink();

        final workType = _workTypes.firstWhere(
          (wt) => wt.id == worker.workTypeId,
          orElse: () => WorkType(
            name: 'Unknown',
            code: 'UNK',
            paymentMode: PaymentMode.dailyRate,
            baseRate: 0,
          ),
        );

        final periodDays = workType.paymentPeriodDays ?? 14;
        final attendances = _workerAttendances[worker.id!] ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AttendancePeriodGrid(
            workerId: worker.id!,
            workerName: worker.fullName,
            periodStartDate: _periodStartDate,
            periodDays: periodDays,
            existingAttendances: attendances,
            onDayStatusChanged: (date, status) =>
                _handleDayStatusChanged(worker.id!, date, status),
          ),
        );
      },
    );
  }
}
