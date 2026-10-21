import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/app_snackbar.dart';
import 'worker_detail_page.dart';
import 'worker_form_page.dart';
import '../../data/datasources/worker_remote_datasource.dart';
import '../../data/datasources/work_type_remote_datasource.dart';
import '../../data/datasources/site_remote_datasource.dart';
import '../../domain/entities/worker.dart';
import '../../domain/entities/work_type.dart';
import '../../domain/entities/site.dart';
import '../../../notifications/data/datasources/notifications_remote_datasource.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

// ─────────────────────────── Brand constants ────────────────────────────────
const _kEmerald = Color(0xFF007A3D);
const _kEmeraldDark = Color(0xFF005C2E);
const _kNavy = Color(0xFF0A192F);
const _kCrimson = Color(0xFFB71C1C);
const _kAmber = Color(0xFFE65100);
const _kBackground = Color(0xFFF4F7F4);

const _kEmeraldTint = Color(0xFFE8F5EE);
const _kNavyTint = Color(0xFFE8EDF4);
const _kAmberTint = Color(0xFFFFF3E0);
const _kGreyLight = Color(0xFFF3F4F6);
const _kGreyMid = Color(0xFF9CA3AF);
const _kGreyText = Color(0xFF6B7280);
// ─────────────────────────────────────────────────────────────────────────────

class WorkersListPage extends StatefulWidget {
  const WorkersListPage({super.key});

  @override
  State<WorkersListPage> createState() => _WorkersListPageState();
}

class _WorkersListPageState extends State<WorkersListPage> {
  String? _selectedWorkPlace;
  final _searchController = TextEditingController();
  final _workerDatasource = WorkerRemoteDataSource();
  final _workTypeDatasource = WorkTypeRemoteDataSource();
  final _siteDatasource = SiteRemoteDataSource();
  final _storageService = StorageService();
  late final NotificationsRemoteDatasource _notificationsDatasource;
  List<Worker> _workers = [];
  List<WorkType> _workTypes = [];
  List<String> _workPlaces = [];
  List<Site> _sites = [];
  int? _currentSiteId;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _expandedWorkPlaces = {};
  int _unreadNotificationCount = 0;
  bool _hasWorkplaceAssignment = true;
  bool _checkingWorkplaceAssignment = true;
  bool _isSuperAdmin = false;
  List<int> _allowedWorkplaceIds = [];

  @override
  void initState() {
    super.initState();
    _notificationsDatasource = NotificationsRemoteDatasource(getIt<Dio>());
    _workers = [];
    _workTypes = [];
    _sites = [];
    _checkCurrentUserWorkplaceAssignment();
    _initializeSite();
    _loadUnreadNotificationCount();
  }

  Future<void> _checkCurrentUserWorkplaceAssignment() async {
    try {
      final dio = getIt<Dio>();
      final response = await dio.get('/users/me');
      final currentUser = response.data;
      final role = currentUser['role'] as String?;
      final workplaceAssignments = currentUser['work_place_assignments'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _isSuperAdmin = role == 'super_admin';
          _hasWorkplaceAssignment = workplaceAssignments.isNotEmpty;
          _checkingWorkplaceAssignment = false;
          _allowedWorkplaceIds = workplaceAssignments
              .map((wp) => wp['work_place']?['id'] as int?)
              .whereType<int>()
              .toList();
        });

        if (!_isSuperAdmin && workplaceAssignments.isNotEmpty) {
          final firstWorkplace = workplaceAssignments[0] as Map<String, dynamic>;
          final siteId = firstWorkplace['work_place']?['site_id'] as int?;
          if (siteId != null) {
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

    _loadData();
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    try {
      final sites = await _siteDatasource.getSites(isActive: true);
      if (mounted) {
        setState(() {
          _sites = sites;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e is ApiException) {
          errorMessage = e.displayMessage;
        } else {
          errorMessage = 'Error loading sites. Please try again.';
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationsDatasource.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workersResult = await _workerDatasource.getWorkers(
        siteId: _currentSiteId,
      );
      final workTypesResult = await _workTypeDatasource.getWorkTypes(isActive: true);

      if (mounted) {
        // Filter workers if the user is a normal admin and has specific workplace assignments
        List<Worker> allowedWorkers = workersResult;
        if (!_isSuperAdmin && _allowedWorkplaceIds.isNotEmpty) {
          allowedWorkers = workersResult.where((w) {
            return w.workPlaceId != null && _allowedWorkplaceIds.contains(w.workPlaceId);
          }).toList();
        } else if (!_isSuperAdmin) {
          allowedWorkers = [];
        }

        setState(() {
          _workers = allowedWorkers;
          _workTypes = workTypesResult;
          _workPlaces = allowedWorkers
              .map((w) => w.workPlaceName ?? 'General Workforce')
              .toSet()
              .toList()
            ..sort();
          _isLoading = false;
          _errorMessage = null;

          // Auto-expand all workplaces by default
          final grouped = <String, List<Worker>>{};
          for (final worker in _workers) {
            final workPlaceName = worker.workPlaceName ?? 'General Workforce';
            grouped.putIfAbsent(workPlaceName, () => []).add(worker);
          }
          _expandedWorkPlaces.addAll(grouped.keys);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e is ApiException) {
          errorMessage = e.displayMessage;
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workers = await _workerDatasource.getWorkers(
        siteId: _currentSiteId,
      );
      if (mounted) {
        // Filter workers if the user is a normal admin and has specific workplace assignments
        List<Worker> allowedWorkers = workers;
        if (!_isSuperAdmin && _allowedWorkplaceIds.isNotEmpty) {
          allowedWorkers = workers.where((w) {
            return w.workPlaceId != null && _allowedWorkplaceIds.contains(w.workPlaceId);
          }).toList();
        } else if (!_isSuperAdmin) {
          allowedWorkers = [];
        }

        setState(() {
          _workers = allowedWorkers;
          _workPlaces = allowedWorkers
              .map((w) => w.workPlaceName ?? 'General Workforce')
              .toSet()
              .toList()
            ..sort();
          _isLoading = false;
          _errorMessage = null;

          // Auto-expand all workplaces by default
          final grouped = <String, List<Worker>>{};
          for (final worker in _workers) {
            final workPlaceName = worker.workPlaceName ?? 'General Workforce';
            grouped.putIfAbsent(workPlaceName, () => []).add(worker);
          }
          _expandedWorkPlaces.addAll(grouped.keys);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e is ApiException) {
          errorMessage = e.displayMessage;
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  Future<void> _addWorker() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WorkerFormPage()),
    );

    if (result == true) {
      _loadWorkers();
    }
  }

  List<Worker> get _filteredWorkers {
    final query = _searchController.text.toLowerCase();

    if (_selectedWorkPlace == null) {
      if (query.isEmpty) return _workers;
      return _workers.where((w) {
        return w.fullName.toLowerCase().contains(query) ||
            w.employeeId.toLowerCase().contains(query) ||
            (w.phoneNumber?.contains(query) ?? false);
      }).toList();
    }

    return _workers.where((w) {
      final workPlace = w.workPlaceName ?? 'General Workforce';
      if (workPlace != _selectedWorkPlace) return false;

      if (query.isEmpty) return true;
      return w.fullName.toLowerCase().contains(query) ||
          w.employeeId.toLowerCase().contains(query) ||
          (w.phoneNumber?.contains(query) ?? false);
    }).toList();
  }

  Map<String, List<Worker>> get _workersGroupedByWorkPlace {
    final Map<String, List<Worker>> grouped = {};
    for (var worker in _filteredWorkers) {
      final workPlaceName = worker.workPlaceName ?? 'General Workforce';
      grouped.putIfAbsent(workPlaceName, () => []).add(worker);
    }
    return grouped;
  }

  List<Widget> _buildWorkPlaceGroupedList() {
    final grouped = _workersGroupedByWorkPlace;
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'General Workforce') return 1;
        if (b == 'General Workforce') return -1;
        return a.compareTo(b);
      });

    final List<Widget> widgets = [];
    for (final workPlaceName in sortedKeys) {
      final workers = grouped[workPlaceName]!;
      final isExpanded = _expandedWorkPlaces.contains(workPlaceName);

      widgets.add(_buildWorkPlaceHeader(workPlaceName, workers.length, isExpanded));

      if (isExpanded) {
        for (final worker in workers) {
          widgets.add(_buildWorkerCard(worker));
        }
      }
    }

    return widgets;
  }

  Widget _buildWorkPlaceHeader(String workPlaceName, int count, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedWorkPlaces.remove(workPlaceName);
          } else {
            _expandedWorkPlaces.add(workPlaceName);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF00796B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D004D40),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                workPlaceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: _kEmerald,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    final workType = _workTypes.firstWhere(
      (wt) => wt.id == worker.workTypeId,
      orElse: () => WorkType(
        name: worker.workType ?? 'Unknown',
        code: 'UNK',
        paymentMode: PaymentMode.dailyRate,
        baseRate: 0,
      ),
    );

    final avatarBg = worker.isActive ? _kEmeraldTint : _kGreyLight;
    final avatarTextColor = worker.isActive ? _kEmerald : _kGreyText;
    final statusDotColor = worker.isActive ? _kEmerald : _kGreyMid;

    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
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
          radius: 28,
          backgroundColor: avatarBg,
          child: Text(
            worker.fullName.isNotEmpty
                ? worker.fullName.substring(0, 1).toUpperCase()
                : 'W',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: avatarTextColor,
            ),
          ),
        ),
        title: Text(
          worker.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              worker.employeeId,
              style: const TextStyle(
                color: _kGreyText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kEmeraldTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workType.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kEmerald,
                    ),
                  ),
                ),
                if (worker.hasIdDocument) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFB2DFCA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge, size: 10, color: _kEmerald),
                        SizedBox(width: 3),
                        Text(
                          'ID ON FILE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _kEmerald,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '• ${worker.siteName ?? 'Site ${worker.siteId}'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kGreyText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (worker.supervisorName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.supervisor_account,
                    size: 14,
                    color: _kGreyText,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Reports to: ${worker.supervisorName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kGreyText,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusDotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: _kGreyMid),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerDetailPage(
                worker: worker,
              ),
            ),
          );
          _loadWorkers();
        },
      ),
    );
  }

  // ─────────────────────── Enterprise header banner ───────────────────────
  Widget _buildHeaderBanner() {
    final activeCount = _workers.where((w) => w.isActive).length;
    final siteCount = _sites.length;
    final currentSiteName = _sites
        .firstWhere(
          (s) => s.id == _currentSiteId,
          orElse: () => Site(name: 'All Sites', code: ''),
        )
        .name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kEmeraldDark, _kEmerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative background circle for visual depth
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0x1AFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0x0DFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workforce Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentSiteName,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people,
                    label: '$activeCount Active',
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: Icons.groups,
                    label: '${_workers.length} Total',
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: Icons.location_city,
                    label: '$siteCount Sites',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────── No Workplace Assignment screen ─────────────────────
  Widget _buildNoWorkplaceScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: _kAmberTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 56,
                color: _kAmber,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Workplace Assignment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kAmberTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAmber, width: 1.5),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: _kAmber, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'You need to be assigned to a workplace to view and manage workers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _kNavy,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please contact a Super Admin to assign you to a workplace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _kGreyText,
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
                color: _kNavyTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kNavy),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, color: _kNavy, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Once assigned, you\'ll be able to manage workers in your workplace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _kNavy,
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

  // ────────────────────────── Error screen ─────────────────────────────────
  Widget _buildErrorScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kCrimson.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off,
              size: 52,
              color: _kCrimson,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: _kGreyText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCrimson,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        foregroundColor: Colors.white,
        title: Text(
          localizations?.workers ?? 'Workers',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSuperAdmin && _sites.length > 1)
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed: _showSiteSelector,
              tooltip: 'Select Site',
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                  _loadUnreadNotificationCount();
                },
                tooltip: 'Notifications',
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _kCrimson,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (_isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterSheet,
            ),
        ],
      ),
      body: !_checkingWorkplaceAssignment && !_isSuperAdmin && !_hasWorkplaceAssignment
          ? _buildNoWorkplaceScreen()
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // ── Enterprise branded header banner ──
                _buildHeaderBanner(),

                // ── Search bar ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: localizations?.search ?? 'Search workers...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // ── Filter chips ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All (${_workers.length})',
                          isSelected: _selectedWorkPlace == null,
                          onTap: () => setState(() => _selectedWorkPlace = null),
                        ),
                        const SizedBox(width: 8),
                        ..._workPlaces.map((workPlace) {
                          final count = _workers.where((w) {
                            final wp = w.workPlaceName ?? 'General Workforce';
                            return wp == workPlace;
                          }).length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: '$workPlace ($count)',
                              isSelected: _selectedWorkPlace == workPlace,
                              onTap: () => setState(
                                () => _selectedWorkPlace = workPlace,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Body content ──
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: CircularProgressIndicator(color: _kEmerald),
                    ),
                  )
                else if (_errorMessage != null)
                  _buildErrorScreen()
                else if (_filteredWorkers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: _kEmeraldTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.people_outline,
                            size: 44,
                            color: _kEmerald,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No workers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: _kGreyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._buildWorkPlaceGroupedList(),
              ],
            ),
      floatingActionButton:
          !_checkingWorkplaceAssignment && !_isSuperAdmin && !_hasWorkplaceAssignment
              ? null
              : Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D2137), _kNavy],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D0A192F),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: _addWorker,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      localizations?.add ?? 'Add Worker',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
    );
  }

  // ─────────────────── Enterprise site-selector bottom sheet ──────────────
  void _showSiteSelector() {
    try {
      if (_sites.isEmpty) {
        AppSnackBar.showInfo(context, 'No sites available');
        return;
      }

      final sites = List<Site>.from(_sites);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Drag handle ──
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // ── Title row ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          const Text(
                            'Select Site',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _kNavy,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _kEmeraldTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${sites.length}',
                              style: const TextStyle(
                                color: _kEmerald,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // ── Site list ──
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: sites.length,
                        itemBuilder: (context, index) {
                          final site = sites[index];
                          final isSelected = _currentSiteId == site.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                Navigator.pop(sheetCtx);
                                if (site.id != null) {
                                  await _storageService
                                      .setSelectedSiteId(site.id!);
                                  setState(() {
                                    _currentSiteId = site.id;
                                  });
                                  _loadData();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _kEmeraldTint
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? _kEmerald
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _kEmerald
                                            : const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.location_city,
                                        color: isSelected
                                            ? Colors.white
                                            : _kGreyText,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            site.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? _kEmerald
                                                  : _kNavy,
                                            ),
                                          ),
                                          Text(
                                            site.code,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _kGreyMid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: _kEmerald,
                                        size: 22,
                                      )
                                    else
                                      const Icon(
                                        Icons.radio_button_unchecked,
                                        color: _kGreyMid,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      // Handle hot reload error
    }
  }

  void _showSiteFilter() {
    Navigator.pop(context);
    _showSiteSelector();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Workers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.work),
                title: const Text('Work Type'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              if (_isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Site'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showSiteFilter,
                ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Status'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kEmerald,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────── Stat chip (header) ─────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────── Filter chip ──────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kEmerald : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x4D007A3D),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _kGreyText,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
