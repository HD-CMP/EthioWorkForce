import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/storage_service.dart';
import '../../../workers/data/datasources/work_place_remote_datasource.dart';
import '../../../workers/data/datasources/site_remote_datasource.dart';
import '../../../workers/domain/entities/work_place.dart';
import '../../../workers/domain/entities/site.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/datasources/roles_remote_datasource.dart';
import '../../data/datasources/users_remote_datasource.dart';
import '../../data/models/registration_request.dart';
import '../../data/models/role_model.dart';
import '../../data/models/user_model.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminRegistrationPage extends StatelessWidget {
  const AdminRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc(
        datasource: AdminRemoteDatasource(getIt<Dio>()),
      ),
      child: const _AdminRegistrationPageContent(),
    );
  }
}

class _AdminRegistrationPageContent extends StatefulWidget {
  const _AdminRegistrationPageContent();

  @override
  State<_AdminRegistrationPageContent> createState() =>
      _AdminRegistrationPageContentState();
}

class _AdminRegistrationPageContentState
    extends State<_AdminRegistrationPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storageService = StorageService();
  final _siteDataSource = SiteRemoteDataSource();
  List<Site> _sites = [];
  Site? _selectedSite;
  String? _userRole;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRole();
    _loadSites();
  }

  Future<void> _loadUserRole() async {
    try {
      // Try to get from storage first
      String? role = await _storageService.getUserRole();
      
      // If not in storage, fetch from API
      if (role == null) {
        try {
          final dio = getIt<Dio>();
          final response = await dio.get('/users/me');
          final userData = response.data;
          role = userData['role'] as String?;
          
          if (role != null) {
            await _storageService.setUserRole(role);
          }
        } catch (e) {
          debugPrint('Error fetching user role from API: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _userRole = role;
          _isSuperAdmin = role == 'super_admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  Future<void> _loadSites() async {
    try {
      final sites = await _siteDataSource.getSites(isActive: true);
      final savedSiteId = await _storageService.getSelectedSiteId();
      
      Site? siteToSelect;
      if (savedSiteId != null && sites.any((s) => s.id == savedSiteId)) {
        siteToSelect = sites.firstWhere((s) => s.id == savedSiteId);
      } else if (sites.isNotEmpty) {
        siteToSelect = sites.first;
        if (siteToSelect.id != null) {
          await _storageService.setSelectedSiteId(siteToSelect.id!);
        }
      }
      
      if (mounted) {
        setState(() {
          _sites = sites;
          _selectedSite = siteToSelect;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _showSiteSelectorDialog() {
    try {
      if (_sites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('No sites available'),
            ]),
            backgroundColor: const Color(0xFF0A192F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
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
                  final isSelected = _selectedSite?.id == site.id;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF007A3D) : null,
                    ),
                    title: Text(site.name),
                    subtitle: Text(site.code),
                    onTap: () async {
                      Navigator.pop(context);
                      if (site.id != null) {
                        await _storageService.setSelectedSiteId(site.id!);
                        setState(() {
                          _selectedSite = site;
                        });
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Registration'),
            if (_userRole != null)
              Text(
                _userRole!.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontSize: 11, color: Color(0xCCFFFFFF)),
              ),
          ],
        ),
        actions: [
          if (_isSuperAdmin && _sites.length > 1)
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _showSiteSelectorDialog,
              tooltip: 'Select Site',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xB3FFFFFF),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Register New'),
            Tab(icon: Icon(Icons.info_outline), text: 'Details'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _RegisterAdminTab(),
          _AdminDetailsTab(selectedSite: _selectedSite),
          _PendingRequestsTab(selectedSite: _selectedSite),
        ],
      ),
    );
  }
}

class _RegisterAdminTab extends StatefulWidget {
  const _RegisterAdminTab();

  @override
  State<_RegisterAdminTab> createState() => _RegisterAdminTabState();
}

class _RegisterAdminTabState extends State<_RegisterAdminTab> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storageService = StorageService();

  String _selectedRole = 'admin';
  final List<int> _selectedWorkplaces = [];
  List<WorkPlace> _filteredWorkplaces = [];
  List<Site> _sites = [];
  List<RoleModel> _roles = [];
  List<UserModel> _searchResults = [];
  Site? _selectedSite;
  UserModel? _selectedUser;
  bool _loadingWorkplaces = false;
  bool _loadingSites = false;
  bool _loadingRoles = false;
  bool _searchingUsers = false;
  bool _isExistingUser = false;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserContext();
    _loadSites();
    _loadRoles();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCurrentUserContext() async {
    try {
      final role = await _storageService.getUserRole();
      if (mounted) {
        setState(() {
          _currentUserRole = role;
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Require site selection before searching
    if (_selectedSite == null) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchingUsers = true;
    });

    try {
      final datasource = UsersRemoteDatasource(getIt<Dio>());
      final results = await datasource.searchUsers(
        query,
        siteId: _selectedSite!.id,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searchingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchingUsers = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFE65100),
          ),
        );
      }
    }
  }

  String _generateUsername(String fullName) {
    // Convert to lowercase and remove special characters
    String username = fullName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    
    // If too long, take first part
    if (username.length > 20) {
      username = username.substring(0, 20);
    }
    
    return username;
  }

  Future<String> _getUniqueUsername(String baseUsername) async {
    try {
      final dio = getIt<Dio>();
      String username = baseUsername;
      int counter = -1;
      
      while (counter < 100) {
        try {
          // Check if username is available
          final response = await dio.get(
            '/users/check-username',
            queryParameters: {'username': username},
          );
          // If successful response (200), username is available
          if (response.statusCode == 200) {
            return username;
          }
        } on DioException catch (e) {
          // If 409 (conflict), username exists, try next
          if (e.response?.statusCode == 409) {
            counter++;
            username = '$baseUsername$counter';
          } else {
            // Other error, return base username
            return baseUsername;
          }
        }
      }
      
      // Fallback if all attempts failed
      return '${baseUsername}_${DateTime.now().millisecondsSinceEpoch % 10000}';
    } catch (e) {
      debugPrint('DEBUG: Error checking username: $e');
      return baseUsername;
    }
  }

  String _determineRoleFromHierarchy(int? level, String? workTypeName) {
    final title = (workTypeName ?? '').toLowerCase();
    
    // Level 3 or Site Manager title -> site_admin (Full 8 modules scoped to site)
    if (level == 3 ||
        title.contains('site manager') ||
        title.contains('project manager') ||
        title.contains('site engineer')) {
      return 'site_admin';
    }
    // Level 1 or 2 -> admin (Executive / Cross-Site)
    if (level == 1 ||
        level == 2 ||
        title.contains('director') ||
        title.contains('executive')) {
      return 'admin';
    }
    // Level 4 -> supervisor (Field Operations, Timekeeping)
    if (level == 4 ||
        title.contains('supervisor') ||
        title.contains('foreman') ||
        title.contains('timekeeper') ||
        title.contains('lead')) {
      return 'supervisor';
    }
    // Level 5, 6 or operational workforce
    return 'viewer';
  }

  String _getHierarchyName(int level) {
    switch (level) {
      case 1:
        return 'Executive';
      case 2:
        return 'Senior Mgmt';
      case 3:
        return 'Site Mgmt';
      case 4:
        return 'Supervisory';
      case 5:
        return 'Operational';
      case 6:
        return 'Trainee';
      default:
        return 'Level $level';
    }
  }

  void _selectUser(UserModel user) async {
    // Generate smart username from full name
    final baseUsername = _generateUsername(user.fullName);
    final uniqueUsername = await _getUniqueUsername(baseUsername);
    
    if (!mounted) return;

    final determinedRole = _determineRoleFromHierarchy(user.hierarchyLevel, user.workTypeName);

    setState(() {
      _selectedUser = user;
      _isExistingUser = false;
      _usernameController.text = uniqueUsername;
      _emailController.text = user.email;
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phoneNumber ?? '';
      _searchController.text = user.fullName;
      _searchResults = [];

      // Auto-assign the role based on hierarchy
      if (_roles.any((r) => r.name == determinedRole)) {
        _selectedRole = determinedRole;
      } else if (determinedRole == 'site_admin' && _roles.any((r) => r.name == 'site_admin')) {
        _selectedRole = 'site_admin';
      } else if (_roles.isNotEmpty) {
        _selectedRole = _roles.first.name;
      }
      
      // Auto-select workplace if worker has one assigned
      _selectedWorkplaces.clear();
      if (user.workPlaceId != null) {
        _selectedWorkplaces.add(user.workPlaceId!);
      }
    });
    
    // If user has a different site, switch to it and reload workplaces (if not restricted site_admin)
    if (user.siteId != null && user.siteId != _selectedSite?.id && _currentUserRole != 'site_admin') {
      final site = _sites.firstWhere(
        (s) => s.id == user.siteId,
        orElse: () => _sites.first,
      );
      setState(() {
        _selectedSite = site;
      });
      await _loadWorkplaces();
      
      // Re-apply workplace selection after workplaces are loaded
      if (user.workPlaceId != null && mounted) {
        setState(() {
          _selectedWorkplaces.clear();
          _selectedWorkplaces.add(user.workPlaceId!);
        });
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedUser = null;
      _isExistingUser = false;
      _usernameController.clear();
      _emailController.clear();
      _fullNameController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _searchController.clear();
      _searchResults = [];
    });
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loadingRoles = true;
    });
    try {
      final datasource = RolesRemoteDatasource(getIt<Dio>());
      final allRoles = await datasource.getRoles(isActive: true);
      final currentRole = await _storageService.getUserRole();
      if (mounted) {
        setState(() {
          var filtered = allRoles.where((r) => r.name != 'super_admin').toList();
          if (currentRole == 'site_admin') {
            filtered = filtered.where((r) => r.name != 'admin').toList();
          }
          _roles = filtered;
          _loadingRoles = false;
          if (_roles.isNotEmpty && !_roles.any((r) => r.name == _selectedRole)) {
            _selectedRole = _roles.first.name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRoles = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Unable to load roles. Please try again.')),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _loadSites() async {
    setState(() {
      _loadingSites = true;
    });
    try {
      final datasource = SiteRemoteDataSource();
      var sites = await datasource.getSites(isActive: true);
      
      final currentRole = await _storageService.getUserRole();
      final savedSiteId = await _storageService.getSelectedSiteId();

      if (currentRole == 'site_admin' && savedSiteId != null) {
        sites = sites.where((s) => s.id == savedSiteId).toList();
      }
      
      Site? siteToSelect;
      if (savedSiteId != null && sites.any((s) => s.id == savedSiteId)) {
        siteToSelect = sites.firstWhere((s) => s.id == savedSiteId);
      } else if (sites.isNotEmpty) {
        siteToSelect = sites.first;
        if (siteToSelect.id != null) {
          await _storageService.setSelectedSiteId(siteToSelect.id!);
        }
      }
      
      if (mounted) {
        setState(() {
          _currentUserRole = currentRole;
          _sites = sites;
          _selectedSite = siteToSelect;
          _loadingSites = false;
        });
        
        if (_selectedSite != null) {
          _loadWorkplaces();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSites = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Unable to load sites. Please try again.')),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _loadWorkplaces() async {
    if (_selectedSite == null) return;
    
    setState(() {
      _loadingWorkplaces = true;
    });
    try {
      final datasource = WorkPlaceRemoteDataSource();
      final workplaces = await datasource.getWorkPlaces(
        siteId: _selectedSite!.id,
        isActive: true,
      );
      if (mounted) {
        setState(() {
          _filteredWorkplaces = workplaces;
          _loadingWorkplaces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingWorkplaces = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Unable to load workplaces. Please try again.')),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _onSiteChanged(Site? site) async {
    if (site != null && site.id != _selectedSite?.id) {
      if (site.id != null) {
        await _storageService.setSelectedSiteId(site.id!);
      }
      if (mounted) {
        setState(() {
          _selectedSite = site;
          _selectedWorkplaces.clear();
          // Clear search when site changes
          _searchController.clear();
          _searchResults = [];
          _selectedUser = null;
          _isExistingUser = false;
        });
        _loadWorkplaces();
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is RegistrationSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration request submitted successfully'),
              backgroundColor: const Color(0xFF007A3D),
            ),
          );
          _formKey.currentState!.reset();
          _usernameController.clear();
          _emailController.clear();
          _fullNameController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          setState(() {
            _selectedWorkplaces.clear();
          });
        } else if (state is AdminError) {
          if (state.apiError?.isDuplicateRequest == true) {
            _showDuplicateRequestDialog(context, state.apiError!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFB71C1C),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
      child: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          final isLoading = state is AdminLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. TARGET SITE ASSIGNMENT CARD ──
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_city_rounded, color: Color(0xFF007A3D), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Target Site Assignment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0A192F),
                                ),
                              ),
                              const Spacer(),
                              if (_currentUserRole == 'site_admin')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Locked to Your Site',
                                    style: TextStyle(
                                      color: Color(0xFFE65100),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_currentUserRole == 'site_admin') ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7F4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD1D5DB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.business, color: Color(0xFF007A3D), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedSite?.name ?? 'Assigned Site',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A192F),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 18),
                                ],
                              ),
                            ),
                          ] else ...[
                            _loadingSites
                                ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                                : DropdownButtonFormField<Site>(
                                    value: _selectedSite,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Site *',
                                      prefixIcon: Icon(Icons.business_outlined),
                                      border: OutlineInputBorder(),
                                      helperText: 'Admin account and workers are bound to this site',
                                    ),
                                    items: _sites.map((site) {
                                      return DropdownMenuItem<Site>(
                                        value: site,
                                        child: Text(site.name),
                                      );
                                    }).toList(),
                                    onChanged: _onSiteChanged,
                                    validator: (value) {
                                      if (value == null) return 'Please select a site';
                                      return null;
                                    },
                                  ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 2. LINK WORKER OR USER CARD ──
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_search_rounded,
                                color: Color(0xFF007A3D),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Link Worker or Existing Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF007A3D),
                                ),
                              ),
                              const Spacer(),
                              if (_selectedUser != null)
                                TextButton.icon(
                                  onPressed: _clearSelection,
                                  icon: const Icon(Icons.clear, size: 18),
                                  label: const Text('Clear'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFB71C1C),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Search by worker name, employee ID, or username to automatically configure RBAC and site credentials.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _searchController,
                            enabled: _selectedUser == null && _selectedSite != null,
                            decoration: InputDecoration(
                              hintText: _selectedSite == null
                                  ? 'Please select a site first...'
                                  : 'Search by employee ID, name, or username...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchingUsers
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _selectedUser != null
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF007A3D),
                                        )
                                      : null,
                              border: const OutlineInputBorder(),
                              filled: _selectedUser != null ? true : false,
                              fillColor: _selectedUser != null ? const Color(0xFFE8F5EE) : null,
                            ),
                          ),
                          if (_searchResults.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 220),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFD1D5DB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  final isManager = user.hierarchyLevel == 3 ||
                                      (user.workTypeName?.toLowerCase().contains('site manager') ?? false);
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isManager ? const Color(0xFF0A192F) : const Color(0xFF007A3D),
                                      child: Text(
                                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'W',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${user.employeeId != null ? "${user.employeeId} • " : ""}${user.workTypeName ?? user.role}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Wrap(
                                      spacing: 6,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (user.hierarchyLevel != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0A192F),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'L${user.hierarchyLevel}',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isManager ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5EE),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isManager ? const Color(0xFFFF9800) : const Color(0xFF007A3D),
                                            ),
                                          ),
                                          child: Text(
                                            isManager ? 'SITE ADMIN' : user.role.toUpperCase(),
                                            style: TextStyle(
                                              color: isManager ? const Color(0xFFE65100) : const Color(0xFF007A3D),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _selectUser(user),
                                  );
                                },
                              ),
                            ),
                          ],
                          if (_selectedUser != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE8F5EE), Color(0xFFF4F7F4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF81C784)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF007A3D),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.verified_user_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    _selectedUser!.fullName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0A192F),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (_selectedUser!.employeeId != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF0A192F),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      _selectedUser!.employeeId!,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _selectedUser!.workTypeName ?? 'Field Workforce Member',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF4B5563),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Color(0xFFC8E6C9)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (_selectedUser!.hierarchyLevel != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A192F),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Level ${_selectedUser!.hierarchyLevel}: ${_getHierarchyName(_selectedUser!.hierarchyLevel!)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF007A3D),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Auto-Role: ${_selectedRole.toUpperCase()}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_selectedRole == 'site_admin')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF3E0),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFFB74D)),
                                          ),
                                          child: const Text(
                                            'All 8 Modules • Site Scoped',
                                            style: TextStyle(
                                              color: Color(0xFFE65100),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedRole == 'site_admin'
                                        ? '✓ Site Manager profile automatically selected. This account will have full access to all 8 operational modules, strictly restricted to ${_selectedSite?.name ?? "the assigned site"}.'
                                        : '✓ Enterprise RBAC mapped. System role has been pre-selected according to organizational hierarchy. Administrator can override the role below if desired.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2E7D32),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.account_circle),
                              border: OutlineInputBorder(),
                              helperText: 'Auto-generated, editable',
                              helperStyle: TextStyle(fontSize: 11),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter username';
                              }
                              if (value.length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email (Optional)',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && !value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Role & Permissions',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/role-management',
                                  );
                                  _loadRoles();
                                },
                                icon: const Icon(Icons.settings, size: 18),
                                label: const Text('Manage Roles'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _loadingRoles
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                    prefixIcon: Icon(Icons.security),
                                    border: OutlineInputBorder(),
                                    helperText: 'Select user role and permissions',
                                  ),
                                  items: _roles.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role.name,
                                      child: Text(role.displayName),
                                    );
                                  }).toList(),
                                  onChanged: _roles.isEmpty
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedRole = value!;
                                          });
                                        },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a role';
                                    }
                                    return null;
                                  },
                                ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'site_admin'
                                  ? const Color(0xFFE8F5EE)
                                  : const Color(0xFFF8FAF8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedRole == 'site_admin'
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _selectedRole == 'site_admin'
                                      ? Icons.domain_verification_rounded
                                      : _selectedRole == 'admin'
                                          ? Icons.admin_panel_settings_rounded
                                          : Icons.info_outline_rounded,
                                  size: 18,
                                  color: _selectedRole == 'site_admin'
                                      ? const Color(0xFF007A3D)
                                      : const Color(0xFF4B5563),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedRole == 'site_admin'
                                        ? 'Site Administrator: Full access to all 8 operational modules (Workers, Attendance, Payroll, Sites, Work Types, Reports, Admins, Settings), strictly scoped to ${_selectedSite?.name ?? "the assigned site"}.'
                                        : _selectedRole == 'admin'
                                            ? 'Administrator: Multi-site operational authority across all company sites.'
                                            : _selectedRole == 'supervisor'
                                                ? 'Supervisor: Frontline operational access for attendance logging, biometric/QR check-in, and overtime records.'
                                                : 'Role permissions will be applied according to organizational policy.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _selectedRole == 'site_admin'
                                          ? const Color(0xFF005C2E)
                                          : const Color(0xFF374151),
                                      fontWeight: _selectedRole == 'site_admin'
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Assign Workplaces'),
                            subtitle: Text(
                              _selectedWorkplaces.isEmpty
                                  ? 'No workplaces selected'
                                  : '${_selectedWorkplaces.length} workplace(s) selected',
                            ),
                            trailing: _loadingWorkplaces
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward_ios),
                            onTap: _loadingWorkplaces
                                ? null
                                : () => _showWorkplacePicker(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              helperText: _isExistingUser 
                                  ? 'Leave empty to keep current password, or enter new password to update'
                                  : 'Required - minimum 6 characters',
                            ),
                            validator: (value) {
                              if (!_isExistingUser &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter password';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_passwordController.text.isNotEmpty &&
                                  value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isExistingUser
                                ? 'Upgrade to Admin'
                                : 'Register Admin',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWorkplacePicker() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A3D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Select Workplaces',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1A007A3D),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0x4D007A3D),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_selectedWorkplaces.length} selected',
                            style: TextStyle(
                              color: const Color(0xFF007A3D),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: const Color(0xFF374151),
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_selectedSite != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFD1D5DB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: const Color(0xFF007A3D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedSite!.name,
                        style: TextStyle(
                          fontSize: 15,
                          color: const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _filteredWorkplaces.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off,
                              size: 64,
                              color: const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No workplaces available',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create workplaces for this site first',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredWorkplaces.length,
                        itemBuilder: (context, index) {
                          final workplace = _filteredWorkplaces[index];
                          final isSelected = _selectedWorkplaces.contains(workplace.id);
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedWorkplaces.remove(workplace.id);
                                } else if (workplace.id != null) {
                                  _selectedWorkplaces.add(workplace.id!);
                                }
                              });
                              Navigator.pop(dialogContext);
                              _showWorkplacePicker();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF007A3D)
                                      : const Color(0xFFD1D5DB),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF007A3D)
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.location_city,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workplace.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8EDF4),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                workplace.code,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: const Color(0xFF0A192F),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (workplace.locationAddress != null) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.location_on,
                                                size: 13,
                                                color: const Color(0xFF9CA3AF),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  workplace.locationAddress!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: const Color(0xFF6B7280),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (workplace.description != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            workplace.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF6B7280),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF007A3D)
                                            : const Color(0xFF9CA3AF),
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? const Color(0xFF007A3D)
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _selectedWorkplaces.isEmpty
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF007A3D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _selectedWorkplaces.isEmpty ? 'Close' : 'Save',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDuplicateRequestDialog(BuildContext context, ApiError error) {
    final requestId = error.details?['request_id'];
    final username = error.details?['username'];
    final createdAt = error.details?['created_at'];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: const Color(0xFFE65100)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Pending Request Exists')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A registration request for "$username" is already pending approval.',
              style: const TextStyle(fontSize: 15),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Created: ${_formatDateTime(createdAt)}',
                style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'You can:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('� Wait for the existing request to be approved'),
            const Text('� Cancel the existing request and submit a new one'),
            const Text('� Modify the existing request details'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
          if (requestId != null)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _cancelExistingRequest(requestId);
              },
              child: const Text('Cancel Existing Request'),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _cancelExistingRequest(int requestId) async {
    try {
      final datasource = AdminRemoteDatasource(getIt<Dio>());
      await datasource.cancelRequest(requestId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text('Previous request cancelled successfully. You can now submit a new request.'),
              ),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Failed to cancel request: ${e.toString()}')),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSite == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Please select a site'),
            ]),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
      
      final request = RegistrationRequest(
        username: _usernameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text.isEmpty
            ? null
            : _phoneController.text,
        password: _passwordController.text,
        role: _selectedRole,
        siteIds: _selectedSite!.id != null ? [_selectedSite!.id!] : null,
        workPlaceIds: _selectedWorkplaces.isEmpty ? null : _selectedWorkplaces,
        workerId: _selectedUser?.workerId ?? _selectedUser?.id,
      );

      context.read<AdminBloc>().add(SubmitRegistrationEvent(request));
    }
  }
}

class _AdminDetailsTab extends StatefulWidget {
  final Site? selectedSite;
  
  const _AdminDetailsTab({this.selectedSite});

  @override
  State<_AdminDetailsTab> createState() => _AdminDetailsTabState();
}

class _AdminDetailsTabState extends State<_AdminDetailsTab> {
  List<dynamic> _admins = [];
  bool _loading = false;
  final _searchController = TextEditingController();
  List<dynamic> _filteredAdmins = [];
  bool _hasWorkplaceAssignment = true;
  bool _checkingWorkplaceAssignment = true;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterAdmins);
    _checkCurrentUserWorkplaceAssignment();
    if (widget.selectedSite != null) {
      _loadAdmins();
    }
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingWorkplaceAssignment = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(_AdminDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSite?.id != widget.selectedSite?.id) {
      if (widget.selectedSite != null) {
        _loadAdmins();
      } else {
        setState(() {
          _admins = [];
          _filteredAdmins = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    if (widget.selectedSite == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final dio = getIt<Dio>();
      final response = await dio.get('/users');

      final allUsers = response.data as List<dynamic>;
      
      // Filter admins for selected site
      final siteAdmins = allUsers.where((user) {
        final assignments = user['site_assignments'] as List<dynamic>?;
        if (assignments == null) return false;
        return assignments.any((a) => a['site_id'] == widget.selectedSite!.id);
      }).toList();

      if (mounted) {
        setState(() {
          _admins = siteAdmins;
          _filteredAdmins = siteAdmins;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      
      String errorMessage;
      if (e is ApiError) {
        errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      } else {
        final apiError = ErrorHandler.extractError(e);
        errorMessage = ErrorHandler.getUserFriendlyMessage(apiError);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load admins: $errorMessage'),
            backgroundColor: const Color(0xFFB71C1C),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _filterAdmins() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAdmins = _admins.where((admin) {
        final name = (admin['full_name'] as String? ?? '').toLowerCase();
        final username = (admin['username'] as String? ?? '').toLowerCase();
        final email = (admin['email'] as String? ?? '').toLowerCase();
        final role = (admin['role'] as String? ?? '').toLowerCase();
        return name.contains(query) || username.contains(query) || 
               email.contains(query) || role.contains(query);
      }).toList();
    });
  }

  void _showAdminDetails(dynamic admin) {
    showDialog(
      context: context,
      builder: (context) => _AdminDetailsDialog(
        admin: admin,
        onSave: () {
          _loadAdmins();
        },
        onDelete: () {
          _loadAdmins();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show warning if admin has no workplace assignment (but not for super admins)
    if (!_checkingWorkplaceAssignment && !_isSuperAdmin && !_hasWorkplaceAssignment) {
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
                        'Once assigned, you\'ll be able to manage admins and workers in your workplace.',
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

    return Column(
      children: [
        if (widget.selectedSite != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF3F4F6),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, username, email, or role...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAdmins.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.admin_panel_settings_outlined,
                              size: 64, color: const Color(0xFF9CA3AF)),
                          const SizedBox(height: 16),
                          Text(
                            widget.selectedSite == null
                                ? 'Select a site to view admins'
                                : 'No admins found',
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredAdmins.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final admin = _filteredAdmins[index];
                        return _buildAdminCard(admin);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAdminCard(dynamic admin) {
    final isActive = admin['is_active'] as bool? ?? true;
    final statusColor = isActive ? const Color(0xFF007A3D) : const Color(0xFFB71C1C);
    final role = admin['role'] as String? ?? 'admin';

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showAdminDetails(admin),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF007A3D),
                child: Text(
                  (admin['full_name'] as String? ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            admin['full_name'] as String? ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(26, statusColor.red, statusColor.green, statusColor.blue),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '@${admin['username'] as String? ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EDF4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined, size: 11, color: Color(0xFF0A192F)),
                              const SizedBox(width: 4),
                              Text(
                                role.toUpperCase().replaceAll('_', ' '),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF0A192F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: const Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            admin['email'] as String? ?? 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF374151),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: const Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDetailsDialog extends StatefulWidget {
  final dynamic admin;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const _AdminDetailsDialog({
    required this.admin,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_AdminDetailsDialog> createState() => _AdminDetailsDialogState();
}

class _AdminDetailsDialogState extends State<_AdminDetailsDialog> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _saving = false;
  bool _deleting = false;
  List<WorkPlace> _assignedWorkplaces = [];
  List<WorkPlace> _availableWorkplaces = [];
  List<int> _selectedWorkplaceIds = [];
  bool _loadingWorkplaces = false;
  bool _loadingAvailableWorkplaces = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.admin['full_name'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: widget.admin['email'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.admin['phone_number'] as String? ?? '',
    );
    _loadWorkplaceDetails();
  }

  Future<void> _loadWorkplaceDetails() async {
    final workplaceAssignments = widget.admin['work_place_assignments'] as List<dynamic>? ?? [];
    
    setState(() {
      _loadingWorkplaces = true;
    });

    try {
      final datasource = WorkPlaceRemoteDataSource();
      final List<WorkPlace> loadedWorkplaces = [];
      final List<int> workplaceIds = [];
      
      for (var assignment in workplaceAssignments) {
        final workplaceId = assignment['work_place_id'] as int?;
        if (workplaceId != null) {
          workplaceIds.add(workplaceId);
          try {
            final workplace = await datasource.getWorkPlaceById(workplaceId);
            loadedWorkplaces.add(workplace);
          } catch (e) {
            debugPrint('Failed to load workplace $workplaceId: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _assignedWorkplaces = loadedWorkplaces;
          _selectedWorkplaceIds = workplaceIds;
          _loadingWorkplaces = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading workplace details: $e');
      if (mounted) {
        setState(() {
          _loadingWorkplaces = false;
        });
      }
    }
  }

  Future<void> _loadAvailableWorkplaces() async {
    if (_loadingAvailableWorkplaces) return;

    final siteAssignments = widget.admin['site_assignments'] as List<dynamic>? ?? [];
    if (siteAssignments.isEmpty) return;

    setState(() {
      _loadingAvailableWorkplaces = true;
    });

    try {
      final datasource = WorkPlaceRemoteDataSource();
      final dio = getIt<Dio>();
      final List<WorkPlace> allWorkplaces = [];

      // Get current user info to check role and workplace assignments
      final currentUserResponse = await dio.get('/users/me');
      final currentUser = currentUserResponse.data;
      final currentUserRole = currentUser['role'] as String?;
      final isSuperAdmin = currentUserRole == 'super_admin';

      if (isSuperAdmin) {
        // Super admins can see all workplaces in the admin's assigned sites
        for (var assignment in siteAssignments) {
          final siteId = assignment['site_id'] as int?;
          if (siteId != null) {
            try {
              final workplaces = await datasource.getWorkPlaces(
                siteId: siteId,
                isActive: true,
              );
              allWorkplaces.addAll(workplaces);
            } catch (e) {
              debugPrint('Failed to load workplaces for site $siteId: $e');
            }
          }
        }
      } else {
        // Regular admins can only assign their own workplaces
        final currentUserWorkplaceAssignments = currentUser['work_place_assignments'] as List<dynamic>? ?? [];
        final currentUserWorkplaceIds = currentUserWorkplaceAssignments
            .map((assignment) => assignment['work_place_id'] as int?)
            .whereType<int>()
            .toSet();

        if (currentUserWorkplaceIds.isEmpty) {
          // If no workplace assignments, load all workplaces from assigned sites
          // (fallback for backward compatibility)
          for (var assignment in siteAssignments) {
            final siteId = assignment['site_id'] as int?;
            if (siteId != null) {
              try {
                final workplaces = await datasource.getWorkPlaces(
                  siteId: siteId,
                  isActive: true,
                );
                allWorkplaces.addAll(workplaces);
              } catch (e) {
                debugPrint('Failed to load workplaces for site $siteId: $e');
              }
            }
          }
        } else {
          // Load only the workplaces the current admin is assigned to
          for (var workplaceId in currentUserWorkplaceIds) {
            try {
              final workplace = await datasource.getWorkPlaceById(workplaceId);
              allWorkplaces.add(workplace);
            } catch (e) {
              debugPrint('Failed to load workplace $workplaceId: $e');
            }
          }
        }
      }

      final uniqueWorkplaces = <int, WorkPlace>{};
      for (var wp in allWorkplaces) {
        if (wp.id != null) {
          uniqueWorkplaces[wp.id!] = wp;
        }
      }

      if (mounted) {
        setState(() {
          _availableWorkplaces = uniqueWorkplaces.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          _loadingAvailableWorkplaces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAvailableWorkplaces = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load available workplaces: $e'),
            backgroundColor: const Color(0xFFE65100),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _saving = true;
    });

    try {
      final dio = getIt<Dio>();
      
      await dio.patch(
        '/users/${widget.admin['id']}/profile',
        data: {
          'full_name': _fullNameController.text,
          'email': _emailController.text,
          'phone_number': _phoneController.text.isEmpty ? null : _phoneController.text,
        },
      );

      if (_selectedWorkplaceIds.isNotEmpty) {
        try {
          await dio.post(
            '/users/${widget.admin['id']}/workplace-assignments',
            data: {
              'workplace_ids': _selectedWorkplaceIds,
            },
          );
        } catch (e) {
          debugPrint('Failed to update workplace assignments: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Admin details updated successfully'),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        widget.onSave();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Failed to update admin: $e')),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isResetting = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: const Color(0xFF007A3D), size: 28),
              const SizedBox(width: 12),
              const Text('Reset Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Set a new password for ${widget.admin['full_name']}.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isResetting ? null : () async {
                if (formKey.currentState?.validate() ?? false) {
                  setState(() => isResetting = true);
                  try {
                    final datasource = UsersRemoteDatasource(getIt<Dio>());
                    await datasource.resetPassword(
                      widget.admin['id'], 
                      passwordController.text
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(children: [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text('Password reset successfully'),
                          ]),
                          backgroundColor: const Color(0xFF007A3D),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Failed to reset password: $e')),
                          ]),
                          backgroundColor: const Color(0xFFB71C1C),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => isResetting = false);
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A3D),
                foregroundColor: Colors.white,
              ),
              child: isResetting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAdmin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C), size: 28),
            SizedBox(width: 12),
            Text('Delete Admin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${widget.admin['full_name']}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The admin will lose access to the system.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _deleting = true;
      });

      try {
        final dio = getIt<Dio>();
        await dio.delete('/users/${widget.admin['id']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Admin deleted successfully'),
              ]),
              backgroundColor: const Color(0xFF007A3D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          widget.onDelete();
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to delete admin: $e')),
              ]),
              backgroundColor: const Color(0xFFB71C1C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _deleting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x26000000),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF007A3D),
                    const Color(0xD9007A3D),
                    const Color(0xB3007A3D),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x4D007A3D),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: avatar + name/username + close button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          (widget.admin['full_name'] as String? ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFF007A3D),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.admin['full_name'] as String? ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.alternate_email, size: 13, color: const Color(0xB3FFFFFF)),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    widget.admin['username'] as String? ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 2: action buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: const Color(0x8AFFFFFF)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.lock_reset, size: 16),
                        label: const Text('Reset Pwd', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      if (!_deleting)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF9A9A),
                            side: BorderSide(color: const Color(0xFFE57373)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _deleteAdmin,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete', style: TextStyle(fontSize: 12)),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: const Color(0x8AFFFFFF)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => setState(() => _isEditing = !_isEditing),
                        icon: Icon(_isEditing ? Icons.cancel_outlined : Icons.edit_outlined, size: 16),
                        label: Text(_isEditing ? 'Cancel' : 'Edit', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Contact Information',
                        Icons.person_outline,
                        const Color(0xFF1E3A5F),
                        [
                          _buildDetailField(
                            'Full Name',
                            _fullNameController,
                            Icons.badge_outlined,
                          ),
                          _buildDetailField(
                            'Email',
                            _emailController,
                            Icons.email_outlined,
                          ),
                          _buildDetailField(
                            'Phone Number',
                            _phoneController,
                            Icons.phone_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildSection(
                        'Account Details',
                        Icons.admin_panel_settings_outlined,
                        const Color(0xFF0A192F),
                        [
                          _buildReadOnlyField(
                            'Username',
                            widget.admin['username'] as String? ?? 'N/A',
                            Icons.person_outline,
                          ),
                          _buildReadOnlyField(
                            'Role',
                            (widget.admin['role'] as String? ?? 'admin')
                                .toUpperCase()
                                .replaceAll('_', ' '),
                            Icons.shield_outlined,
                          ),
                          _buildReadOnlyField(
                            'Status',
                            (widget.admin['is_active'] as bool? ?? true)
                                ? 'ACTIVE'
                                : 'INACTIVE',
                            Icons.info_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildSection(
                        'Workplace Assignments',
                        Icons.business_outlined,
                        const Color(0xFFE65100),
                        [
                          _buildWorkplaceAssignmentsList(),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildSection(
                        'Site Assignments',
                        Icons.location_on_outlined,
                        const Color(0xFF007A3D),
                        [
                          _buildSiteAssignmentsList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0D000000),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 20),
                      label: Text(
                        _saving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x08000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(20, color.red, color.green, color.blue),
                  Color.fromARGB(13, color.red, color.green, color.blue),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(38, color.red, color.green, color.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF007A3D), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value,
        enabled: false,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _showWorkplaceSelector() async {
    if (_availableWorkplaces.isEmpty && !_loadingAvailableWorkplaces) {
      await _loadAvailableWorkplaces();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE65100),
                          const Color(0xD9E65100),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Select Workplaces',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_selectedWorkplaceIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x4DFFFFFF),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${_selectedWorkplaceIds.length} selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_loadingAvailableWorkplaces)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_availableWorkplaces.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_off, size: 64, color: const Color(0xFF9CA3AF)),
                            const SizedBox(height: 16),
                            Text(
                              'No workplaces available',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableWorkplaces.length,
                        itemBuilder: (context, index) {
                          final workplace = _availableWorkplaces[index];
                          final isSelected = _selectedWorkplaceIds.contains(workplace.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedWorkplaceIds.remove(workplace.id);
                                  } else if (workplace.id != null) {
                                    _selectedWorkplaceIds.add(workplace.id!);
                                  }
                                });
                                setDialogState(() {});
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFE65100) : const Color(0xFFD1D5DB),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFE65100) : const Color(0xFF9CA3AF),
                                          width: 2,
                                        ),
                                        color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workplace.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? const Color(0xFFBF360C) : const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            workplace.code,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isSelected ? const Color(0xFFE65100) : const Color(0xFF6B7280),
                                            ),
                                          ),
                                          if (workplace.locationAddress != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 12,
                                                  color: const Color(0xFF9CA3AF),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    workplace.locationAddress!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: const Color(0xFF6B7280),
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
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: const Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _loadWorkplaceDetails();
                            Navigator.pop(dialogContext);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
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
        },
      ),
    );
  }

  Widget _buildWorkplaceAssignmentsList() {
    if (_loadingWorkplaces) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isEditing) ...[
          InkWell(
            onTap: _showWorkplaceSelector,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80), width: 1.5, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: const Color(0xFFBF360C), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedWorkplaceIds.isEmpty
                          ? 'Add Workplace Assignments'
                          : 'Manage Workplace Assignments (${_selectedWorkplaceIds.length})',
                      style: TextStyle(
                        color: const Color(0xFFBF360C),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: const Color(0xFFE65100)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_assignedWorkplaces.isEmpty && !_isEditing)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: const Color(0xFF6B7280), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No workplace assignments',
                    style: TextStyle(
                      color: const Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._assignedWorkplaces.map((workplace) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF3E0),
                    const Color(0x80FFF3E0),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1AE65100),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.business, color: const Color(0xFFBF360C), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workplace.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFBF360C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                workplace.code,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFBF360C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (workplace.locationAddress != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: const Color(0xFFE65100)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  workplace.locationAddress!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFFBF360C),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildSiteAssignmentsList() {
    final assignments = widget.admin['site_assignments'] as List<dynamic>? ?? [];
    
    if (assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: const Color(0xFF6B7280), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No site assignments',
                style: TextStyle(
                  color: const Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: assignments.map((assignment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE8F5EE),
                const Color(0x80E8F5EE),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB2DFCA), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A007A3D),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on, color: const Color(0xFF005C2E), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment['site_name'] as String? ?? 'Site ID: ${assignment['site_id']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003D1F),
                      ),
                    ),
                    if (assignment['site_code'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          assignment['site_code'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF005C2E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PendingRequestsTab extends StatefulWidget {
  final Site? selectedSite;
  
  const _PendingRequestsTab({this.selectedSite});

  @override
  State<_PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<_PendingRequestsTab> {
  int? _filterSiteId;

  @override
  void initState() {
    super.initState();
    _filterSiteId = widget.selectedSite?.id;
    _loadRequests();
  }

  @override
  void didUpdateWidget(_PendingRequestsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSite?.id != widget.selectedSite?.id) {
      setState(() {
        _filterSiteId = widget.selectedSite?.id;
      });
    }
  }

  void _loadRequests() {
    context.read<AdminBloc>().add(
      const FetchPendingRequestsEvent(),
    );
  }

  List<RegistrationRequestResponse> _filterRequests(List<RegistrationRequestResponse> requests) {
    if (_filterSiteId == null) {
      return requests;
    }
    return requests.where((request) {
      return request.siteIds?.contains(_filterSiteId) ?? false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is RegistrationApproved || state is RegistrationRejected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is RegistrationApproved
                    ? state.message
                    : (state as RegistrationRejected).message,
              ),
              backgroundColor: state is RegistrationApproved
                  ? const Color(0xFF007A3D)
                  : const Color(0xFFE65100),
            ),
          );
          _loadRequests();
        } else if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFB71C1C),
            ),
          );
        }
      },
      child: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PendingRequestsLoaded) {
            final filteredRequests = _filterRequests(state.requests);
            
            return Column(
              children: [
                if (_filterSiteId != null && widget.selectedSite != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1A007A3D),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0x4D007A3D),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 18,
                          color: const Color(0xFF007A3D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtered by: ${widget.selectedSite!.name}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF007A3D),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A3D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${filteredRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filteredRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox, size: 64, color: const Color(0xFF9CA3AF)),
                              const SizedBox(height: 16),
                              Text(
                                _filterSiteId != null 
                                    ? 'No pending requests for selected site'
                                    : 'No pending requests',
                                style: const TextStyle(fontSize: 16, color: const Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _loadRequests();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              final request = filteredRequests[index];
                              return _buildRequestCard(context, request);
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pull to refresh'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<AdminBloc>()
                        .add(const FetchPendingRequestsEvent());
                  },
                  child: const Text('Load Requests'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    RegistrationRequestResponse request,
  ) {
    final timeDiff = DateTime.now().difference(request.createdAt);
    final timeAgo = timeDiff.inDays > 0
        ? '${timeDiff.inDays} days ago'
        : timeDiff.inHours > 0
            ? '${timeDiff.inHours} hours ago'
            : '${timeDiff.inMinutes} minutes ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    request.fullName.isNotEmpty ? request.fullName[0].toUpperCase() : 'R',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${request.username}',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.role.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFFBF360C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (request.siteNames != null && request.siteNames!.isNotEmpty) ...[
              _buildInfoRow(
                Icons.location_on, 
                request.siteNames!.join(', '),
              ),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(Icons.email, request.email ?? 'Not provided'),
            if (request.phoneNumber != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, request.phoneNumber!),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'Requested $timeAgo'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(context, request.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB71C1C),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(context, request.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFF374151),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _approveRequest(BuildContext context, int requestId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Registration'),
        content: const Text(
          'Are you sure you want to approve this registration request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminBloc>().add(
                    ApproveRegistrationEvent(requestId: requestId),
                  );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(BuildContext context, int requestId) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Rejection Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminBloc>().add(
                    RejectRegistrationEvent(
                      requestId: requestId,
                      rejectionNotes: notesController.text.isEmpty
                          ? null
                          : notesController.text,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
