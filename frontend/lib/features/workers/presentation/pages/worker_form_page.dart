import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/constants/ethiopian_banks.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/ethiopian_date_picker.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../domain/entities/worker.dart';
import '../../domain/entities/site.dart';
import '../../domain/entities/work_place.dart';
import '../../domain/entities/work_type.dart';
import '../../data/datasources/worker_remote_datasource.dart';
import '../../data/datasources/site_remote_datasource.dart';
import '../../data/datasources/work_place_remote_datasource.dart';
import '../../data/datasources/work_type_remote_datasource.dart';
import 'site_management_page.dart';
import 'work_type_management_page.dart';

class WorkerFormPage extends StatefulWidget {
  final Worker? worker;

  const WorkerFormPage({super.key, this.worker});

  @override
  State<WorkerFormPage> createState() => _WorkerFormPageState();
}

class _WorkerFormPageState extends State<WorkerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _datasource = WorkerRemoteDataSource();
  final _siteDatasource = SiteRemoteDataSource();
  final _workPlaceDatasource = WorkPlaceRemoteDataSource();
  final _workTypeDatasource = WorkTypeRemoteDataSource();
  
  late TextEditingController _employeeIdController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bankAccountController;
  late TextEditingController _tinController;
  late TextEditingController _baseSalaryController;
  late TextEditingController _overtimeRateController;
  
  int? _selectedSiteId;
  int? _selectedWorkPlaceId;
  int? _selectedWorkTypeId;
  int? _selectedSupervisorId;
  int? _initialSupervisorId;
  String? _status;
  bool _isLoading = false;
  DateTime? _hireDate;

  // National ID / Kebele ID Document
  File? _idCardImageFile;
  String? _existingIdCardUrl;
  String? _resolvedExistingIdCardUrl;

  // Returns true if the selected work type is hierarchy level 1-4
  // (Executive, Senior Management, Middle Management, Supervisory)
  bool get _requiresIndividualSalary {
    if (_selectedWorkTypeId == null || _workTypes.isEmpty) return false;
    final wt = _workTypes.where((w) => w.id == _selectedWorkTypeId).firstOrNull;
    return wt != null && wt.hierarchyLevel <= 4;
  }
  
  List<Site> _sites = [];
  List<WorkPlace> _workPlaces = [];
  List<WorkType> _workTypes = [];
  List<Worker> _potentialSupervisors = [];
  bool _loadingSites = false;
  bool _loadingWorkPlaces = false;
  bool _loadingWorkTypes = false;
  bool _loadingSupervisors = false;
  
  EthiopianBank? _selectedBank;
  String? _detectedBankName;
  
  // Employee ID validation
  Timer? _employeeIdDebounce;
  bool _isCheckingEmployeeId = false;
  bool? _employeeIdAvailable;
  String? _employeeIdValidationMessage;
  
  // User role and permissions
  bool _isSuperAdmin = false;
  List<Map<String, dynamic>> _userWorkplaceAssignments = [];
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    final worker = widget.worker;
    _employeeIdController = TextEditingController(text: worker?.employeeId);
    _fullNameController = TextEditingController(text: worker?.fullName);
    _phoneController = TextEditingController(text: worker?.phoneNumber);
    _bankAccountController = TextEditingController(text: worker?.bankAccountNumber);
    _tinController = TextEditingController(text: worker?.tinNumber);
    _baseSalaryController = TextEditingController(
      text: worker?.baseSalary != null ? worker!.baseSalary!.toStringAsFixed(2) : '',
    );
    _overtimeRateController = TextEditingController(
      text: worker?.overtimeRatePerHour != null && worker!.overtimeRatePerHour! > 0
          ? worker!.overtimeRatePerHour!.toStringAsFixed(2)
          : '',
    );
    
    if (worker != null) {
      _selectedSiteId = worker.siteId;
      _selectedWorkPlaceId = worker.workPlaceId;
      _selectedWorkTypeId = worker.workTypeId;
      _initialSupervisorId = worker.supervisorId;
      _status = worker.status ?? 'active';
      _hireDate = worker.hireDate;
      if (worker.bankName != null) {
        _selectedBank = EthiopianBanks.all.where((b) => b.name == worker.bankName).firstOrNull;
      }
      _existingIdCardUrl = worker.idCardUrl;
      if (_existingIdCardUrl != null && _existingIdCardUrl!.isNotEmpty) {
        _resolveExistingIdUrl();
      }
    } else {
      _hireDate = DateTime.now();
      _status = 'active';
    }
    
    _loadUserRoleAndInitialize();
  }

  Future<void> _resolveExistingIdUrl() async {
    if (_existingIdCardUrl != null && _existingIdCardUrl!.isNotEmpty) {
      final resolved = await DioClient.resolveMediaUrl(_existingIdCardUrl);
      if (mounted) {
        setState(() => _resolvedExistingIdCardUrl = resolved);
      }
    }
  }

  Future<void> _pickIdCardImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (picked != null && mounted) {
        setState(() {
          _idCardImageFile = File(picked.path);
        });
      }
    } catch (e) {
      _showError('Could not access camera or gallery: ${e.toString()}');
    }
  }

  void _showDocumentSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.badge_outlined, color: Color(0xFF007A3D), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Worker ID Card',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A192F),
                        ),
                      ),
                      Text(
                        'National ID / Kebele ID / Fayda card capture',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdCardImage(ImageSource.camera);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF007A3D), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take Photo with Camera',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Use device camera to frame and scan physical ID card',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdCardImage(ImageSource.gallery);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0A192F), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose from Gallery / Files',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select an existing image or document scan',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              ),
              if (_idCardImageFile != null || (_existingIdCardUrl != null && _existingIdCardUrl!.isNotEmpty)) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _idCardImageFile = null;
                      _existingIdCardUrl = null;
                      _resolvedExistingIdCardUrl = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Color(0xFFB71C1C), size: 24),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Remove Attached ID Document',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullscreenImagePreview(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0A192F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: Color(0xFF007A3D), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Official ID Document Preview',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                color: Colors.black,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _loadUserRoleAndInitialize() async {
    try {
      // Load sites and work types first (before checking user role)
      debugPrint('📥 Loading sites...');
      await _loadSites();
      debugPrint('✅ Sites loaded: ${_sites.length}');
      
      debugPrint('📥 Loading work types...');
      await _loadWorkTypes();
      debugPrint('✅ Work types loaded: ${_workTypes.length}');
      
      debugPrint('🔍 About to fetch user data from /users/me');
      // Get user data
      final dio = getIt<Dio>();
      debugPrint('✅ Dio instance obtained');
      final response = await dio.get('/users/me');
      debugPrint('✅ /users/me response received: ${response.statusCode}');
      debugPrint('📦 Response data: ${response.data}');
      final currentUser = response.data;
      final role = currentUser['role'] as String?;
      final workplaceAssignments = currentUser['work_place_assignments'] as List<dynamic>? ?? [];
      
      debugPrint('👤 User role: $role');
      debugPrint('📍 Workplace assignments count: ${workplaceAssignments.length}');
      if (workplaceAssignments.isNotEmpty) {
        debugPrint('📍 First assignment: ${workplaceAssignments[0]}');
      }
      
      final isSuperAdmin = role == 'super_admin';
      
      if (mounted) {
        setState(() {
          _isSuperAdmin = isSuperAdmin;
          _userWorkplaceAssignments = workplaceAssignments.cast<Map<String, dynamic>>();
        });
      }
      
      // Auto-assign for regular admins (only for new workers)
      if (!isSuperAdmin && workplaceAssignments.isNotEmpty && widget.worker == null) {
        debugPrint('🎯 Auto-assign check: isSuperAdmin=$isSuperAdmin, hasAssignments=${workplaceAssignments.isNotEmpty}, isNewWorker=${widget.worker == null}');
        final firstWorkplace = workplaceAssignments[0] as Map<String, dynamic>;
        final workPlace = firstWorkplace['work_place'] as Map<String, dynamic>?;
        debugPrint('🏢 Work place data: $workPlace');
        
        if (workPlace != null) {
          final autoSiteId = workPlace['site_id'] as int?;
          final autoWorkPlaceId = workPlace['id'] as int?;
          
          debugPrint('Auto-filling for regular admin: siteId=$autoSiteId, workPlaceId=$autoWorkPlaceId');
          
          if (autoSiteId != null && autoWorkPlaceId != null) {
            if (mounted) {
              setState(() {
                _selectedSiteId = autoSiteId;
                _selectedWorkPlaceId = autoWorkPlaceId;
              });
            }
            await _loadWorkPlaces();
            debugPrint('Workplaces loaded: ${_workPlaces.length}, selected workplace exists: ${_workPlaces.any((wp) => wp.id == autoWorkPlaceId)}');
          }
        } else {
          debugPrint('workPlace is null in assignment');
        }
      }
      
      // Load existing worker's workplaces if editing
      if (widget.worker != null && _selectedSiteId != null) {
        await _loadWorkPlaces();
      }
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      
      if (_selectedWorkTypeId != null) {
        _loadPotentialSupervisors();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading user role: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      // If error loading user data, proceed with default behavior
      if (mounted) {
        setState(() {
          _isSuperAdmin = false;
          _isInitializing = false;
        });
      }
      await _loadSites();
      await _loadWorkTypes();
      if (_selectedSiteId != null) {
        await _loadWorkPlaces();
        if (_selectedWorkTypeId != null) {
          _loadPotentialSupervisors();
        }
      }
    }
  }
  
  Future<void> _loadSites() async {
    setState(() => _loadingSites = true);
    try {
      final sites = await _siteDatasource.getSites(isActive: true);
      if (mounted) {
        setState(() {
          _sites = sites;
          _loadingSites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSites = false);
      }
    }
  }
  
  Future<void> _loadWorkTypes() async {
    debugPrint('🔧 _loadWorkTypes START');
    setState(() => _loadingWorkTypes = true);
    try {
      debugPrint('📡 Calling getWorkTypes...');
      final workTypes = await _workTypeDatasource.getWorkTypes(isActive: true);
      debugPrint('✅ getWorkTypes returned ${workTypes.length} items');
      debugPrint('🔍 mounted=$mounted');
      if (mounted) {
        setState(() {
          _workTypes = workTypes;
          _loadingWorkTypes = false;
        });
        debugPrint('✅ setState completed for work types');
      } else {
        debugPrint('⚠️ Widget not mounted, skipping setState');
      }
      debugPrint('🔧 _loadWorkTypes END');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _loadWorkTypes: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _loadingWorkTypes = false);
      }
    }
  }
  
  Future<void> _loadWorkPlaces() async {
    if (_selectedSiteId == null) {
      setState(() {
        _workPlaces = [];
        _selectedWorkPlaceId = null;
      });
      return;
    }
    
    setState(() => _loadingWorkPlaces = true);
    try {
      final workPlaces = await _workPlaceDatasource.getWorkPlaces(siteId: _selectedSiteId, isActive: true);
      if (mounted) {
        setState(() {
          _workPlaces = workPlaces;
          _loadingWorkPlaces = false;
          
          // Only reset work place selection if it doesn't belong to new site
          // Skip this during initialization for regular admins
          if (!_isInitializing && _selectedWorkPlaceId != null && !workPlaces.any((wp) => wp.id == _selectedWorkPlaceId)) {
            _selectedWorkPlaceId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingWorkPlaces = false);
      }
    }
  }
  
  Future<void> _loadPotentialSupervisors() async {
    if (_selectedSiteId == null) return;
    
    setState(() => _loadingSupervisors = true);
    try {
      final workers = await _datasource.getWorkers(siteId: _selectedSiteId, status: 'active');
      if (mounted) {
        List<Worker> filteredWorkers = workers.where((w) => w.id != widget.worker?.id).toList();
        Worker? initialSupervisor;
        
        if (_initialSupervisorId != null) {
          initialSupervisor = workers.where((w) => w.id == _initialSupervisorId).firstOrNull;
          
          // LEAK FIX: If the supervisor is deactivated, they won't be in the 'active' workers list.
          // Create a placeholder so we don't silently wipe the worker's supervisor assignment.
          if (initialSupervisor == null && widget.worker != null && widget.worker?.supervisorName != null) {
            initialSupervisor = Worker(
              id: _initialSupervisorId,
              employeeId: 'N/A',
              fullName: '${widget.worker!.supervisorName} (Inactive)',
              siteId: _selectedSiteId!,
              workTypeId: widget.worker!.workTypeId, // Dummy, just for satisfying the model
              status: 'inactive',
            );
          }
        }
        
        // Filter by work place if selected, but ALWAYS include site-wide managers (Hierarchy 1 & 2)
        if (_selectedWorkPlaceId != null) {
          filteredWorkers = filteredWorkers.where((worker) {
            // If they are in the same workplace, they are eligible
            if (worker.workPlaceId == _selectedWorkPlaceId) return true;
            
            // If they are site-wide managers (Hierarchy 1 or 2), they are eligible everywhere
            final workerWorkType = _workTypes.where((wt) => wt.id == worker.workTypeId).firstOrNull;
            if (workerWorkType != null && workerWorkType.hierarchyLevel <= 2) {
              return true;
            }
            
            return false;
          }).toList();
        }
        
        if (_selectedWorkTypeId != null && _workTypes.isNotEmpty) {
          final selectedWorkType = _workTypes.firstWhere(
            (wt) => wt.id == _selectedWorkTypeId,
            orElse: () => _workTypes.first,
          );
          
          // Filter workers with higher hierarchy (lower level number)
          filteredWorkers = filteredWorkers.where((worker) {
            if (worker.workTypeId == null) return false;
            
            final workerWorkType = _workTypes.where((wt) => wt.id == worker.workTypeId).firstOrNull;
            if (workerWorkType == null) return false;
            
            return workerWorkType.hierarchyLevel < selectedWorkType.hierarchyLevel;
          }).toList();
          
          // Sort by hierarchy level (lower number = higher in hierarchy)
          filteredWorkers.sort((a, b) {
            final aWorkType = _workTypes.where((wt) => wt.id == a.workTypeId).firstOrNull;
            final bWorkType = _workTypes.where((wt) => wt.id == b.workTypeId).firstOrNull;
            
            if (aWorkType == null && bWorkType == null) return 0;
            if (aWorkType == null) return 1;
            if (bWorkType == null) return -1;
            
            final levelCompare = aWorkType.hierarchyLevel.compareTo(bWorkType.hierarchyLevel);
            if (levelCompare != 0) return levelCompare;
            
            // If same level, sort by name
            return a.fullName.compareTo(b.fullName);
          });
        }
        
        // If editing and initial supervisor is not in filtered list, add them
        if (initialSupervisor != null && !filteredWorkers.any((w) => w.id == initialSupervisor!.id)) {
          filteredWorkers.insert(0, initialSupervisor);
        }
        
        setState(() {
          _potentialSupervisors = filteredWorkers;
          // Only set selected supervisor after we've loaded the list
          if (_initialSupervisorId != null && filteredWorkers.any((w) => w.id == _initialSupervisorId)) {
            _selectedSupervisorId = _initialSupervisorId;
          }
          _loadingSupervisors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSupervisors = false);
      }
    }
  }
  
  Future<void> _openSiteManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SiteManagementPage()),
    );
    _loadSites();
  }
  
  Future<void> _openWorkTypeManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkTypeManagementPage()),
    );
    _loadWorkTypes();
  }
  
  void _openWorkPlaceManagement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Work Place management feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _employeeIdDebounce?.cancel();
    _employeeIdController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _bankAccountController.dispose();
    _tinController.dispose();
    _baseSalaryController.dispose();
    _overtimeRateController.dispose();
    super.dispose();
  }
  
  void _onEmployeeIdChanged(String value) {
    _employeeIdDebounce?.cancel();
    
    if (value.trim().isEmpty) {
      setState(() {
        _employeeIdAvailable = null;
        _employeeIdValidationMessage = null;
      });
      return;
    }
    
    _employeeIdDebounce = Timer(const Duration(milliseconds: 800), () {
      _checkEmployeeIdAvailability();
    });
  }
  
  Future<void> _checkEmployeeIdAvailability() async {
    final employeeId = _employeeIdController.text.trim();
    
    if (employeeId.isEmpty || _selectedSiteId == null || _selectedWorkTypeId == null) {
      setState(() {
        _employeeIdAvailable = null;
        _employeeIdValidationMessage = null;
      });
      return;
    }
    
    setState(() => _isCheckingEmployeeId = true);
    
    try {
      final result = await _datasource.checkEmployeeIdAvailability(
        employeeId: employeeId,
        siteId: _selectedSiteId!,
        workTypeId: _selectedWorkTypeId!,
        excludeWorkerId: widget.worker?.id,
      );
      
      if (mounted) {
        setState(() {
          _employeeIdAvailable = result['available'] as bool;
          _employeeIdValidationMessage = result['message'] as String?;
          _isCheckingEmployeeId = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmployeeId = false;
          _employeeIdAvailable = null;
          _employeeIdValidationMessage = null;
        });
      }
    }
  }

  Future<void> _selectHireDate() async {
    final picked = await showEthiopianDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _hireDate = picked);
    }
  }

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSiteId == null) {
      _showError('Please select a site');
      return;
    }

    if (_selectedWorkTypeId == null) {
      _showError('Please select a work type');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final salaryText = _baseSalaryController.text.trim();
      double? baseSalary;
      if (_requiresIndividualSalary) {
        if (salaryText.isEmpty) {
          _showError('Base Salary is required for this hierarchy level');
          setState(() => _isLoading = false);
          return;
        }
        baseSalary = double.tryParse(salaryText);
        if (baseSalary == null || baseSalary <= 0) {
          _showError('Please enter a valid salary amount');
          setState(() => _isLoading = false);
          return;
        }
      } else {
        baseSalary = null;
      }

      final otRateText = _overtimeRateController.text.trim();
      final double? customOtRate = otRateText.isNotEmpty ? double.tryParse(otRateText) : null;
      final tinText = _tinController.text.trim();

      String? idCardUrl = _existingIdCardUrl;
      if (_idCardImageFile != null) {
        try {
          idCardUrl = await _datasource.uploadIdDocument(_idCardImageFile!.path);
        } catch (_) {
          try {
            final bytes = await _idCardImageFile!.readAsBytes();
            final b64 = base64Encode(bytes);
            idCardUrl = 'data:image/jpeg;base64,$b64';
          } catch (_) {
            idCardUrl = _existingIdCardUrl;
          }
        }
      }

      final worker = Worker(
        id: widget.worker?.id,
        employeeId: _employeeIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        siteId: _selectedSiteId!,
        workPlaceId: _selectedWorkPlaceId,
        workTypeId: _selectedWorkTypeId!,
        supervisorId: _selectedSupervisorId,
        status: _status,
        bankName: _selectedBank?.name,
        bankAccountNumber: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
        tinNumber: tinText.isEmpty ? null : tinText,
        hireDate: _hireDate,
        baseSalary: baseSalary,
        overtimeRatePerHour: customOtRate,
        idCardUrl: idCardUrl,
      );

      if (widget.worker == null) {
        await _datasource.createWorker(worker);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Worker registered successfully!'),
              ]),
              backgroundColor: const Color(0xFF007A3D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        await _datasource.updateWorker(worker);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Worker details saved successfully!'),
              ]),
              backgroundColor: const Color(0xFF007A3D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.displayMessage;
      } else {
        errorMessage = 'An unexpected error occurred. Please try again.';
      }
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isEditing = widget.worker != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Worker' : (localizations?.add ?? 'Add Worker')),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveWorker,
              child: Text(
                localizations?.save ?? 'Save',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Basic Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: InputDecoration(
                        labelText: localizations?.employeeId ?? 'Employee ID',
                        prefixIcon: const Icon(Icons.badge),
                        border: const OutlineInputBorder(),
                        filled: isEditing,
                        fillColor: isEditing ? const Color(0xFFF3F4F6) : null,
                        helperText: isEditing ? 'Cannot be changed' : 'Unique identifier for the worker',
                        suffixIcon: !isEditing && _selectedSiteId != null && _selectedWorkTypeId != null
                            ? _isCheckingEmployeeId
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _employeeIdAvailable == true
                                    ? const Icon(Icons.check_circle, color: const Color(0xFF007A3D))
                                    : _employeeIdAvailable == false
                                        ? const Icon(Icons.error, color: const Color(0xFFB71C1C))
                                        : null
                            : null,
                        errorText: !isEditing && _employeeIdAvailable == false 
                            ? _employeeIdValidationMessage 
                            : null,
                        errorMaxLines: 2,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Employee ID is required';
                        }
                        if (!isEditing && _employeeIdAvailable == false) {
                          return 'This Employee ID is already in use';
                        }
                        return null;
                      },
                      readOnly: isEditing,
                      onChanged: isEditing ? null : _onEmployeeIdChanged,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: localizations?.fullName ?? 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: localizations?.phoneNumber ?? 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: const OutlineInputBorder(),
                        hintText: '+251 911 234 567',
                        helperText: 'Contact number for the worker',
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildIdDocumentSection(),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Work Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedSiteId,
                            decoration: InputDecoration(
                              labelText: localizations?.site ?? 'Site',
                              prefixIcon: const Icon(Icons.location_on),
                              border: const OutlineInputBorder(),
                              filled: !_isSuperAdmin,
                              fillColor: !_isSuperAdmin ? const Color(0xFFF3F4F6) : null,
                            ),
                            items: _sites.map((site) {
                              return DropdownMenuItem<int>(
                                value: site.id,
                                child: Text(site.name),
                              );
                            }).toList(),
                            onChanged: _isSuperAdmin ? (value) {
                              setState(() {
                                _selectedSiteId = value;
                                _selectedSupervisorId = null;
                                _initialSupervisorId = null;
                                _potentialSupervisors.clear();
                              });
                              _loadWorkPlaces();
                              _loadPotentialSupervisors();
                              _checkEmployeeIdAvailability();
                            } : null,
                            disabledHint: _selectedSiteId != null 
                                ? Text(_sites.firstWhere((s) => s.id == _selectedSiteId, orElse: () => Site(id: 0, name: 'Unknown', code: '', isActive: true)).name)
                                : null,
                            validator: (value) => value == null ? 'Please select a site' : null,
                          ),
                        ),
                        if (_isSuperAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _openSiteManagement,
                              icon: const Icon(Icons.settings),
                              tooltip: 'Manage Sites',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedWorkPlaceId,
                            decoration: InputDecoration(
                              labelText: 'Work Place',
                              prefixIcon: const Icon(Icons.business),
                              border: const OutlineInputBorder(),
                              filled: !_isSuperAdmin,
                              fillColor: !_isSuperAdmin ? const Color(0xFFF3F4F6) : null,
                              helperText: _selectedSiteId == null 
                                  ? 'Select a site first' 
                                  : _loadingWorkPlaces 
                                      ? 'Loading work places...' 
                                      : null,
                            ),
                            items: _selectedSiteId == null || _loadingWorkPlaces
                                ? []
                                : _workPlaces.map((workPlace) {
                                    return DropdownMenuItem<int>(
                                      value: workPlace.id,
                                      child: Text(workPlace.name),
                                    );
                                  }).toList(),
                            onChanged: (_selectedSiteId == null || _loadingWorkPlaces || !_isSuperAdmin)
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedWorkPlaceId = value;
                                      _selectedSupervisorId = null;
                                      _initialSupervisorId = null;
                                    });
                                    if (_selectedWorkTypeId != null) {
                                      _loadPotentialSupervisors();
                                    }
                                  },
                            disabledHint: _selectedWorkPlaceId != null && _workPlaces.isNotEmpty
                                ? Text(_workPlaces.firstWhere((wp) => wp.id == _selectedWorkPlaceId, orElse: () => WorkPlace(id: 0, name: 'Unknown', code: '', parentSiteId: 0, isActive: true)).name)
                                : null,
                          ),
                        ),
                        if (_isSuperAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _openWorkPlaceManagement,
                              icon: const Icon(Icons.settings),
                              tooltip: 'Manage Work Places',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedWorkTypeId,
                            decoration: InputDecoration(
                              labelText: localizations?.workType ?? 'Work Type',
                              prefixIcon: const Icon(Icons.work),
                              border: const OutlineInputBorder(),
                            ),
                            items: _workTypes.map((workType) {
                              return DropdownMenuItem<int>(
                                value: workType.id,
                                child: Text(workType.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedWorkTypeId = value;
                                _selectedSupervisorId = null;
                                _initialSupervisorId = null;
                              });
                              if (_selectedSiteId != null) {
                                _loadPotentialSupervisors();
                              }
                              _checkEmployeeIdAvailability();
                            },
                            validator: (value) => value == null ? 'Please select a work type' : null,
                          ),
                        ),
                        if (_isSuperAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _openWorkTypeManagement,
                              icon: const Icon(Icons.settings),
                              tooltip: 'Manage Work Types',
                            ),
                          ),
                        ],
                      ],
                    ),
                    // ── DYNAMIC INDIVIDUAL SALARY FIELD ──────────────────────
                    // Appears only when a hierarchy 1-4 work type is selected
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: _requiresIndividualSalary
                          ? Padding(
                              key: const ValueKey('salary_field'),
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFF3E0),
                                          Color(0xFFFFF8F0),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFFB74D)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.stars_rounded, color: Color(0xFFE65100), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This role requires an individual salary. The Work Type rate will NOT be used.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFFBF360C),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _baseSalaryController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Base Salary (ETB) *',
                                      prefixIcon: const Icon(Icons.payments_outlined),
                                      prefixText: 'ETB ',
                                      border: const OutlineInputBorder(),
                                      helperText: () {
                                        final wt = _workTypes.where((w) => w.id == _selectedWorkTypeId).firstOrNull;
                                        if (wt == null) return null;
                                        const levels = {1: 'Executive', 2: 'Senior Management', 3: 'Middle Management', 4: 'Supervisory'};
                                        return 'For ${wt.name} — Hierarchy Level ${wt.hierarchyLevel} (${levels[wt.hierarchyLevel] ?? ''})';
                                      }(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('salary_empty')),
                    ),

                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedSupervisorId,
                      decoration: InputDecoration(
                        labelText: 'Supervisor/Manager (Optional)',
                        prefixIcon: const Icon(Icons.supervisor_account),
                        border: const OutlineInputBorder(),
                        helperText: _selectedWorkTypeId == null
                            ? 'Select a work type first to see available supervisors'
                            : _potentialSupervisors.isEmpty
                                ? (_selectedWorkPlaceId != null
                                    ? 'No supervisors available in this work place at higher hierarchy levels'
                                    : 'No supervisors available at higher hierarchy levels')
                                : (_selectedWorkPlaceId != null
                                    ? 'Showing ${_potentialSupervisors.length} supervisor(s) from this work place with higher hierarchy level'
                                    : 'Showing ${_potentialSupervisors.length} supervisor(s) with higher hierarchy level'),
                        suffixIcon: _selectedSupervisorId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => setState(() => _selectedSupervisorId = null),
                                tooltip: 'Clear selection',
                              )
                            : null,
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          const Text('None', style: TextStyle(fontStyle: FontStyle.italic)),
                          ..._potentialSupervisors.map((supervisor) {
                            final workType = _workTypes.where((wt) => wt.id == supervisor.workTypeId).firstOrNull;
                            return Text(
                              '${supervisor.fullName} (${workType?.name ?? 'N/A'})',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            );
                          }).toList(),
                        ];
                      },
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline, size: 18, color: const Color(0xFF9CA3AF)),
                              SizedBox(width: 8),
                              Text('None - No Supervisor', style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        ..._potentialSupervisors.map((supervisor) {
                          final workType = _workTypes.where((wt) => wt.id == supervisor.workTypeId).firstOrNull;
                          final hierarchyLevel = workType?.hierarchyLevel;
                          
                          String getHierarchyIcon(int? level) {
                            switch (level) {
                              case 1: return '⭐⭐⭐';
                              case 2: return '⭐⭐';
                              case 3: return '⭐';
                              case 4: return '👤';
                              case 5: return '•';
                              default: return '•';
                            }
                          }
                          
                          return DropdownMenuItem<int>(
                            value: supervisor.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Text(
                                    getHierarchyIcon(hierarchyLevel),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        supervisor.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            supervisor.employeeId,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: const Color(0xFF374151),
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          if (supervisor.workType != null) ...[
                                            Text(
                                              ' • ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: const Color(0xFF9CA3AF),
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                supervisor.workType!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: const Color(0xFF6B7280),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: _loadingSupervisors ? null : (value) {
                        setState(() => _selectedSupervisorId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectHireDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hire Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _hireDate != null
                              ? () {
                                  final ethDate = EthiopianCalendar.fromGregorian(_hireDate!);
                                  return '${ethDate.day}/${ethDate.month}/${ethDate.year}';
                                }()
                              : 'Select date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _status == 'active' 
                            ? const Color(0xFFE8F5EE) 
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _status == 'active' 
                              ? const Color(0xFFB2DFCA) 
                              : const Color(0xFFFFCC80),
                        ),
                      ),
                      child: SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(
                          _status == 'active' 
                              ? 'Worker is currently active' 
                              : 'Worker is currently inactive',
                          style: TextStyle(
                            color: _status == 'active' 
                                ? const Color(0xFF003D1F) 
                                : const Color(0xFFBF360C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _status == 'active',
                        onChanged: (value) => setState(() => _status = value ? 'active' : 'inactive'),
                        activeThumbColor: const Color(0xFF007A3D),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<EthiopianBank>(
                      value: _selectedBank,
                      decoration: InputDecoration(
                        labelText: 'Bank',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: const OutlineInputBorder(),
                        helperText: _detectedBankName != null 
                            ? '✓ Detected: $_detectedBankName' 
                            : null,
                        helperStyle: TextStyle(
                          color: const Color(0xFF005C2E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      items: EthiopianBanks.all.map((bank) {
                        return DropdownMenuItem<EthiopianBank>(
                          value: bank,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(bank.logo, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  bank.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (bank) {
                        setState(() {
                          _selectedBank = bank;
                          _detectedBankName = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bankAccountController,
                      decoration: InputDecoration(
                        labelText: 'Bank Account Number',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: const OutlineInputBorder(),
                        hintText: _selectedBank != null 
                            ? '${_selectedBank!.accountNumberLength} digits'
                            : 'Select a bank first',
                        suffixIcon: _selectedBank != null && _bankAccountController.text.isNotEmpty
                            ? (_selectedBank!.validateAccountNumber(_bankAccountController.text)
                                ? Icon(Icons.check_circle, color: const Color(0xFF005C2E))
                                : Icon(Icons.error, color: const Color(0xFFB71C1C)))
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_selectedBank?.accountNumberLength ?? 13),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (_selectedBank == null && value.isNotEmpty) {
                            final detectedBank = EthiopianBanks.detectBankFromAccount(value);
                            if (detectedBank != null) {
                              _selectedBank = detectedBank;
                              _detectedBankName = detectedBank.name;
                            }
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (_selectedBank == null) {
                          return 'Please select a bank';
                        }
                        if (!_selectedBank!.validateAccountNumber(value)) {
                          return 'Invalid account number (requires ${_selectedBank!.accountNumberLength} digits)';
                        }
                        return null;
                      },
                    ),
                    if (_selectedBank != null && _bankAccountController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Formatted: ${_selectedBank!.formatAccountNumber(_bankAccountController.text)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tinController,
                      decoration: const InputDecoration(
                        labelText: 'TIN Number (Tax ID)',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                        hintText: 'Tax Identification Number',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _overtimeRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Custom Overtime Rate (ETB/hr) — Optional',
                        prefixIcon: Icon(Icons.access_time_filled),
                        prefixText: 'ETB ',
                        border: OutlineInputBorder(),
                        helperText: 'Overrides work type default (e.g. 100 or 200 ETB/hr). Leave blank for standard/statutory rate.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIdDocumentSection() {
    final hasLocalImage = _idCardImageFile != null;
    final hasRemoteImage = !hasLocalImage && _existingIdCardUrl != null && _existingIdCardUrl!.isNotEmpty;
    final hasDocument = hasLocalImage || hasRemoteImage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_rounded, color: Color(0xFF007A3D), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'National ID / Kebele ID',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A192F),
                        ),
                      ),
                      Text(
                        'Document physical ID card for verification',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasDocument ? const Color(0xFFE8F5EE) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasDocument ? const Color(0xFF007A3D) : const Color(0xFFE65100),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasDocument ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 14,
                        color: hasDocument ? const Color(0xFF007A3D) : const Color(0xFFE65100),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasDocument ? 'Attached' : 'Recommended',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasDocument ? const Color(0xFF007A3D) : const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (hasDocument) ...[
              // Attached Document Preview Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A192F),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: hasLocalImage
                              ? Image.file(
                                  _idCardImageFile!,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _resolvedExistingIdCardUrl ?? _existingIdCardUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1E3A5F),
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.broken_image_rounded, color: Colors.white70, size: 36),
                                          SizedBox(height: 8),
                                          Text('Failed to load image', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // Top gradient overlay with status
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xB3000000), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007A3D),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.shield_rounded, color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Official ID Card',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (hasLocalImage) {
                                      _showFullscreenImagePreview(FileImage(_idCardImageFile!));
                                    } else {
                                      _showFullscreenImagePreview(NetworkImage(_resolvedExistingIdCardUrl ?? _existingIdCardUrl!));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0x66000000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Action toolbar below preview
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      color: const Color(0xFF0A192F),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showDocumentSourceSheet,
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                              label: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0x40FFFFFF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (hasLocalImage) {
                                  _showFullscreenImagePreview(FileImage(_idCardImageFile!));
                                } else {
                                  _showFullscreenImagePreview(NetworkImage(_resolvedExistingIdCardUrl ?? _existingIdCardUrl!));
                                }
                              },
                              icon: const Icon(Icons.zoom_in_rounded, size: 16, color: Color(0xFF33A86A)),
                              label: const Text('View Zoom', style: TextStyle(color: Color(0xFF33A86A), fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0x6633A86A)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF5350), size: 20),
                            onPressed: () {
                              setState(() {
                                _idCardImageFile = null;
                                _existingIdCardUrl = null;
                                _resolvedExistingIdCardUrl = null;
                              });
                            },
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // No Document - Enterprise Capture Card
              GestureDetector(
                onTap: _showDocumentSourceSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFB2DFCA),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 26, color: Color(0xFF007A3D)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Capture National ID or Kebele ID',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A192F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Frame worker\'s ID card with device camera or choose from gallery',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickIdCardImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: const Text('Use Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007A3D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => _pickIdCardImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF0A192F)),
                            label: const Text('From Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A192F))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0A192F)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
