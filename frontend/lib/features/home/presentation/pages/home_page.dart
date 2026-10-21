import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/network/dio_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  Map<String, dynamic>? _userData;
  String? _resolvedAvatarUrl;
  bool _isLoadingUser = true;
  bool _isSuperAdmin = false;
  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Quick stat values
  int _totalWorkers = 0;
  int _presentToday = 0;
  int _activeSites = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController!, curve: Curves.easeOut));

    // 1. Immediately restore cached user & stats for seamless offline-first experience
    _loadCachedUserData();

    // 2. Fetch fresh user & stats from backend
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionManager.checkAndHandleResume().then((expired) {
        if (!expired && mounted) {
          _loadUserData(isSilent: true);
        }
      });
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      SessionManager.recordActivity(syncNow: true);
    }
  }

  Future<void> _loadCachedUserData() async {
    try {
      final localDs = getIt<AuthLocalDataSource>();
      final cachedUser = await localDs.getUserData();
      final prefs = getIt<SharedPreferences>();

      final cachedWorkers = prefs.getInt('cached_total_workers');
      final cachedPresent = prefs.getInt('cached_present_today');
      final cachedSites = prefs.getInt('cached_active_sites');

      if (mounted && cachedUser != null) {
        final role = (cachedUser['role'] ?? '').toString().toLowerCase();
        final rawPhoto = cachedUser['profile_photo']?.toString();
        String? resolved;
        if (rawPhoto != null && rawPhoto.isNotEmpty) {
          resolved = await DioClient.resolveMediaUrl(rawPhoto);
        }
        setState(() {
          _userData = cachedUser;
          _resolvedAvatarUrl = resolved;
          _isSuperAdmin = role == 'super_admin' || role == 'admin';
          _isLoadingUser = false;
          if (cachedWorkers != null) _totalWorkers = cachedWorkers;
          if (cachedPresent != null) _presentToday = cachedPresent;
          if (cachedSites != null) _activeSites = cachedSites;
          if (cachedWorkers != null || cachedSites != null) {
            _statsLoaded = true;
          }
        });
        _fadeController?.forward();
        _slideController?.forward();
      }
    } catch (_) {}
  }

  Future<void> _loadUserData({bool isSilent = false}) async {
    if (!isSilent && _userData == null) {
      setState(() => _isLoadingUser = true);
    }
    try {
      final dio = getIt<Dio>();
      final response = await dio.get('/users/me');
      if (mounted) {
        final data = response.data;
        if (data != null && (data is Map<String, dynamic> || data is Map)) {
          final userMap = Map<String, dynamic>.from(data as Map);
          final role = (userMap['role'] ?? '').toString().toLowerCase();
          final rawPhoto = userMap['profile_photo']?.toString();
          String? resolved;
          if (rawPhoto != null && rawPhoto.isNotEmpty) {
            resolved = await DioClient.resolveMediaUrl(rawPhoto);
          }

          setState(() {
            _userData = userMap;
            _resolvedAvatarUrl = resolved;
            _isSuperAdmin = role == 'super_admin' || role == 'admin';
            _isLoadingUser = false;
          });

          // Persist user data to local storage so future cold starts/resumes retain it
          try {
            final localDs = getIt<AuthLocalDataSource>();
            await localDs.saveUserData(userMap);

            // Auto-configure and lock primary site for Site Managers / Site Admins
            if (role == 'site_admin' && userMap['site_assignments'] is List && (userMap['site_assignments'] as List).isNotEmpty) {
              final assignments = userMap['site_assignments'] as List;
              final primaryAssignment = assignments.firstWhere(
                (a) => a is Map && a['is_primary'] == true,
                orElse: () => assignments.first,
              );
              if (primaryAssignment is Map && primaryAssignment['site_id'] != null) {
                final siteId = primaryAssignment['site_id'] as int;
                await StorageService().setSelectedSiteId(siteId);
              }
            }
          } catch (_) {}

          _fadeController?.forward();
          _slideController?.forward();
          _loadQuickStats(dio);
        }
      }
    } catch (e) {
      if (mounted) {
        // If we didn't have user data yet, fall back to local storage
        if (_userData == null) {
          await _loadCachedUserData();
        }
        setState(() => _isLoadingUser = false);
        _fadeController?.forward();
        _slideController?.forward();

        // If the server explicitly returned 401 Unauthorized, token has expired
        if (e is DioException && e.response?.statusCode == 401 && mounted) {
          context.read<AuthBloc>().add(LogoutRequested());
        }
      }
    }
  }

  Future<void> _loadQuickStats(Dio dio) async {
    try {
      final results = await Future.wait([
        dio.get('/workers', queryParameters: {'status': 'active', 'limit': 1}).catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'total': 0})),
        dio.get('/attendance', queryParameters: {
          'date_from': DateTime.now().toIso8601String().split('T')[0],
          'date_to': DateTime.now().toIso8601String().split('T')[0],
        }).catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: [])),
        dio.get('/sites', queryParameters: {'is_active': true}).catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: [])),
      ]);

      if (!mounted) return;

      final workersData = results[0].data;
      final attendanceData = results[1].data;
      final sitesData = results[2].data;

      int newWorkers = _totalWorkers;
      int newPresent = _presentToday;
      int newSites = _activeSites;

      if (workersData is Map) {
        newWorkers = (workersData['total'] ?? workersData['count'] ?? 0) as int;
      } else if (workersData is List) {
        newWorkers = workersData.length;
      }
      if (attendanceData is List) {
        newPresent = attendanceData
            .where((a) => (a['status'] ?? '') == 'present')
            .length;
      }
      if (sitesData is List) {
        newSites = sitesData.length;
      } else if (sitesData is Map) {
        final list = sitesData['data'] ?? sitesData['sites'] ?? [];
        if (list is List) {
          newSites = list.length;
        } else {
          newSites = (sitesData['total'] ?? sitesData['count'] ?? 0) as int;
        }
      }

      setState(() {
        _totalWorkers = newWorkers;
        _presentToday = newPresent;
        _activeSites = newSites;
        _statsLoaded = true;
      });

      // Persist quick stats to SharedPreferences
      try {
        final prefs = getIt<SharedPreferences>();
        await prefs.setInt('cached_total_workers', newWorkers);
        await prefs.setInt('cached_present_today', newPresent);
        await prefs.setInt('cached_active_sites', newSites);
      } catch (_) {}
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'U';
    final names = fullName.trim().split(RegExp(r'\s+'));
    if (names.length == 1) return names[0].isNotEmpty ? names[0][0].toUpperCase() : 'U';
    return '${names.first[0]}${names.last[0]}'.toUpperCase();
  }

  String _getRoleLabel(String? role) {
    switch (role?.toString().toLowerCase()) {
      case 'super_admin': return 'Super Administrator';
      case 'admin': return 'Administrator';
      case 'site_admin': return 'Site Administrator';
      case 'supervisor': return 'Supervisor';
      case 'hr_officer': return 'HR Officer';
      case 'viewer': return 'Viewer';
      default: return 'User';
    }
  }

  bool get _isAdminOrSuperAdmin {
    final role = (_userData?['role'] ?? '').toString().toLowerCase();
    return _isSuperAdmin || role == 'super_admin' || role == 'admin';
  }

  bool get _isAnyAdmin {
    final role = (_userData?['role'] ?? '').toString().toLowerCase();
    return _isSuperAdmin || role == 'super_admin' || role == 'admin' || role == 'site_admin';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showUserMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      color: Colors.white,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 280),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF005C2E), Color(0xFF007A3D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x4D005C2E),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(_userData?['full_name']),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData?['full_name'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _userData?['email'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF007A3D)),
                          ),
                          child: Text(
                            _getRoleLabel(_userData?['role']),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF007A3D), letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE5E7EB)),
            ],
          ),
        ),
        _menuItem('profile', Icons.person_outline, 'My Profile', const Color(0xFF0A192F), const Color(0xFFE8EDF4)),
        _menuItem('settings', Icons.settings_outlined, 'Settings', const Color(0xFF007A3D), const Color(0xFFE8F5EE)),
        const PopupMenuItem<String>(
          enabled: false,
          height: 8,
          child: Divider(color: Color(0xFFE5E7EB), height: 1),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFB71C1C)),
              ),
              const SizedBox(width: 12),
              const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFB71C1C))),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == null || !mounted) return;
      switch (value) {
        case 'profile':
          await Navigator.pushNamed(context, AppRouter.profile);
          if (mounted) _loadUserData();
          break;
        case 'settings':
          await Navigator.pushNamed(context, AppRouter.settings);
          if (mounted) _loadUserData();
          break;
        case 'logout':
          _handleLogout();
          break;
      }
    });
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color iconColor, Color bgColor) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMenuItems() {
    final all = [
      {
        'icon': Icons.people_alt_rounded,
        'title': 'Workers',
        'subtitle': 'Manage workforce',
        'gradient': [const Color(0xFF005C2E), const Color(0xFF007A3D)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.workers),
        'adminOnly': false,
      },
      {
        'icon': Icons.fact_check_rounded,
        'title': 'Attendance',
        'subtitle': 'Mark & verify',
        'gradient': [const Color(0xFF004D40), const Color(0xFF00796B)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.attendance),
        'adminOnly': false,
      },
      {
        'icon': Icons.payments_rounded,
        'title': 'Payroll',
        'subtitle': 'Process payments',
        'gradient': [const Color(0xFF0A192F), const Color(0xFF1E3A5F)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.payroll),
        'adminOnly': true,
      },
      {
        'icon': Icons.location_city_rounded,
        'title': 'Sites',
        'subtitle': 'Manage locations',
        'gradient': [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.sites),
        'adminOnly': true,
      },
      {
        'icon': Icons.work_history_rounded,
        'title': 'Work Types',
        'subtitle': 'Define roles',
        'gradient': [const Color(0xFF003049), const Color(0xFF005F73)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.workTypes),
        'adminOnly': true,
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Reports',
        'subtitle': 'Analytics & insights',
        'gradient': [const Color(0xFF1A237E), const Color(0xFF283593)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.reports),
        'adminOnly': true,
      },
      {
        'icon': Icons.admin_panel_settings_rounded,
        'title': 'Admins',
        'subtitle': 'Manage administrators',
        'gradient': [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.adminRegistration),
        'adminOnly': true,
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'subtitle': 'Configure app',
        'gradient': [const Color(0xFF2D3436), const Color(0xFF4A5568)],
        'onTap': () => Navigator.pushNamed(context, AppRouter.settings),
        'adminOnly': false,
      },
    ];
    final role = (_userData?['role'] ?? '').toString().toLowerCase();
    // Super Admin, Admin, and Site Manager (site_admin) get ALL 8 modules with full functionality!
    if (_isAdminOrSuperAdmin || role == 'super_admin' || role == 'admin' || role == 'site_admin') {
      return all;
    }
    return all.where((i) => i['adminOnly'] == false).toList();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, size: 28, color: Color(0xFFB71C1C)),
              ),
              const SizedBox(height: 18),
              const Text('Sign Out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 10),
              const Text('Are you sure you want to sign out?', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthBloc>().add(LogoutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F0),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF007A3D),
            onRefresh: () async {
              await _loadUserData();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                    child: SlideTransition(
                      position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
                      child: Column(
                        children: [
                          if (_isAnyAdmin) _buildQuickStats(),
                          _buildSectionTitle('Quick Access'),
                          _buildModuleGrid(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003D1F), Color(0xFF005C2E), Color(0xFF007A3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 160, height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0FFFFFFF),
                ),
              ),
            ),
            Positioned(
              right: 40, top: 20,
              child: Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0DFFFFFF),
                ),
              ),
            ),
            Positioned(
              left: -30, bottom: -20,
              child: Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0AFFFFFF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Text(
                                'EthioWorkforce',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingUser)
                        const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      else
                        Builder(
                          builder: (ctx) => GestureDetector(
                            onTap: () => _showUserMenu(ctx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0x40FFFFFF)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34, height: 34,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _resolvedAvatarUrl != null && _resolvedAvatarUrl!.isNotEmpty
                                          ? Image.network(
                                              _resolvedAvatarUrl!,
                                              width: 34,
                                              height: 34,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  _getInitials(_userData?['full_name']),
                                                  style: const TextStyle(color: Color(0xFF007A3D), fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                _getInitials(_userData?['full_name']),
                                                style: const TextStyle(color: Color(0xFF007A3D), fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xCCFFFFFF), size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Greeting
                  Text(
                    '${_getGreeting()},',
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData?['full_name']?.toString().split(' ').first ?? 'Welcome',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          _getRoleLabel(_userData?['role']),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                        ),
                      ],
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

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _buildStatCard(
            'Total Workers',
            _statsLoaded ? '$_totalWorkers' : '—',
            Icons.groups_rounded,
            const Color(0xFF007A3D),
            const Color(0xFFE8F5EE),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Present Today',
            _statsLoaded ? '$_presentToday' : '—',
            Icons.how_to_reg_rounded,
            const Color(0xFF004D40),
            const Color(0xFFE0F2F1),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Active Sites',
            _statsLoaded ? '$_activeSites' : '—',
            Icons.location_city_rounded,
            const Color(0xFF0A192F),
            const Color(0xFFE8EDF4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF007A3D), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: -0.2)),
        ],
      ),
    );
  }

  Widget _buildModuleGrid() {
    final items = _getMenuItems();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildModuleCard(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            subtitle: item['subtitle'] as String,
            gradient: item['gradient'] as List<Color>,
            onTap: item['onTap'] as VoidCallback,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(89, gradient[0].red, gradient[0].green, gradient[0].blue),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative background circle
                Positioned(
                  right: -16, bottom: -16,
                  child: Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1AFFFFFF),
                    ),
                  ),
                ),
                Positioned(
                  right: 10, top: -20,
                  child: Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x12FFFFFF),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 11, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
