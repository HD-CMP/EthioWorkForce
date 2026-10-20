import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/file_saver.dart';
import '../../data/datasources/reports_remote_datasource.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportsRemoteDataSource _reportsDs = getIt<ReportsRemoteDataSource>();
  final Dio _dio = getIt<Dio>();

  // Global Filter State
  List<dynamic> _sites = [];
  int? _selectedSiteId;
  bool _isLoadingInitial = true;
  String? _errorMessage;

  // Tab 0: Executive Dashboard State
  Map<String, dynamic>? _dashboardData;
  bool _isLoadingDashboard = false;

  // Tab 1: Banking & Payment Batches State
  List<dynamic> _payrolls = [];
  int? _selectedPayrollId;
  Map<String, dynamic>? _selectedPayrollDetails;
  List<dynamic> _payrollItems = [];
  bool _isLoadingPayroll = false;
  String _bankingSearchQuery = '';

  // Tab 2: Tax & Statutory Compliance State
  final TextEditingController _orgNameController = TextEditingController(text: 'EthioWorkforce Enterprise');
  final TextEditingController _tinController = TextEditingController(text: '0012345678');
  Map<String, dynamic>? _taxComplianceData;
  bool _isLoadingTax = false;
  String _taxSearchQuery = '';

  // Tab 3: Attendance & Overtime Ledger State
  DateTime _attendanceDateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _attendanceDateTo = DateTime.now();
  Map<String, dynamic>? _attendanceRosterData;
  bool _isLoadingAttendanceRoster = false;
  String _attendanceSearchQuery = '';

  // Tab 4: Workforce Census State
  List<dynamic> _censusWorkers = [];
  bool _isLoadingCensus = false;
  String _censusStatusFilter = 'all';
  String _censusSearchQuery = '';
  List<dynamic> _workTypes = [];
  int? _censusWorkTypeId;

  // Downloading State
  bool _isDownloading = false;
  String? _downloadingFileName;

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orgNameController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final index = _tabController.index;
      if (index == 0 && _dashboardData == null) _loadDashboardData();
      if (index == 1 && _selectedPayrollDetails == null && _selectedPayrollId != null) _loadPayrollBatchData(_selectedPayrollId!);
      if (index == 2 && _taxComplianceData == null && _selectedPayrollId != null) _loadTaxComplianceData(_selectedPayrollId!);
      if (index == 3 && _attendanceRosterData == null && _selectedSiteId != null) _loadAttendanceRoster();
      if (index == 4 && _censusWorkers.isEmpty) _loadCensusData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    try {
      final sitesResp = await _dio.get('/sites').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: []));
      final payrollsList = await _reportsDs.getPayrolls();
      final wtResp = await _dio.get('/work-types').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: []));

      if (!mounted) return;

      final sitesData = sitesResp.data;
      _sites = sitesData is List ? sitesData : [];
      if (_sites.isNotEmpty && _selectedSiteId == null) {
        _selectedSiteId = _sites.first['id'] as int?;
      }

      _payrolls = payrollsList;
      if (_payrolls.isNotEmpty) {
        _selectedPayrollId = _payrolls.first['id'] as int?;
      }

      final wtData = wtResp.data;
      _workTypes = wtData is List ? wtData : [];

      setState(() => _isLoadingInitial = false);

      // Load initial dashboard & payroll data
      _loadDashboardData();
      if (_selectedPayrollId != null) {
        _loadPayrollBatchData(_selectedPayrollId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
        _errorMessage = 'Failed to load initial data: $e';
      });
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final data = await _reportsDs.getDashboardKpi(siteId: _selectedSiteId);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDashboard = false);
    }
  }

  Future<void> _loadPayrollBatchData(int payrollId) async {
    setState(() => _isLoadingPayroll = true);
    try {
      final results = await Future.wait([
        _dio.get('/payroll/$payrollId'),
        _dio.get('/payroll/$payrollId/items'),
      ]);
      if (mounted) {
        setState(() {
          _selectedPayrollDetails = results[0].data as Map<String, dynamic>;
          _payrollItems = (results[1].data as List<dynamic>?) ?? [];
          _isLoadingPayroll = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPayroll = false);
    }
  }

  Future<void> _loadTaxComplianceData(int payrollId) async {
    setState(() => _isLoadingTax = true);
    try {
      final data = await _reportsDs.getTaxComplianceReport(payrollId);
      if (mounted) {
        setState(() {
          _taxComplianceData = data;
          _isLoadingTax = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTax = false);
    }
  }

  Future<void> _loadAttendanceRoster() async {
    if (_selectedSiteId == null) return;
    setState(() => _isLoadingAttendanceRoster = true);
    try {
      final fromStr = DateFormat('yyyy-MM-dd').format(_attendanceDateFrom);
      final toStr = DateFormat('yyyy-MM-dd').format(_attendanceDateTo);
      final data = await _reportsDs.getAttendanceRoster(
        siteId: _selectedSiteId!,
        dateFrom: fromStr,
        dateTo: toStr,
      );
      if (mounted) {
        setState(() {
          _attendanceRosterData = data;
          _isLoadingAttendanceRoster = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAttendanceRoster = false);
    }
  }

  Future<void> _loadCensusData() async {
    setState(() => _isLoadingCensus = true);
    try {
      final data = await _reportsDs.getWorkerCensus(
        siteId: _selectedSiteId,
        workTypeId: _censusWorkTypeId,
        status: _censusStatusFilter,
      );
      if (mounted) {
        setState(() {
          _censusWorkers = data;
          _isLoadingCensus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCensus = false);
    }
  }

  Future<void> _downloadFile({
    required String urlPath,
    required String filename,
    Map<String, dynamic>? queryParams,
  }) async {
    setState(() {
      _isDownloading = true;
      _downloadingFileName = filename;
    });

    try {
      final bytes = await _reportsDs.downloadReportBytes(urlPath, queryParams: queryParams);
      final message = await FileSaver.saveAndOpenFile(bytes, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('$message ($filename)')),
              ],
            ),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
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
              Expanded(child: Text('Download failed: $e')),
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
          _isDownloading = false;
          _downloadingFileName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExecutiveOverviewTab(),
                        _buildBankingDisbursementTab(),
                        _buildTaxComplianceTab(),
                        _buildAttendanceOvertimeTab(),
                        _buildWorkforceCensusTab(),
                      ],
                    ),
                    if (_isDownloading) _buildDownloadOverlay(),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF007A3D),
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      actions: [
        // Site filter pill — compact, never crushes title
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints(maxWidth: 160),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedSiteId,
              dropdownColor: const Color(0xFF005C2E),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              hint: const Text('All Sites', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
              isExpanded: true,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Sites', style: TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
                ..._sites.map((s) => DropdownMenuItem<int?>(
                      value: s['id'] as int,
                      child: Text(
                        s['name'] ?? 'Site #${s['id']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (newSiteId) {
                setState(() => _selectedSiteId = newSiteId);
                _loadDashboardData();
                if (_tabController.index == 3) _loadAttendanceRoster();
                if (_tabController.index == 4) _loadCensusData();
              },
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Reports',
          onPressed: () {
            _loadDashboardData();
            if (_selectedPayrollId != null) {
              _loadPayrollBatchData(_selectedPayrollId!);
              _loadTaxComplianceData(_selectedPayrollId!);
            }
            if (_tabController.index == 3) _loadAttendanceRoster();
            if (_tabController.index == 4) _loadCensusData();
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFFFFD54F),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFFFFD54F),
        unselectedLabelColor: const Color(0xB3FFFFFF),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.2),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Overview', height: 52),
          Tab(icon: Icon(Icons.account_balance_rounded, size: 20), text: 'Banking', height: 52),
          Tab(icon: Icon(Icons.verified_user_rounded, size: 20), text: 'Tax', height: 52),
          Tab(icon: Icon(Icons.fact_check_rounded, size: 20), text: 'Attendance', height: 52),
          Tab(icon: Icon(Icons.badge_rounded, size: 20), text: 'Census', height: 52),
        ],
      ),
    );
  }

  Widget _buildDownloadOverlay() {
    return Container(
      color: const Color(0xFF737373),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1B5E20)),
              const SizedBox(height: 20),
              const Text(
                'Generating Official Report...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _downloadingFileName ?? 'Preparing file download',
                style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: const Color(0xFFB71C1C), size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred loading reports',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 0: EXECUTIVE DASHBOARD & KPI ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExecutiveOverviewTab() {
    if (_isLoadingDashboard && _dashboardData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _dashboardData;
    if (data == null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _loadDashboardData,
          icon: const Icon(Icons.refresh),
          label: const Text('Load Analytics'),
        ),
      );
    }

    final workforce = data['workforce'] as Map<String, dynamic>? ?? {};
    final att = data['attendance_analytics'] as Map<String, dynamic>? ?? {};
    final ot = data['overtime_analytics'] as Map<String, dynamic>? ?? {};
    final payroll = data['payroll_analytics'] as Map<String, dynamic>? ?? {};
    final sitesDist = (data['sites_distribution'] as List<dynamic>?) ?? [];
    final wtDist = (data['work_types_distribution'] as List<dynamic>?) ?? [];
    final recentPayrolls = (payroll['recent_payrolls'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 4 Top Executive KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard(
                      title: 'Active Workforce',
                      value: '${workforce['active_workers'] ?? 0}',
                      subtitle: 'of ${workforce['total_workers'] ?? 0} total registered',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF1976D2),
                      badge: '${workforce['retention_rate'] ?? 0}% active',
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard(
                      title: 'Presenteeism Rate',
                      value: '${att['presenteeism_rate'] ?? 0}%',
                      subtitle: '${att['present_count'] ?? 0} present in 30 days',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF2E7D32),
                      badge: '${att['total_records'] ?? 0} records',
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard(
                      title: 'Overtime Hours',
                      value: '${ot['total_hours'] ?? 0} hrs',
                      subtitle: '${ot['verified_hours'] ?? 0} hrs verified',
                      icon: Icons.more_time_rounded,
                      color: const Color(0xFFE65100),
                      badge: '${ot['total_entries'] ?? 0} entries',
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: _buildMetricCard(
                      title: 'Gross Payroll Disbursed',
                      value: 'ETB ${_currencyFormat.format(payroll['total_gross_disbursed'] ?? 0)}',
                      subtitle: 'Net: ETB ${_currencyFormat.format(payroll['total_net_disbursed'] ?? 0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF4A148C),
                      badge: '${payroll['total_payrolls'] ?? 0} runs',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Attendance Distribution Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_rounded, color: Color(0xFF007A3D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '30-Day Attendance Composition',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Total: ${att['total_records'] ?? 0} logs',
                              style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAttendanceDistributionBar(att),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sites & Work Types Distributions Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sites Distribution
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Color(0xFF1565C0)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Workforce by Site',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (sitesDist.isEmpty)
                              const Text('No site data available', style: TextStyle(color: const Color(0xFF9CA3AF)))
                            else
                              ...sitesDist.map((s) => _buildDistributionItem(
                                    label: s['site_name'] ?? 'Site',
                                    count: s['worker_count'] ?? 0,
                                    total: workforce['active_workers'] ?? 1,
                                    color: const Color(0xFF1976D2),
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                  // Work Types Distribution
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.work_rounded, color: Color(0xFF00695C)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Workforce by Role & Type',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (wtDist.isEmpty)
                              const Text('No work types defined', style: TextStyle(color: const Color(0xFF9CA3AF)))
                            else
                              ...wtDist.map((wt) => _buildDistributionItem(
                                    label: '${wt['name']} (${(wt['payment_mode'] ?? '').replaceAll('_', ' ')})',
                                    count: wt['worker_count'] ?? 0,
                                    total: workforce['active_workers'] ?? 1,
                                    color: const Color(0xFF00695C),
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Recent Payrolls Summary
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_edu_rounded, color: Color(0xFF4A148C)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recent Payroll Runs & Statutory Remittance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recentPayrolls.isEmpty)
                    const Text('No recent payroll records found', style: TextStyle(color: const Color(0xFF9CA3AF)))
                  else
                    ...recentPayrolls.map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4A148C).withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF4A148C)),
                          ),
                          title: Text(
                            p['payroll_code'] ?? 'Payroll #${p['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Period: ${p['period_start']} to ${p['period_end']} | ${p['employee_count']} Workers',
                            style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Net: ETB ${_currencyFormat.format(p['total_net_amount'] ?? 0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                              ),
                              Text(
                                'Gross: ETB ${_currencyFormat.format(p['total_gross_amount'] ?? 0)}',
                                style: TextStyle(fontSize: 11, color: const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() => _selectedPayrollId = p['id'] as int?);
                            _tabController.animateTo(1);
                          },
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  radius: 20,
                  child: Icon(icon, color: color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceDistributionBar(Map<String, dynamic> att) {
    final present = (att['present_count'] as num?)?.toInt() ?? 0;
    final late = (att['late_count'] as num?)?.toInt() ?? 0;
    final half = (att['half_day_count'] as num?)?.toInt() ?? 0;
    final leave = (att['leave_count'] as num?)?.toInt() ?? 0;
    final absent = (att['absent_count'] as num?)?.toInt() ?? 0;
    final total = (att['total_records'] as num?)?.toInt() ?? 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                if (present > 0)
                  Expanded(flex: present, child: Container(color: const Color(0xFF2E7D32))),
                if (late > 0)
                  Expanded(flex: late, child: Container(color: const Color(0xFFFBC02D))),
                if (half > 0)
                  Expanded(flex: half, child: Container(color: const Color(0xFF0288D1))),
                if (leave > 0)
                  Expanded(flex: leave, child: Container(color: const Color(0xFF7B1FA2))),
                if (absent > 0)
                  Expanded(flex: absent, child: Container(color: const Color(0xFFD32F2F))),
                if (total == 0)
                  Expanded(child: Container(color: const Color(0xFFD1D5DB))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendPill('Present', present, const Color(0xFF2E7D32)),
            _buildLegendPill('Late', late, const Color(0xFFFBC02D)),
            _buildLegendPill('Half Day', half, const Color(0xFF0288D1)),
            _buildLegendPill('Paid Leave', leave, const Color(0xFF7B1FA2)),
            _buildLegendPill('Absent', absent, const Color(0xFFD32F2F)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendPill(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('$count', style: TextStyle(fontSize: 12, color: const Color(0xFF374151))),
      ],
    );
  }

  Widget _buildDistributionItem({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count workers (${(pct * 100).toStringAsFixed(1)}%)',
                style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: BANKING & PAYMENT BATCHES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBankingDisbursementTab() {
    if (_payrolls.isEmpty) {
      return const Center(
        child: Text('No calculated payrolls found to generate bank batches for.'),
      );
    }

    final filteredItems = _payrollItems.where((item) {
      if (_bankingSearchQuery.isEmpty) return true;
      final q = _bankingSearchQuery.toLowerCase();
      final name = (item['worker_name'] ?? item['worker']?['full_name'] ?? '').toString().toLowerCase();
      final empId = (item['employee_id'] ?? item['worker']?['employee_id'] ?? '').toString().toLowerCase();
      final acct = (item['bank_account_number'] ?? item['worker']?['bank_account_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || empId.contains(q) || acct.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Payroll Run Selector Banner
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Color(0xFF007A3D)),
                const SizedBox(width: 12),
                const Text('Select Payroll Run:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedPayrollId,
                      items: _payrolls.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text(
                            '${p['payroll_code']} | ${p['period_start']} to ${p['period_end']} (Net: ETB ${_currencyFormat.format(p['total_net_amount'] ?? 0)})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() => _selectedPayrollId = id);
                          _loadPayrollBatchData(id);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // One-Click Export Action Cards
        const Text(
          'Instant Bank & Payment Disbursement Batches',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildExportActionCard(
              title: 'CBE Bank Transfer',
              subtitle: 'Commercial Bank of Ethiopia direct deposit sheet',
              fileFormat: 'EXCEL (.xlsx)',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF6A1B9A),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/payroll/$_selectedPayrollId/export/cbe',
                  filename: 'CBE_Payroll_Transfer_PAY-$_selectedPayrollId.xlsx',
                );
              },
            ),
            _buildExportActionCard(
              title: 'Telebirr Mobile Payout',
              subtitle: 'Ethio Telecom Telebirr bulk salary disbursement CSV',
              fileFormat: 'CSV (.csv)',
              icon: Icons.phone_android_rounded,
              color: const Color(0xFFE65100),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/payroll/$_selectedPayrollId/export/telebirr',
                  filename: 'Telebirr_Bulk_Payout_PAY-$_selectedPayrollId.csv',
                );
              },
            ),
            _buildExportActionCard(
              title: 'Dashen Bank Transfer',
              subtitle: 'Dashen corporate salary disbursement template',
              fileFormat: 'EXCEL (.xlsx)',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF0D47A1),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/payroll/$_selectedPayrollId/export/dashen',
                  filename: 'Dashen_Salary_Transfer_PAY-$_selectedPayrollId.xlsx',
                );
              },
            ),
            _buildExportActionCard(
              title: 'Awash Bank Transfer',
              subtitle: 'Awash Bank payroll direct deposit register',
              fileFormat: 'EXCEL (.xlsx)',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFFC55A11),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/payroll/$_selectedPayrollId/export/awash',
                  filename: 'Awash_Payroll_PAY-$_selectedPayrollId.xlsx',
                );
              },
            ),
            _buildExportActionCard(
              title: 'Cash Payment Roll Sheet',
              subtitle: 'Field distribution sheet with acknowledgment signature lines',
              fileFormat: 'EXCEL (.xlsx)',
              icon: Icons.payments_rounded,
              color: const Color(0xFF2E7D32),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/payroll/$_selectedPayrollId/export/cash-sheet',
                  filename: 'Cash_Payment_Sheet_PAY-$_selectedPayrollId.xlsx',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Search & In-App Table Preview
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disbursement Roster Preview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search employee or account number...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF007A3D)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007A3D), width: 2),
                ),
              ),
              onChanged: (v) => setState(() => _bankingSearchQuery = v),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoadingPayroll)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (filteredItems.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No employees found in this payroll run matching filter')),
            ),
          )
        else
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                columns: const [
                  DataColumn(label: Text('S/N', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Employee ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Net Pay (ETB)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Bank / Account', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Days Worked', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredItems.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final name = item['worker_name'] ?? item['worker']?['full_name'] ?? 'Worker';
                  final empId = item['employee_id'] ?? item['worker']?['employee_id'] ?? '-';
                  final net = floatOrZero(item['net_salary']);
                  final acct = item['bank_account_number'] ?? item['worker']?['bank_account_number'] ?? '-';
                  final phone = item['phone_number'] ?? item['worker']?['phone_number'] ?? '-';
                  final days = item['days_worked'] ?? 0;

                  return DataRow(cells: [
                    DataCell(Text('$idx')),
                    DataCell(Text('$empId', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('$name')),
                    DataCell(Text('ETB ${_currencyFormat.format(net)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                    DataCell(Text('$acct')),
                    DataCell(Text('$phone')),
                    DataCell(Text('$days')),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: TAX & STATUTORY COMPLIANCE (ERCA & POESSA PENSION)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTaxComplianceTab() {
    if (_payrolls.isEmpty) {
      return const Center(child: Text('No calculated payrolls found to evaluate tax compliance.'));
    }

    if (_taxComplianceData == null && !_isLoadingTax && _selectedPayrollId != null) {
      _loadTaxComplianceData(_selectedPayrollId!);
    }

    final summary = _taxComplianceData?['summary'] as Map<String, dynamic>? ?? {};
    final items = (_taxComplianceData?['items'] as List<dynamic>?) ?? [];

    final filteredTaxItems = items.where((item) {
      if (_taxSearchQuery.isEmpty) return true;
      final q = _taxSearchQuery.toLowerCase();
      final name = (item['worker_name'] ?? '').toString().toLowerCase();
      final id = (item['employee_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Payroll Run Selector & Org Info
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF007A3D)),
                    const SizedBox(width: 12),
                    const Text('Tax Declaration Payroll:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedPayrollId,
                          items: _payrolls.map((p) {
                            return DropdownMenuItem<int>(
                              value: p['id'] as int,
                              child: Text(
                                '${p['payroll_code']} (${p['period_start']} to ${p['period_end']})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              setState(() => _selectedPayrollId = id);
                              _loadTaxComplianceData(id);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _orgNameController,
                        decoration: const InputDecoration(
                          labelText: 'Organization / Company Name',
                          hintText: 'e.g. Ethio Construction PLC',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _tinController,
                        decoration: const InputDecoration(
                          labelText: 'Tax Identification Number (TIN)',
                          hintText: 'e.g. 0012345678',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Summary Remittance KPI Metrics Banner
        Card(
          elevation: 2,
          color: const Color(0xFF1E4620),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFFFFD54F), size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Statutory Remittance Summary',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        'ETB ${_currencyFormat.format(summary['total_statutory_remittance'] ?? 0)}',
                        style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('ERCA & POESSA', style: TextStyle(color: const Color(0x99FFFFFF), fontSize: 12)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatutoryMetricItem('Gross Pay', summary['total_gross_salary']),
                    _buildStatutoryMetricItem('Emp. Pension (7%)', summary['total_employee_pension']),
                    _buildStatutoryMetricItem('Taxable Base', summary['total_taxable_income']),
                    _buildStatutoryMetricItem('Income Tax', summary['total_income_tax']),
                    _buildStatutoryMetricItem('Empr. Pension (11%)', summary['total_employer_pension']),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Compliance Download Action Cards
        const Text(
          'Official Statutory Filings & Declarations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildExportActionCard(
              title: 'POESSA Pension Declaration',
              subtitle: 'Ethiopian Social Security Authority contribution schedule',
              fileFormat: 'EXCEL (.xlsx)',
              icon: Icons.description_rounded,
              color: const Color(0xFF0070C0),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/payroll/$_selectedPayrollId/pension-declaration/excel',
                  filename: 'Pension_Declaration_PAY-$_selectedPayrollId.xlsx',
                  queryParams: {
                    'organization_name': _orgNameController.text.trim(),
                    'tin_number': _tinController.text.trim(),
                  },
                );
              },
            ),
            _buildExportActionCard(
              title: 'POESSA Pension Declaration PDF',
              subtitle: 'Official signed & sealed format ready for tax submission',
              fileFormat: 'PDF DOCUMENT',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFC62828),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/payroll/$_selectedPayrollId/pension-declaration/pdf',
                  filename: 'Pension_Declaration_PAY-$_selectedPayrollId.pdf',
                  queryParams: {
                    'organization_name': _orgNameController.text.trim(),
                    'tin_number': _tinController.text.trim(),
                  },
                );
              },
            ),
            _buildExportActionCard(
              title: 'ERCA Income Tax Schedule',
              subtitle: 'Ministry of Revenues Employment Income Tax bracket schedule',
              fileFormat: 'EXCEL (.xlsx)',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF2E7D32),
              onTap: () {
                if (_selectedPayrollId == null) return;
                _downloadFile(
                  urlPath: '/reports/tax-compliance/$_selectedPayrollId/excel',
                  filename: 'ERCA_Tax_Schedule_PAY-$_selectedPayrollId.xlsx',
                  queryParams: {
                    'organization_name': _orgNameController.text.trim(),
                    'tin_number': _tinController.text.trim(),
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Compliance Table Header & Search
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed ERCA Tax & Pension Schedule',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search employee name or ID...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF007A3D)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007A3D), width: 2),
                ),
              ),
              onChanged: (v) => setState(() => _taxSearchQuery = v),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoadingTax)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (filteredTaxItems.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No employees found in this tax period')),
            ),
          )
        else
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                columns: const [
                  DataColumn(label: Text('S/N', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Worker Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Gross Pay (ETB)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Pension (7%)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Taxable Income', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Tax Bracket', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Income Tax', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Employer Pen (11%)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total Remittance', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredTaxItems.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return DataRow(cells: [
                    DataCell(Text('$idx')),
                    DataCell(Text('${item['employee_id']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${item['worker_name']}')),
                    DataCell(Text('ETB ${_currencyFormat.format(item['gross_salary'] ?? 0)}')),
                    DataCell(Text('ETB ${_currencyFormat.format(item['employee_pension'] ?? 0)}')),
                    DataCell(Text('ETB ${_currencyFormat.format(item['taxable_income'] ?? 0)}')),
                    DataCell(Text('${item['tax_rule_applied'] ?? 'standard'}')),
                    DataCell(Text('ETB ${_currencyFormat.format(item['income_tax'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF0A192F)))),
                    DataCell(Text('ETB ${_currencyFormat.format(item['employer_pension'] ?? 0)}')),
                    DataCell(Text('ETB ${_currencyFormat.format(item['total_remittance'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatutoryMetricItem(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: const Color(0xB3FFFFFF), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          'ETB ${_currencyFormat.format(floatOrZero(value))}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: ATTENDANCE & OVERTIME AUDIT LEDGER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAttendanceOvertimeTab() {
    if (_selectedSiteId == null) {
      return const Center(child: Text('Please select a site from the top bar to inspect attendance rosters.'));
    }

    if (_attendanceRosterData == null && !_isLoadingAttendanceRoster) {
      _loadAttendanceRoster();
    }

    final roster = (_attendanceRosterData?['roster'] as List<dynamic>?) ?? [];
    final filteredRoster = roster.where((r) {
      if (_attendanceSearchQuery.isEmpty) return true;
      final q = _attendanceSearchQuery.toLowerCase();
      final name = (r['worker_name'] ?? '').toString().toLowerCase();
      final id = (r['employee_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Date range card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, color: Color(0xFF007A3D)),
                    const SizedBox(width: 10),
                    const Text('Period Date Range:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${DateFormat('MMM dd, yyyy').format(_attendanceDateFrom)} – ${DateFormat('MMM dd, yyyy').format(_attendanceDateTo)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: DateTimeRange(start: _attendanceDateFrom, end: _attendanceDateTo),
                          );
                          if (picked != null) {
                            setState(() {
                              _attendanceDateFrom = picked.start;
                              _attendanceDateTo = picked.end;
                            });
                            _loadAttendanceRoster();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A3D)),
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      label: const Text('Export', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        final fromStr = DateFormat('yyyy-MM-dd').format(_attendanceDateFrom);
                        final toStr = DateFormat('yyyy-MM-dd').format(_attendanceDateTo);
                        _downloadFile(
                          urlPath: '/reports/attendance-roster/excel',
                          filename: 'Attendance_Roster_${_selectedSiteId}_$fromStr.xlsx',
                          queryParams: {
                            'site_id': _selectedSiteId,
                            'date_from': fromStr,
                            'date_to': toStr,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section title + full-width search bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker Attendance & Overtime Breakdown (${roster.length} workers)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search worker name or ID...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF007A3D)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007A3D), width: 2),
                ),
              ),
              onChanged: (v) => setState(() => _attendanceSearchQuery = v),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoadingAttendanceRoster)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (filteredRoster.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No attendance records found for this period and site')),
            ),
          )
        else
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                columns: const [
                  DataColumn(label: Text('S/N', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Employee ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Present', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Late', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Half Day', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Leave', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Absent', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Days Worked', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Reg. Hours', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('OT Hours', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('OT Rate (ETB)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('OT Pay (ETB)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredRoster.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final r = entry.value;
                  return DataRow(cells: [
                    DataCell(Text('$idx')),
                    DataCell(Text('${r['employee_id']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${r['worker_name']}')),
                    DataCell(Text('${r['present_count']}')),
                    DataCell(Text('${r['late_count']}')),
                    DataCell(Text('${r['half_day_count']}')),
                    DataCell(Text('${r['leave_count']}')),
                    DataCell(Text('${r['absent_count']}')),
                    DataCell(Text('${r['days_worked']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007A3D)))),
                    DataCell(Text('${r['regular_hours']}')),
                    DataCell(Text('${r['overtime_hours']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)))),
                    DataCell(Text('ETB ${_currencyFormat.format(r['overtime_rate'] ?? 0)}')),
                    DataCell(Text('ETB ${_currencyFormat.format(r['overtime_pay'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007A3D)))),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: WORKFORCE CENSUS & HR REGISTRY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWorkforceCensusTab() {
    if (_censusWorkers.isEmpty && !_isLoadingCensus) {
      _loadCensusData();
    }

    final filteredWorkers = _censusWorkers.where((w) {
      if (_censusSearchQuery.isEmpty) return true;
      final q = _censusSearchQuery.toLowerCase();
      final name = (w['full_name'] ?? '').toString().toLowerCase();
      final id = (w['employee_id'] ?? '').toString().toLowerCase();
      final phone = (w['phone_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q) || phone.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Filter Controls Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['all', 'active', 'inactive', 'terminated', 'suspended'].map((st) {
                    final isSelected = _censusStatusFilter == st;
                    return ChoiceChip(
                      label: Text(st.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF1A1A1A))),
                      selected: isSelected,
                      selectedColor: const Color(0xFF007A3D),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _censusStatusFilter = st);
                          _loadCensusData();
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Work Type Dropdown
                    Expanded(
                      child: DropdownButton<int?>(
                        value: _censusWorkTypeId,
                        isExpanded: true,
                        hint: const Text('All Work Types', style: TextStyle(fontSize: 13)),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Work Types')),
                          ..._workTypes.map((wt) => DropdownMenuItem<int?>(
                                value: wt['id'] as int,
                                child: Text(wt['name'] ?? '', style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _censusWorkTypeId = val);
                          _loadCensusData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Export Full Census Excel
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A192F),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      label: const Text('Export', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        _downloadFile(
                          urlPath: '/reports/worker-census/excel',
                          filename: 'Workforce_Census_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
                          queryParams: {
                            if (_selectedSiteId != null) 'site_id': _selectedSiteId,
                            if (_censusWorkTypeId != null) 'work_type_id': _censusWorkTypeId,
                            if (_censusStatusFilter != 'all') 'status': _censusStatusFilter,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section title + full-width search bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Census Master List (${_censusWorkers.length} workers)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search worker name, ID or work type...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF007A3D)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007A3D), width: 2),
                ),
              ),
              onChanged: (v) => setState(() => _censusSearchQuery = v),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoadingCensus)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (filteredWorkers.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No workers matching census filter criteria')),
            ),
          )
        else
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                columns: const [
                  DataColumn(label: Text('S/N', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Employee ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Site', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Workplace', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Work Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Hierarchy', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Pay Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Base Rate (ETB)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Bank Account', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredWorkers.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final w = entry.value;
                  final statusStr = (w['status'] ?? 'active').toString().toUpperCase();
                  final isAct = statusStr == 'ACTIVE';

                  return DataRow(cells: [
                    DataCell(Text('$idx')),
                    DataCell(Text('${w['employee_id']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${w['full_name']}')),
                    DataCell(Text('${w['phone_number']}')),
                    DataCell(Text('${w['site_name']}')),
                    DataCell(Text('${w['work_place_name']}')),
                    DataCell(Text('${w['work_type_name']}')),
                    DataCell(Text('Lvl ${w['hierarchy_level'] ?? '-' }')),
                    DataCell(Text('${(w['payment_mode'] ?? '').replaceAll('_', ' ')}')),
                    DataCell(Text('ETB ${_currencyFormat.format(w['base_rate'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('${w['bank_name'] ?? ''} ${w['bank_account_number'] ?? ''}')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAct ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAct ? const Color(0xFF007A3D) : const Color(0xFFB71C1C),
                        ),
                      ),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE EXPORT ACTION CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExportActionCard({
    required String title,
    required String subtitle,
    required String fileFormat,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fileFormat,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: const Color(0xFF6B7280), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Download File',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.download_rounded, color: color, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double floatOrZero(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
