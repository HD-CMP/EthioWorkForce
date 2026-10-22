import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../../workers/domain/entities/site.dart';
import '../../../workers/data/datasources/site_remote_datasource.dart';
import '../bloc/payroll_bloc.dart';
import '../bloc/payroll_event.dart';
import '../bloc/payroll_state.dart';
import 'payroll_detail_page.dart';
import 'payroll_calculation_page.dart';
import 'payroll_preview_page.dart';
import '../../data/datasources/payroll_remote_datasource.dart';
import '../../../../core/utils/app_snackbar.dart';

class PayrollListPage extends StatelessWidget {
  const PayrollListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PayrollBloc>(),
      child: const _PayrollListView(),
    );
  }
}

class _PayrollListView extends StatefulWidget {
  const _PayrollListView();

  @override
  State<_PayrollListView> createState() => _PayrollListViewState();
}

class _PayrollListViewState extends State<_PayrollListView> with SingleTickerProviderStateMixin {
  final SiteRemoteDataSource _siteDataSource = SiteRemoteDataSource();
  final StorageService _storageService = StorageService();
  List<Site> _sites = [];
  Site? _selectedSite;
  bool _isLoadingSites = false;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex && mounted) {
        setState(() => _currentTabIndex = _tabController.index);
        if (_tabController.index == 0 && _selectedSite != null) {
          context.read<PayrollBloc>().add(RefreshPayrolls(siteId: _selectedSite!.id));
        }
      }
    });
    _initializeSite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeSite() async {
    await _loadSites();
    
    final savedSiteId = await _storageService.getSelectedSiteId();
    if (savedSiteId != null && _sites.any((s) => s.id == savedSiteId)) {
      _selectedSite = _sites.firstWhere((s) => s.id == savedSiteId);
    } else if (_sites.isNotEmpty && _selectedSite == null) {
      _selectedSite = _sites.first;
      if (_selectedSite?.id != null) {
        await _storageService.setSelectedSiteId(_selectedSite!.id!);
      }
    }
    
    if (_selectedSite != null && mounted) {
      context.read<PayrollBloc>().add(LoadPayrolls(siteId: _selectedSite!.id));
    }
  }

  Future<void> _loadSites() async {
    setState(() => _isLoadingSites = true);
    try {
      final sites = await _siteDataSource.getSites(isActive: true);
      if (mounted) {
        setState(() {
          _sites = sites;
          _isLoadingSites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSites = false);
        AppSnackBar.showError(context, 'Unable to load sites. Please try again.');
      }
    }
  }

  void _showSiteSelector() {
    try {
      if (_sites.isEmpty) {
        AppSnackBar.showInfo(context, 'No sites available');
        return;
      }
      
      final sites = List<Site>.from(_sites);
      final bloc = context.read<PayrollBloc>();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (bottomSheetContext) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF007A3D), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Select Construction Site',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${sites.length} sites',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF007A3D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final site = sites[index];
                      final isSelected = _selectedSite?.id == site.id;
                      return InkWell(
                        onTap: () async {
                          if (site.id != null) {
                            Navigator.pop(bottomSheetContext);
                            await _storageService.setSelectedSiteId(site.id!);
                            if (mounted) {
                              setState(() {
                                _selectedSite = site;
                              });
                              bloc.add(RefreshPayrolls(siteId: site.id));
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8F5EE) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.business,
                                  size: 18,
                                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
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
                                        color: isSelected ? const Color(0xFF005C2E) : const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Code: ${site.code}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF007A3D), size: 22),
                            ],
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
    } catch (e) {
      // Handle hot reload error
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations?.payroll ?? 'Payroll', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            if (_selectedSite != null)
              Text(_selectedSite!.name, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_rounded, color: Colors.white),
            onPressed: _showSiteSelector,
            tooltip: 'Select Site',
          ),
          IconButton(
            icon: const Icon(Icons.preview_rounded, color: Colors.white),
            tooltip: 'Real-Time Preview',
            onPressed: _selectedSite != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PayrollPreviewPage(site: _selectedSite!),
                      ),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _selectedSite != null
                ? () {
                    context.read<PayrollBloc>().add(
                          RefreshPayrolls(siteId: _selectedSite!.id),
                        );
                  }
                : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xB3FFFFFF),
          indicatorColor: const Color(0xFF007A3D),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt_long_rounded),
              text: 'Payroll Records',
            ),
            Tab(
              icon: Icon(Icons.calculate_rounded),
              text: 'Calculate Payroll',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Payroll Records History
          RefreshIndicator(
              color: const Color(0xFF007A3D),
              onRefresh: () async {
                if (_selectedSite != null) {
                  context.read<PayrollBloc>().add(
                        RefreshPayrolls(siteId: _selectedSite!.id),
                      );
                  await Future.delayed(const Duration(milliseconds: 500));
                }
              },
              child: BlocBuilder<PayrollBloc, PayrollState>(
                builder: (context, state) {
                  if (_isLoadingSites) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF007A3D)),
                    );
                  }
                  if (_sites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: const BoxDecoration(color: Color(0xFFE8EDF4), shape: BoxShape.circle),
                            child: const Icon(Icons.location_off_rounded, size: 36, color: Color(0xFF0A192F)),
                          ),
                          const SizedBox(height: 16),
                          const Text('No sites available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 8),
                          const Text('Contact your administrator', style: TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                    );
                  }
                  if (state is PayrollLoading) {
                    return _LoadingView(selectedSite: _selectedSite);
                  } else if (state is PayrollLoaded) {
                    return _PayrollLoadedView(
                      payrolls: state.payrolls,
                      thisMonthTotal: state.thisMonthTotal,
                      pendingCount: state.pendingCount,
                      selectedSite: _selectedSite,
                    );
                  } else if (state is PayrollError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: _selectedSite != null
                          ? () {
                              context.read<PayrollBloc>().add(
                                    LoadPayrolls(siteId: _selectedSite!.id),
                                  );
                            }
                          : null,
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: const BoxDecoration(color: Color(0xFFE8EDF4), shape: BoxShape.circle),
                          child: const Icon(Icons.payments_rounded, size: 36, color: Color(0xFF0A192F)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Select a site to view payrolls', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
                      ],
                    ),
                  );
                },
              ),
            ),
          // Tab 1: Calculate Payroll Engine
          _selectedSite != null
              ? PayrollCalculationPage(
                  key: ValueKey('calc_' + _selectedSite!.id.toString()),
                  site: _selectedSite!,
                  embedded: true,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(color: Color(0xFFE8EDF4), shape: BoxShape.circle),
                        child: const Icon(Icons.calculate_outlined, size: 36, color: Color(0xFF0A192F)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select a site to calculate payroll',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _showSiteSelector,
                        icon: const Icon(Icons.location_on_rounded, size: 18),
                        label: const Text('Choose Site'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A3D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton: (_selectedSite != null && _currentTabIndex == 0)
          ? FloatingActionButton.extended(
              onPressed: () {
                _tabController.animateTo(1);
              },
              backgroundColor: const Color(0xFF007A3D),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.calculate_rounded),
              label: Text(localizations?.calculatePayroll ?? 'Calculate Payroll'),
            )
          : null,
    );
  }
}

class _LoadingView extends StatelessWidget {
  final Site? selectedSite;

  const _LoadingView({this.selectedSite});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A192F), Color(0xFF1E3A5F)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payroll Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedSite != null
                    ? 'Loading payroll data for ${selectedSite!.name}...'
                    : 'Loading payroll data...',
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF007A3D),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading payrolls...',
                  style: TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF005C2E), Color(0xFF007A3D)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payroll Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFB71C1C)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A3D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PayrollLoadedView extends StatelessWidget {
  final List payrolls;
  final double thisMonthTotal;
  final int pendingCount;
  final Site? selectedSite;

  const _PayrollLoadedView({
    required this.payrolls,
    required this.thisMonthTotal,
    required this.pendingCount,
    this.selectedSite,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 2,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payroll Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (selectedSite != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4DFFFFFF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  selectedSite!.code,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedSite != null
                          ? '${selectedSite!.name} • Calculate, approve & disburse workforce wages'
                          : 'Manage and export construction workforce payroll',
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'This Month',
                    value: currencyFormat.format(thisMonthTotal),
                    icon: Icons.calendar_month,
                    color: const Color(0xFF007A3D),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: pendingCount.toString(),
                    icon: Icons.pending_actions,
                    color: const Color(0xFF0A192F),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Payrolls',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (payrolls.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payrolls found',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first payroll to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final payroll = payrolls[index];
                  return _PayrollCard(payroll: payroll);
                },
                childCount: payrolls.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _PayrollCard extends StatelessWidget {
  final dynamic payroll;

  const _PayrollCard({required this.payroll});

  Future<void> _triggerExport(BuildContext context, Future<String> Function() exportAction) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final filename = await exportAction();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Downloaded $filename')),
              ],
            ),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Export failed: $e')),
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 2,
    );

    final statusColors = {
      'draft': const Color(0xFF9CA3AF),
      'calculated': const Color(0xFF0A192F),
      'approved': const Color(0xFF007A3D),
      'paid': const Color(0xFF005C2E),
      'cancelled': const Color(0xFFB71C1C),
    };

    final statusLabels = {
      'draft': 'Draft',
      'calculated': 'Pending',
      'approved': 'Approved',
      'paid': 'Paid',
      'cancelled': 'Cancelled',
    };

    final status = payroll.status.toLowerCase();
    final statusColor = statusColors[status] ?? const Color(0xFF9CA3AF);
    final statusLabel = statusLabels[status] ?? payroll.status;

    final isMonthly = payroll.periodType.toString().toLowerCase() == 'monthly';
    final isBiWeekly = payroll.periodType.toString().toLowerCase().contains('bi');
    final isTrade = payroll.workTypeId != null;

    final Color accentColor = isMonthly
        ? const Color(0xFF0A192F)
        : (isBiWeekly ? const Color(0xFFE65100) : const Color(0xFF007A3D));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PayrollDetailPage(
                payrollId: payroll.id,
                payrollCode: payroll.payrollCode,
                period: payroll.formattedPeriod,
              ),
            ),
          );
          if (result == true && context.mounted) {
            context.read<PayrollBloc>().add(
              RefreshPayrolls(siteId: payroll.siteId),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 4.5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row: Batch Type & Status & Delete Menu
              Row(
                children: [
                  // Batch Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMonthly
                          ? const Color(0xFFE8EDF4)
                          : (isBiWeekly ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5EE)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMonthly
                            ? const Color(0xFF9AAFCA)
                            : (isBiWeekly ? const Color(0xFFFFCC80) : const Color(0xFFA5D6A7)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMonthly
                              ? Icons.business
                              : (isBiWeekly ? Icons.engineering : (isTrade ? Icons.handyman : Icons.event_repeat)),
                          size: 13,
                          color: isMonthly
                              ? const Color(0xFF0A192F)
                              : (isBiWeekly ? const Color(0xFFE65100) : const Color(0xFF007A3D)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMonthly
                              ? 'Monthly Staff'
                              : (isBiWeekly ? '14-Day Labor' : (isTrade ? 'Trade Batch' : payroll.periodType.toUpperCase())),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMonthly
                                ? const Color(0xFF0A192F)
                                : (isBiWeekly ? const Color(0xFFE65100) : const Color(0xFF007A3D)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ethiopian Month Badge (if present)
                  if (payroll.ethiopianMonth != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month, size: 12, color: Color(0xFF4B5563)),
                          const SizedBox(width: 4),
                          Text(
                            '${payroll.ethiopianMonth} ${payroll.ethiopianYear ?? ""}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(26, statusColor.red, statusColor.green, statusColor.blue),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9CA3AF)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 140),
                    onSelected: (val) async {
                      if (val == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Row(children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C), size: 26),
                              SizedBox(width: 10),
                              Text('Delete Payroll?', style: TextStyle(fontSize: 18)),
                            ]),
                            content: Text(
                              'Are you sure you want to permanently delete ${payroll.payrollCode}?\n\nThis removes all calculated items and cannot be undone.',
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB71C1C),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          try {
                            final dio = await DioClient.createDio();
                            await dio.delete('/payroll/${payroll.id}');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(children: [
                                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Payroll deleted successfully'),
                                  ]),
                                  backgroundColor: Color(0xFF007A3D),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              context.read<PayrollBloc>().add(
                                RefreshPayrolls(siteId: payroll.siteId),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              String msg = 'Could not delete payroll';
                              if (e is DioException && e.response?.data != null && e.response?.data is Map) {
                                msg = e.response?.data['detail'] ?? msg;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(children: [
                                    const Icon(Icons.error_outline, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(msg)),
                                  ]),
                                  backgroundColor: const Color(0xFFB71C1C),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, color: Color(0xFFB71C1C), size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Payroll Code
              Text(
                payroll.payrollCode,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 6),

              // Period & Worker Count Row
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 5),
                  Text(
                    payroll.formattedPeriod,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  if (payroll.employeeCount > 0) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      '${payroll.employeeCount} workers',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Payout Breakdown Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Net Payout',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(payroll.totalNetAmount),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A3D),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Gross: ${currencyFormat.format(payroll.totalGrossAmount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ded: -${currencyFormat.format(payroll.totalDeductions)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick exports if approved or paid
              if (status == 'approved' || status == 'paid') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickExportButton(
                        label: 'CBE Bank',
                        icon: Icons.account_balance,
                        onTap: () => _triggerExport(
                          context,
                          () => getIt<PayrollRemoteDataSource>().exportPayrollCBE(payroll.id),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickExportButton(
                        label: 'Telebirr',
                        icon: Icons.phone_android,
                        onTap: () => _triggerExport(
                          context,
                          () => getIt<PayrollRemoteDataSource>().exportPayrollTelebirr(payroll.id),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickExportButton(
                        label: 'Cash Sheet',
                        icon: Icons.money,
                        onTap: () => _triggerExport(
                          context,
                          () => getIt<PayrollRemoteDataSource>().exportCashPaymentSheet(payroll.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
        border: Border.all(color: Color.fromARGB(77, color.red, color.green, color.blue)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickExportButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1A007A3D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20, color: const Color(0xFF007A3D)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF007A3D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
