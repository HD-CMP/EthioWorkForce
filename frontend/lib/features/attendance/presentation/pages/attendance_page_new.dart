import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/attendance.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../../workers/data/datasources/site_remote_datasource.dart';
import '../../../workers/data/datasources/worker_remote_datasource.dart';
import '../../../workers/domain/entities/site.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../overtime/domain/entities/overtime.dart';
import '../../../overtime/data/datasources/overtime_remote_datasource.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import '../../../../core/widgets/ethiopian_date_picker.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import 'qr_scanner_page.dart';
import 'attendance_detail_page.dart';
import 'bulk_attendance_page.dart';
import 'bulk_verify_page.dart';
import '../widgets/hierarchical_attendance_list.dart';
import '../widgets/hierarchical_workers_list.dart';

class AttendancePageNew extends StatefulWidget {
  final int? siteId;

  const AttendancePageNew({
    super.key,
    this.siteId,
  });

  @override
  State<AttendancePageNew> createState() => _AttendancePageNewState();
}

class _AttendancePageNewState extends State<AttendancePageNew> {
  final AudioFeedbackService _audioService = AudioFeedbackService();
  final AttendanceRemoteDataSource _dataSource = AttendanceRemoteDataSource();
  final OvertimeRemoteDataSource _overtimeDataSource = OvertimeRemoteDataSource();
  final SiteRemoteDataSource _siteDataSource = SiteRemoteDataSource();
  final WorkerRemoteDataSource _workerDataSource = WorkerRemoteDataSource();
  final StorageService _storageService = StorageService();
  
  DateTime _selectedDate = DateTime.now();
  String _calendarType = 'Ethiopian';
  bool _showEthiopianCalendar = true;
  bool _isLoading = false;
  bool _showOnlyUnverified = false;
  String _statusFilter = 'all';
  int _currentTabIndex = 0;
  List<Attendance> _allAttendances = []; // Unfiltered for data operations
  List<Overtime> _allOvertimes = [];
  String? _userRole;
  bool _isSuperAdmin = false;
  bool _hasWorkplaceAssignment = true;
  bool _checkingWorkplaceAssignment = true;

  bool get _canVerifyAttendance {
    final role = _userRole?.toLowerCase() ?? '';
    return role == 'super_admin' ||
        role == 'admin' ||
        role == 'site_admin' ||
        role == 'site_manager' ||
        role == 'site_engineer';
  }
  
  List<Attendance> _attendances = [];
  Map<String, dynamic>? _statistics;
  List<Site> _sites = [];
  List<int> _allowedWorkplaceIds = [];
  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  int? _currentSiteId;
  String? _selectedWorkPlace;
  
  final List<int> _selectedAttendanceIds = [];
  final List<int> _selectedWorkerIds = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _checkCurrentUserWorkplaceAssignment();
    _initializeSite();
  }

  Future<void> _loadUserRole() async {
    final role = await _storageService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isSuperAdmin = role == 'super_admin';
        // Site Engineer / Site Manager / Admins start on Attendance tab (0)
        // Others (Foremen, Timekeepers) start on Workers roster tab (1)
        _currentTabIndex = _canVerifyAttendance ? 0 : 1;
      });
    }
  }

  Future<void> _checkCurrentUserWorkplaceAssignment() async {
    try {
      final dio = getIt<Dio>();
      final response = await dio.get('/users/me');
      final currentUser = response.data;
      final role = currentUser['role'] as String?;
      final workplaceAssignments = currentUser['work_place_assignments'] as List<dynamic>? ?? [];
      final siteAssignments = currentUser['site_assignments'] as List<dynamic>? ?? [];
      
      final roleLower = (role ?? '').toLowerCase();
      final isSuper = roleLower == 'super_admin';
      final isPrivileged = isSuper ||
          roleLower == 'admin' ||
          roleLower == 'site_admin' ||
          roleLower == 'site_manager' ||
          roleLower == 'site_engineer';

      if (mounted) {
        setState(() {
          _isSuperAdmin = isSuper;
          _userRole = roleLower;
          _hasWorkplaceAssignment = workplaceAssignments.isNotEmpty || siteAssignments.isNotEmpty || isPrivileged;
          _checkingWorkplaceAssignment = false;
          
          _allowedWorkplaceIds = workplaceAssignments
              .map((wp) => wp['work_place']?['id'] as int?)
              .whereType<int>()
              .toList();
        });
        
        if (!isSuper && workplaceAssignments.isNotEmpty) {
          final firstWorkplace = workplaceAssignments[0] as Map<String, dynamic>;
          final siteId = firstWorkplace['work_place']?['site_id'] as int?;
          if (siteId != null && _currentSiteId == null) {
            _currentSiteId = siteId;
            await _storageService.setSelectedSiteId(siteId);
          }
        } else if (!isSuper && siteAssignments.isNotEmpty) {
          final firstSite = siteAssignments[0] as Map<String, dynamic>;
          final siteId = firstSite['site']?['id'] as int? ?? firstSite['site_id'] as int?;
          if (siteId != null && _currentSiteId == null) {
            _currentSiteId = siteId;
            await _storageService.setSelectedSiteId(siteId);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingWorkplaceAssignment = false;
        });
      }
    }
  }

  Future<void> _initializeSite() async {
    if (widget.siteId != null) {
      _currentSiteId = widget.siteId;
      await _storageService.setSelectedSiteId(widget.siteId!);
      _loadData();
    } else {
      await _loadSites();
      
      final savedSiteId = await _storageService.getSelectedSiteId();
      if (savedSiteId != null && _sites.any((s) => s.id == savedSiteId)) {
        _currentSiteId = savedSiteId;
      } else if (_sites.isNotEmpty && _currentSiteId == null) {
        _currentSiteId = _sites.first.id;
        if (_currentSiteId != null) {
          await _storageService.setSelectedSiteId(_currentSiteId!);
        }
      }
      
      if (_currentSiteId != null) {
        _loadData();
      }
    }
  }

  Future<void> _loadSites() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final sites = await _siteDataSource.getSites(isActive: true);
      if (mounted) {
        setState(() {
          _sites = sites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error loading sites: ${e.toString()}',
        );
      }
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  int get _uniqueWorkersWithAttendance {
    return _attendances.map((a) => a.workerId).toSet().length;
  }

  List<String> get _workPlaces {
    final places = _workers
        .map((w) => w.workPlaceName ?? 'General Workforce')
        .toSet()
        .toList();
    places.sort((a, b) {
      if (a == 'General Workforce') return 1;
      if (b == 'General Workforce') return -1;
      return a.compareTo(b);
    });
    return places;
  }

  List<Worker> get _displayedWorkers {
    if (_selectedWorkPlace == null) return _workers;
    return _workers.where((w) => 
      (w.workPlaceName ?? 'General Workforce') == _selectedWorkPlace
    ).toList();
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadWorkers(); // Load workers first since attendances depend on it
      await Future.wait([
        _loadAttendances(),
        _loadStatistics(),
      ]);
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

  Future<void> _loadAttendances() async {
    if (_currentSiteId == null) {
      setState(() {
        _allAttendances = [];
        _attendances = [];
        _allOvertimes = [];
      });
      return;
    }
    
    try {
      // Load attendances and overtimes for a date range (90 days before and after selected date)
      // This ensures multiple payment periods are covered for multi-day marking
      final dateFrom = _selectedDate.subtract(const Duration(days: 90));
      final dateTo = _selectedDate.add(const Duration(days: 90));
      
      final results = await Future.wait([
        _dataSource.getAttendances(
          siteId: _currentSiteId!,
          dateFrom: dateFrom,
          dateTo: dateTo,
          isVerified: null, // ALWAYS fetch all so frontend can accurately know who has verified attendance
          limit: 5000,
        ),
        _overtimeDataSource.getOvertimes(
          siteId: _currentSiteId!,
          dateFrom: dateFrom,
          dateTo: dateTo,
          isVerified: null,
        ),
      ]);
      
      final attendances = results[0] as List<Attendance>;
      final overtimes = results[1] as List<Overtime>;
      
      // Filter attendances for selected date only
      List<Attendance> todayAttendances = attendances.where((a) => 
        a.attendanceDate.year == _selectedDate.year &&
        a.attendanceDate.month == _selectedDate.month &&
        a.attendanceDate.day == _selectedDate.day
      ).toList();
      
      // Create a map of worker IDs to their attendance for quick lookup
      final Map<int, Attendance?> workerAttendanceMap = {};
      for (var worker in _workers) {
        if (worker.id != null) {
          workerAttendanceMap[worker.id!] = null;
        }
      }
      for (var attendance in todayAttendances) {
        workerAttendanceMap[attendance.workerId] = attendance;
      }
      
      // Determine which workers to show based on filters
      List<Worker> filteredWorkers = [];
      List<Attendance> filteredAttendances = [];
      
      if (_statusFilter == 'all' && !_showOnlyUnverified) {
        // Show all workers
        filteredWorkers = List<Worker>.from(_workers);
        filteredAttendances = List<Attendance>.from(todayAttendances);
      } else {
        // Filter workers and attendance based on criteria
        Set<int> directMatchWorkerIds = {};
        for (var worker in _workers) {
          if (worker.id == null) continue;
          
          final attendance = workerAttendanceMap[worker.id!];
          bool shouldInclude = false;
          
          if (_statusFilter != 'all') {
            if (attendance != null && attendance.status == _statusFilter) {
              if (!_showOnlyUnverified || !attendance.isVerified) {
                shouldInclude = true;
              }
            }
          } else if (_showOnlyUnverified) {
            // Unverified only includes workers with NO attendance, or unverified attendance
            if (attendance == null || !attendance.isVerified) {
              shouldInclude = true;
            }
          }
          
          if (shouldInclude) {
            directMatchWorkerIds.add(worker.id!);
          }
        }
        
        // Do NOT forcibly include supervisors just to maintain the hierarchy tree.
        // If 'Unverified Only' is checked, the user wants ONLY unverified workers,
        // and verified supervisors should disappear (their subordinates will just show at root level).
        Set<int> workersToInclude = {...directMatchWorkerIds};
        
        // Build the final lists
        for (var worker in _workers) {
          if (worker.id != null && workersToInclude.contains(worker.id!)) {
            filteredWorkers.add(worker);
            final att = workerAttendanceMap[worker.id!];
            if (att != null) {
              filteredAttendances.add(att);
            }
          }
        }
      }
      

      // Update state atomically after all filtering is complete
      if (mounted) {
        setState(() {
          _allAttendances = List<Attendance>.from(attendances);
          _allOvertimes = List<Overtime>.from(overtimes);
          _attendances = filteredAttendances;
          _filteredWorkers = filteredWorkers;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allAttendances = [];
          _attendances = [];
          _allOvertimes = [];
          _filteredWorkers = _workers; // Reset to show all workers on error
        });
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error loading data: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    if (_currentSiteId == null) return;
    
    try {
      final stats = await _dataSource.getStatistics(
        siteId: _currentSiteId!,
        dateFrom: _selectedDate,
        dateTo: _selectedDate,
      );
      
      if (mounted) {
        setState(() {
          _statistics = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statistics = null;
        });
      }
    }
  }

  Future<void> _loadWorkers() async {
    if (_currentSiteId == null) return;
    
    try {
      final workers = await _workerDataSource.getWorkers(
        siteId: _currentSiteId,
        status: 'active',
      );
      
      if (mounted) {
        // Filter workers if the user has specific workplace assignments
        List<Worker> allowedWorkers = workers;
        if (!_isSuperAdmin && _allowedWorkplaceIds.isNotEmpty) {
          allowedWorkers = workers.where((w) {
            return w.workPlaceId != null && _allowedWorkplaceIds.contains(w.workPlaceId);
          }).toList();
        } else if (!_isSuperAdmin && !_canVerifyAttendance && !_hasWorkplaceAssignment) {
          // If not super admin, not site engineer/manager, and has no assignments, show empty
          allowedWorkers = [];
        }

        setState(() {
          _workers = allowedWorkers;
          _filteredWorkers = allowedWorkers; // Initially show all valid workers
          _selectedWorkerIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error loading workers: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _markSelectedWorkersPresent() async {
    if (_selectedWorkerIds.isEmpty) return;
    if (_currentSiteId == null) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.error,
        message: 'No site selected',
      );
      return;
    }
    
    try {
      setState(() => _isLoading = true);
      
      await _dataSource.createBulkAttendance(
        siteId: _currentSiteId!,
        attendanceDate: _selectedDate,
        workerIds: _selectedWorkerIds,
        checkInTime: _formatTimeForApi(TimeOfDay.now()),
        status: 'present',
        method: 'manual_entry',
      );
      
      await _audioService.playAttendanceSuccess('Marked ${_selectedWorkerIds.length} workers');
      
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.success,
        message: 'Attendance Marked',
        subtitle: '${_selectedWorkerIds.length} workers marked present',
      );
      
      setState(() {
        _selectedWorkerIds.clear();
      });
      
      _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.error,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  Future<void> _openQRScanner() async {
    if (_currentSiteId == null) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.error,
        message: 'No site selected',
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (result != null && mounted) {
      final workerId = result['worker_id'] as int;
      final employeeId = result['employee_id'] as String;
      
      try {
        await _dataSource.createAttendance(
          workerId: workerId,
          siteId: _currentSiteId!,
          attendanceDate: _selectedDate,
          checkInTime: _formatTimeForApi(TimeOfDay.now()),
          status: 'present',
          method: 'qr_scan',
        );
        
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.success,
          message: AppLocalizations.of(context)?.registered ?? 'Attendance Registered',
          subtitle: 'Employee: $employeeId',
        );
        
        _loadData();
      } catch (e) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
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
      });
      _loadData();
    }
  }

  Future<void> _verifySelected() async {
    if (!_canVerifyAttendance) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.warning,
        message: 'Verification authority is restricted to Site Engineers, Site Managers, and Admins',
      );
      return;
    }

    if (_selectedAttendanceIds.isEmpty) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.warning,
        message: 'No attendance records selected',
      );
      return;
    }

    // Exclude any records that are locked by payroll
    final lockedRecords = _allAttendances.where((a) => _selectedAttendanceIds.contains(a.id) && a.isLocked).toList();
    if (lockedRecords.isNotEmpty) {
      setState(() {
        _selectedAttendanceIds.removeWhere((id) => lockedRecords.any((lr) => lr.id == id));
      });
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.warning,
        message: '${lockedRecords.length} record(s) are sealed for payroll and cannot be verified',
      );
      if (_selectedAttendanceIds.isEmpty) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.verified, color: Color(0xFF007A3D)),
            SizedBox(width: 8),
            Text('Verify Attendance'),
          ],
        ),
        content: Text(
          'Are you sure you want to verify ${_selectedAttendanceIds.length} attendance record(s)?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A3D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _dataSource.verifyAttendances(
          attendanceIds: _selectedAttendanceIds,
        );
        
        await _audioService.playAttendanceSuccess('Verified');
        
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.success,
          message: 'Successfully verified ${_selectedAttendanceIds.length} records',
        );
        
        setState(() => _selectedAttendanceIds.clear());
        _loadData();
      } catch (e) {
        setState(() => _isLoading = false);
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _openBulkAttendance() async {
    if (_currentSiteId == null) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.error,
        message: 'No site selected',
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BulkAttendancePage(
          siteId: _currentSiteId!,
          selectedDate: _selectedDate,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openBulkVerify() async {
    if (_currentSiteId == null) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.error,
        message: 'No site selected',
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BulkVerifyPage(
          siteId: _currentSiteId!,
          selectedDate: _selectedDate,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openAttendanceDetail(Attendance? attendance) async {
    if (_currentSiteId == null) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.error,
        message: 'No site selected',
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceDetailPage(
          attendance: attendance,
          siteId: _currentSiteId!,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
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
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.event_available;
      case 'leave':
        return Icons.beach_access;
      case 'half_day':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.attendance ?? 'Attendance',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentSiteId != null && _sites.isNotEmpty)
              Text(
                _sites.firstWhere((s) => s.id == _currentSiteId, orElse: () => _sites.first).name,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (_sites.length > 1)
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed: _showSiteSelectorDialog,
              tooltip: 'Select Site',
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {
              setState(() {
                _showEthiopianCalendar = !_showEthiopianCalendar;
                _calendarType = _showEthiopianCalendar ? 'Ethiopian' : 'Gregorian';
              });
            },
            tooltip: 'Toggle Calendar Type',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'export') {
                // TODO: Implement export
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF007A3D),
        onRefresh: () async {
          await _loadData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(dateFormat)),
            SliverToBoxAdapter(child: _buildTabBar()),
            if (_currentTabIndex == 0)
              SliverToBoxAdapter(child: _buildStatistics()),
            SliverToBoxAdapter(child: _buildFilterBar()),
            if (_currentTabIndex == 0 && _canVerifyAttendance)
              SliverToBoxAdapter(child: _buildSelectionBar()),
            _currentTabIndex == 0
                ? _buildAttendanceSliverList()
                : _buildWorkersSliverList(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(DateFormat dateFormat) {
    String formattedDate;
    String dayOfWeek;
    
    if (_showEthiopianCalendar) {
      final ethiopianDate = EthiopianCalendar.fromGregorian(_selectedDate);
      formattedDate = EthiopianCalendar.formatEthiopian(ethiopianDate);
      
      final weekday = _selectedDate.weekday;
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      dayOfWeek = weekdays[weekday - 1];
    } else {
      formattedDate = dateFormat.format(_selectedDate);
      dayOfWeek = '';
    }
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF005C2E),
            Color(0xFF007A3D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showEthiopianCalendar && dayOfWeek.isNotEmpty 
                        ? '$dayOfWeek, $formattedDate' 
                        : formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_calendarType Calendar',
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.date_range, color: Colors.white),
              onPressed: () => _selectDate(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSiteSelectorDialog() {
    try {
      if (_sites.isEmpty) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.warning,
          message: 'No sites available',
        );
        return;
      }
      
      final sites = List<Site>.from(_sites);
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_city, color: Color(0xFF007A3D), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Construction Site',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A192F),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sites.length} sites',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final site = sites[index];
                      final isSelected = _currentSiteId == site.id;
                      return InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          if (!isSelected && site.id != null) {
                            setState(() {
                              _currentSiteId = site.id;
                              _selectedAttendanceIds.clear();
                              _selectedWorkerIds.clear();
                            });
                            await _storageService.setSelectedSiteId(site.id!);
                            _loadData();
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8F5EE) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    site.code.isNotEmpty
                                        ? site.code.substring(0, site.code.length > 3 ? 3 : site.code.length)
                                        : 'STE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      site.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: const Color(0xFF0A192F),
                                      ),
                                    ),
                                    if (site.locationAddress != null && site.locationAddress!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        site.locationAddress!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF007A3D), size: 22)
                              else
                                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // Handle hot reload error
    }
  }

  Widget _buildTabBar() {
    // For Foremen and Timekeepers (roles below Site Engineer), only show Workers roster
    // where they mark and alter daily attendance.
    if (!_canVerifyAttendance) {
      return Container(
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF007A3D), width: 3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 20, color: Color(0xFF007A3D)),
              const SizedBox(width: 8),
              Text(
                'Workers (${_workers.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007A3D), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // For Site Engineers, Site Managers, and Admins: show BOTH tabs:
    // Tab 0: Attendance (to review, filter, audit and verify entries)
    // Tab 1: Workers (roster)
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _currentTabIndex == 0 ? const Color(0xFF007A3D) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 20,
                      color: _currentTabIndex == 0 ? const Color(0xFF007A3D) : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance ($_uniqueWorkersWithAttendance)',
                      style: TextStyle(
                        fontWeight: _currentTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _currentTabIndex == 0 ? const Color(0xFF007A3D) : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _currentTabIndex == 1 ? const Color(0xFF007A3D) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 20,
                      color: _currentTabIndex == 1 ? const Color(0xFF007A3D) : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Workers (${_workers.length})',
                      style: TextStyle(
                        fontWeight: _currentTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _currentTabIndex == 1 ? const Color(0xFF007A3D) : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, IconData icon, Color color) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
        _loadAttendances();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color.fromARGB(128, color.red, color.green, color.blue) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    // Show status filters on Attendance tab
    final showStatusFilters = _currentTabIndex == 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D9CA3AF),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStatusFilters) ...
            [
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildStatusFilterChip('All', 'all', Icons.all_inclusive, const Color(0xFF007A3D)),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Present', 'present', Icons.check_circle, const Color(0xFF007A3D)),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Absent', 'absent', Icons.cancel, const Color(0xFFB71C1C)),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Late', 'late', Icons.access_time, const Color(0xFFE65100)),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Excused', 'excused', Icons.event_available, const Color(0xFF1E3A5F)),
                    const SizedBox(width: 12),
                    Container(height: 24, width: 1, color: const Color(0xFFD1D5DB)),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        setState(() => _showOnlyUnverified = !_showOnlyUnverified);
                        _loadAttendances();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _showOnlyUnverified ? const Color(0xFF005C2E) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _showOnlyUnverified ? const Color(0x801E3A5F) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showOnlyUnverified ? Icons.verified_user : Icons.gpp_maybe,
                              size: 16,
                              color: _showOnlyUnverified ? Colors.white : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Unverified Only',
                              style: TextStyle(
                                color: _showOnlyUnverified ? Colors.white : const Color(0xFF374151),
                                fontSize: 13,
                                fontWeight: _showOnlyUnverified ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          // Workplace filter chips — always visible for all users
          _buildWorkTypeFilterChips(),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final presentCount = _attendances.where((a) => a.status == 'present').length;
    final absentCount = _attendances.where((a) => a.status == 'absent').length;
    final lateCount = _attendances.where((a) => a.status == 'late').length;
    final excusedCount = _attendances.where((a) => a.status == 'excused').length;
    final totalOvertimeHours = _attendances.fold<double>(
      0.0, 
      (sum, attendance) => sum + attendance.overtimeHours,
    );
    final workersWithOvertime = _attendances.where((a) => a.overtimeHours > 0).length;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Present',
                  value: '$presentCount',
                  icon: Icons.check_circle,
                  color: const Color(0xFF007A3D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Absent',
                  value: '$absentCount',
                  icon: Icons.cancel,
                  color: const Color(0xFFB71C1C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Late',
                  value: '$lateCount',
                  icon: Icons.access_time,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    if (_selectedAttendanceIds.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5EE),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC8E6D3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF007A3D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedAttendanceIds.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'records selected',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0A192F), fontSize: 14),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedAttendanceIds.clear()),
            icon: const Icon(Icons.clear, size: 16, color: Color(0xFF6B7280)),
            label: const Text('Clear', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          if (_canVerifyAttendance) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _verifySelected,
              icon: const Icon(Icons.verified, size: 18),
              label: const Text('Verify Selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A3D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceSliverList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentSiteId == null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 80, color: const Color(0xFFD1D5DB)),
              const SizedBox(height: 16),
              Text('No site selected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
              const SizedBox(height: 8),
              Text('Please select a site from the dropdown above,\nor ask an admin to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: const Color(0xFF9CA3AF))),
            ],
          ),
        ),
      );
    }

    if (_workers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 80, color: const Color(0xFF9CA3AF)),
              const SizedBox(height: 16),
              Text('No workers found', style: TextStyle(fontSize: 18, color: const Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Text('Add workers to start marking attendance',
                  style: TextStyle(fontSize: 14, color: const Color(0xFF9CA3AF))),
            ],
          ),
        ),
      );
    }

    List<Worker> displayedWorkers = _filteredWorkers;
    if (_selectedWorkPlace != null) {
      displayedWorkers = displayedWorkers.where((w) =>
        (w.workPlaceName ?? 'General Workforce') == _selectedWorkPlace
      ).toList();
    }

    return SliverToBoxAdapter(
      child: HierarchicalAttendanceList(
          workers: displayedWorkers,
          attendances: _allAttendances, // Fix: pass all attendances so multi-day verification works
          overtimes: _allOvertimes,
          siteId: _currentSiteId!,
          selectedDate: _selectedDate,
          onAttendanceTap: (attendance) => _openAttendanceDetail(attendance),
          onMarkMultiDayOvertime: (worker, overtimeData) async {
            if (worker.id == null || _currentSiteId == null) {
              VisualFeedbackOverlay.showFlashFeedback(
                context,
                type: FeedbackType.error,
                message: 'Invalid worker or site',
              );
              return;
            }
            
            try {
              setState(() => _isLoading = true);
              
              // MultiDayOvertimeSelector already makes the API calls.
              // We just need to reload data and show feedback.
              final totalHours = overtimeData.values.fold<double>(0.0, (sum, h) => sum + h);
              
              await _loadData();
              
              await _audioService.playAttendanceSuccess('Saved');
              
              VisualFeedbackOverlay.showFlashFeedback(
                context,
                type: FeedbackType.success,
                message: 'Overtime saved successfully',
                subtitle: '${worker.fullName} - $totalHours hours across ${overtimeData.length} days',
              );
            } catch (e) {
              setState(() => _isLoading = false);
              VisualFeedbackOverlay.showFlashFeedback(
                context,
                type: FeedbackType.error,
                message: 'Error: ${e.toString()}',
              );
            }
          },
          onVerifyMultiDayAttendance: _canVerifyAttendance ? (worker, dates) async {
            if (worker.id == null || _currentSiteId == null) {
          VisualFeedbackOverlay.showFlashFeedback(
            context,
            type: FeedbackType.error,
            message: 'Invalid worker or site',
          );
          return;
        }
        
        try {
          setState(() => _isLoading = true);
          
          final result = await _dataSource.verifyMultiDayAttendance(
            workerId: worker.id!,
            siteId: _currentSiteId!,
            attendanceDates: dates,
          );
          
          await _audioService.playAttendanceSuccess('Verified');
          
          VisualFeedbackOverlay.showFlashFeedback(
            context,
            type: FeedbackType.success,
            message: result['message'] ?? 'Multi-day attendance verified',
            subtitle: '${worker.fullName} - ${dates.length} days',
          );
          
          _loadData();
        } catch (e) {
          setState(() => _isLoading = false);
          VisualFeedbackOverlay.showFlashFeedback(
            context,
            type: FeedbackType.error,
            message: 'Error: ${e.toString()}',
          );
        }
      } : null,
      onAttendanceSelected: (attendanceId, selected) {
        setState(() {
          if (selected) {
            _selectedAttendanceIds.add(attendanceId);
          } else {
            _selectedAttendanceIds.remove(attendanceId);
          }
        });
      },
      selectedAttendanceIds: _selectedAttendanceIds.toSet(),
      onRefresh: _loadData,
    ),
    );
  }

  Widget _buildWorkersSliverList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentSiteId == null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 80, color: const Color(0xFFD1D5DB)),
              const SizedBox(height: 16),
              Text('No site selected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
              const SizedBox(height: 8),
              Text('Please select a site from the dropdown above,\nor ask an admin to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: const Color(0xFF9CA3AF))),
            ],
          ),
        ),
      );
    }

    if (!_checkingWorkplaceAssignment && !_isSuperAdmin && !_canVerifyAttendance && !_hasWorkplaceAssignment) {
      return SliverFillRemaining(child: _buildNoWorkplaceAssignmentWarning());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
        if (_selectedWorkerIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0x1A007A3D),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedWorkerIds.length} worker(s) selected',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _markSelectedWorkersPresent,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Mark Present'),
                ),
              ],
            ),
          ),
        HierarchicalWorkersList(
          workers: _displayedWorkers,
          attendances: _allAttendances, // Use unfiltered for data operations
          overtimes: _allOvertimes,
          siteId: _currentSiteId!,
          selectedDate: _selectedDate,
          onMarkAttendance: (worker, status) async {
            if (worker.id == null || _currentSiteId == null) {
              VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.error,
                  message: 'Invalid worker or site',
                );
                return;
              }
              
              try {
                setState(() => _isLoading = true);
                
                final existingAttendance = _allAttendances.firstWhere(
                  (a) => a.workerId == worker.id &&
                         a.attendanceDate.year == _selectedDate.year &&
                         a.attendanceDate.month == _selectedDate.month &&
                         a.attendanceDate.day == _selectedDate.day,
                  orElse: () => Attendance(
                    workerId: worker.id!,
                    siteId: _currentSiteId!,
                    attendanceDate: _selectedDate,
                    status: status,
                    method: 'manual_entry',
                  ),
                );
                
                if (existingAttendance.id != null) {
                  if (existingAttendance.isLocked) {
                    setState(() => _isLoading = false);
                    VisualFeedbackOverlay.showFlashFeedback(
                      context,
                      type: FeedbackType.warning,
                      message: 'This record is sealed for payroll and cannot be altered',
                    );
                    return;
                  }
                  if (existingAttendance.isVerified && !_canVerifyAttendance) {
                    setState(() => _isLoading = false);
                    VisualFeedbackOverlay.showFlashFeedback(
                      context,
                      type: FeedbackType.warning,
                      message: 'This record has been verified by the Site Engineer and cannot be altered by a Foreman or Timekeeper',
                    );
                    return;
                  }
                  await _dataSource.updateAttendance(
                    id: existingAttendance.id!,
                    status: status,
                  );
                } else {
                  await _dataSource.createAttendance(
                    workerId: worker.id!,
                    siteId: _currentSiteId!,
                    attendanceDate: _selectedDate,
                    checkInTime: _formatTimeForApi(TimeOfDay.now()),
                    status: status,
                    method: 'manual_entry',
                  );
                }
                
                await _audioService.playAttendanceSuccess('Marked');
                
                VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.success,
                  message: 'Attendance ${existingAttendance.id != null ? 'Updated' : 'Marked'}',
                  subtitle: '${worker.fullName} - ${status.toUpperCase()}',
                );
                
                _loadData();
              } catch (e) {
                setState(() => _isLoading = false);
                VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.error,
                  message: 'Error: ${e.toString()}',
                );
              }
            },
            onMarkMultiDayAttendance: (worker, dates, status) async {
              if (worker.id == null || _currentSiteId == null) {
                VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.error,
                  message: 'Invalid worker or site',
                );
                return;
              }
              
              try {
                setState(() => _isLoading = true);
                
                if (status == 'unmark') {
                  // Unmark mode: preserve overtime, delete or convert to absent
                  int processedCount = 0;
                  int convertedToAbsent = 0;
                  int deleted = 0;
                  
                  for (final date in dates) {
                    // Find attendance record for this date
                    final attendance = _allAttendances.firstWhere(
                      (a) => 
                        a.workerId == worker.id && 
                        a.attendanceDate.year == date.year &&
                        a.attendanceDate.month == date.month &&
                        a.attendanceDate.day == date.day,
                      orElse: () => throw Exception('Attendance not found'),
                    );
                    
                    if (attendance.id != null) {
                      if (attendance.overtimeHours > 0) {
                        // Has overtime - convert to ABSENT, preserve overtime
                        await _dataSource.updateAttendance(
                          id: attendance.id!,
                          status: 'absent',
                          regularHours: 0,
                          checkInTime: '',
                          checkOutTime: '',
                        );
                        convertedToAbsent++;
                      } else {
                        // No overtime - delete completely
                        await _dataSource.deleteAttendance(attendance.id!);
                        deleted++;
                      }
                      processedCount++;
                    }
                  }
                  
                  await _audioService.playAttendanceSuccess('Unmarked');
                  
                  final subtitle = convertedToAbsent > 0
                      ? '${worker.fullName} - $processedCount day${processedCount != 1 ? 's' : ''} unmarked ($convertedToAbsent with overtime preserved)'
                      : '${worker.fullName} - $processedCount day${processedCount != 1 ? 's' : ''} removed';
                  
                  VisualFeedbackOverlay.showFlashFeedback(
                    context,
                    type: FeedbackType.success,
                    message: 'Multi-day attendance unmarked',
                    subtitle: subtitle,
                  );
                } else {
                  // Mark mode: create attendance records
                  await _dataSource.createMultiDayAttendance(
                    workerId: worker.id!,
                    siteId: _currentSiteId!,
                    attendanceDates: dates,
                    status: status,
                    checkInTime: _formatTimeForApi(TimeOfDay.now()),
                  );
                  
                  await _audioService.playAttendanceSuccess('Marked');
                  
                  VisualFeedbackOverlay.showFlashFeedback(
                    context,
                    type: FeedbackType.success,
                    message: 'Multi-day attendance marked',
                    subtitle: '${worker.fullName} - ${dates.length} days - ${status.toUpperCase()}',
                  );
                }
                
                await _loadData();
              } catch (e) {
                setState(() => _isLoading = false);
                VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.error,
                  message: 'Error: ${e.toString()}',
                );
              }
            },
            onMarkMultiDayOvertime: (worker, overtimeData) async {
              if (worker.id == null || _currentSiteId == null) {
                VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.error,
                  message: 'Invalid worker or site',
                );
                return;
              }
              
              try {
                setState(() => _isLoading = true);
                
                debugPrint('💼 Overtime saved for worker ${worker.id}: ${overtimeData.length} days');
                
                // MultiDayOvertimeSelector already makes the API calls.
                // We just need to reload data and show feedback.
                
                final totalHours = overtimeData.values.fold<double>(0.0, (sum, h) => sum + h);
                
                await _loadData();
                
                await _audioService.playAttendanceSuccess('Saved');
                
                VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.success,
                  message: 'Overtime saved',
                  subtitle: '${worker.fullName} - $totalHours hours across ${overtimeData.length} days',
                );
              } catch (e) {
                setState(() => _isLoading = false);
                VisualFeedbackOverlay.showFlashFeedback(
                  context,
                  type: FeedbackType.error,
                  message: 'Error: ${e.toString()}',
                );
              }
            },
            onUnmarkAttendance: (attendance) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Unmark Attendance'),
                  content: Text(
                    'Are you sure you want to delete attendance record for ${attendance.workerName ?? 'this worker'}?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                try {
                  setState(() => _isLoading = true);
                  
                  if (attendance.overtimeHours > 0) {
                    // Has overtime - convert to ABSENT, preserve overtime
                    await _dataSource.updateAttendance(
                      id: attendance.id!,
                      status: 'absent',
                      regularHours: 0,
                      checkInTime: '',
                      checkOutTime: '',
                    );
                    
                    await _audioService.playAttendanceSuccess('Updated');
                    
                    VisualFeedbackOverlay.showFlashFeedback(
                      context,
                      type: FeedbackType.success,
                      message: 'Attendance unmarked (overtime preserved)',
                    );
                  } else {
                    // No overtime - delete completely
                    await _dataSource.deleteAttendance(attendance.id!);
                    
                    await _audioService.playAttendanceSuccess('Deleted');
                    
                    VisualFeedbackOverlay.showFlashFeedback(
                      context,
                      type: FeedbackType.success,
                      message: 'Attendance unmarked',
                    );
                  }
                  
                  await _loadData();
                } catch (e) {
                  setState(() => _isLoading = false);
                  VisualFeedbackOverlay.showFlashFeedback(
                    context,
                    type: FeedbackType.error,
                    message: 'Error: ${e.toString()}',
                  );
                }
              }
            },
            onWorkerSelected: (workerId, selected) {
              setState(() {
                if (selected) {
                  _selectedWorkerIds.add(workerId);
                } else {
                  _selectedWorkerIds.remove(workerId);
                }
              });
            },
            selectedWorkerIds: _selectedWorkerIds.toSet(),
            onRefresh: _loadData,
          ),
      ],
      ),
    );
  }

  Widget _buildWorkTypeFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _WorkTypeFilterChip(
              label: 'All (${_workers.length})',
              isSelected: _selectedWorkPlace == null,
              onTap: () => setState(() => _selectedWorkPlace = null),
            ),
            const SizedBox(width: 8),
            ..._workPlaces.map((workPlace) {
              final count = _workers.where((w) => 
                (w.workPlaceName ?? 'General Workforce') == workPlace
              ).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _WorkTypeFilterChip(
                  label: '$workPlace ($count)',
                  isSelected: _selectedWorkPlace == workPlace,
                  onTap: () => setState(() => _selectedWorkPlace = workPlace),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkplaceAssignmentWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: const Color(0xFFE65100),
            ),
            const SizedBox(height: 24),
            Text(
              'No Workplace Assignment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80), width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFFBF360C), size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'You need to be assigned to a workplace to view and manage data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF1F2937),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please contact a Super Admin to assign you to a workplace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, color: const Color(0xFF0A192F), size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Once assigned, you\'ll be able to manage attendance and workers in your workplace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF0A192F),
                      ),
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

  Widget _buildFAB() {
    final showVerify = _canVerifyAttendance && _currentTabIndex == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'qr_scan',
          backgroundColor: const Color(0xFF0A192F),
          foregroundColor: Colors.white,
          onPressed: _openQRScanner,
          tooltip: 'Scan QR Code',
          child: const Icon(Icons.qr_code_scanner),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'manual_mark',
          backgroundColor: const Color(0xFF007A3D),
          foregroundColor: Colors.white,
          onPressed: showVerify ? _openBulkVerify : _openBulkAttendance,
          icon: Icon(showVerify ? Icons.verified : Icons.people),
          label: Text(showVerify ? 'Bulk Verify' : 'Bulk Mark'),
        ),
      ],
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
        color: Color.fromARGB(26, color.red, color.green, color.blue),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromARGB(77, color.red, color.green, color.blue), width: 1),
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
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkTypeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkTypeFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005C2E) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF374151),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
