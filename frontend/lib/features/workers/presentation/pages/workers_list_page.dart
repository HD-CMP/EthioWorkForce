import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/di/injection.dart';
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
    } catch (e) {
    }
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
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF004D40).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                color: Colors.white.withOpacity(0.2),
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
                  color: Color(0xFF007A3D),
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
          backgroundColor: worker.isActive
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[300],
          child: Text(
            worker.fullName.isNotEmpty ? worker.fullName.substring(0, 1).toUpperCase() : 'W',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: worker.isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
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
              style: TextStyle(
                color: Colors.grey[600],
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workType.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '• ${worker.siteName ?? 'Site ${worker.siteId}'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                  Icon(
                    Icons.supervisor_account,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Reports to: ${worker.supervisorName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
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
                color: worker.isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.workers ?? 'Workers'),
        elevation: 0,
        actions: [
          if (_isSuperAdmin && _sites.length > 1)
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _showSiteSelector,
              tooltip: 'Select Site',
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
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
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
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
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
            ),
        ],
      ),
      body: !_checkingWorkplaceAssignment && !_isSuperAdmin && !_hasWorkplaceAssignment
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Workplace Assignment',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[800], size: 32),
                          const SizedBox(height: 12),
                          Text(
                            'You need to be assigned to a workplace to view and manage workers.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please contact a Super Admin to assign you to a workplace.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Once assigned, you\'ll be able to manage workers in your workplace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workforce Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_workers.where((w) => w.isActive).length} Active Workers',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: localizations?.search ?? 'Search workers...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
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
                              onTap: () => setState(() => _selectedWorkPlace = workPlace),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Connection Error',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_filteredWorkers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No workers found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else
                  ..._buildWorkPlaceGroupedList(),
              ],
            ),
      floatingActionButton: !_checkingWorkplaceAssignment && !_isSuperAdmin && !_hasWorkplaceAssignment
          ? null
          : FloatingActionButton.extended(
              onPressed: _addWorker,
              icon: const Icon(Icons.add),
              label: Text(localizations?.add ?? 'Add Worker'),
            ),
    );
  }

  void _showSiteSelector() {
    try {
      if (_sites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sites available')),
        );
        return;
      }
      
      final sites = List<Site>.from(_sites);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Site'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
                  final isSelected = _currentSiteId == site.id;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                    title: Text(site.name),
                    subtitle: Text(site.code),
                    onTap: () async {
                      Navigator.pop(context);
                      if (site.id != null) {
                        await _storageService.setSelectedSiteId(site.id!);
                        setState(() {
                          _currentSiteId = site.id;
                        });
                        _loadData();
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
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
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
