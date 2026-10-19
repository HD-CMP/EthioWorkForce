import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

class _PayrollListViewState extends State<_PayrollListView> {
  final SiteRemoteDataSource _siteDataSource = SiteRemoteDataSource();
  final StorageService _storageService = StorageService();
  List<Site> _sites = [];
  Site? _selectedSite;
  bool _isLoadingSites = false;

  @override
  void initState() {
    super.initState();
    _initializeSite();
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
      showDialog(
        context: context,
        builder: (dialogContext) {
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
                      if (site.id != null) {
                        Navigator.pop(dialogContext);
                        await _storageService.setSelectedSiteId(site.id!);
                        if (mounted) {
                          setState(() {
                            _selectedSite = site;
                          });
                          bloc.add(RefreshPayrolls(siteId: site.id));
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
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
      ),
      body: RefreshIndicator(
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
      floatingActionButton: _selectedSite != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PayrollCalculationPage(site: _selectedSite!),
                  ),
                ).then((_) {
                  context.read<PayrollBloc>().add(
                        RefreshPayrolls(siteId: _selectedSite!.id),
                      );
                });
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF007A3D),
                  const Color(0xB3007A3D),
                ],
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
                      ? '${selectedSite!.name} - Manage and export payroll data'
                      : 'Manage and export payroll data',
                  style: TextStyle(
                    color: const Color(0xE6FFFFFF),
                    fontSize: 14,
                  ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PayrollDetailPage(
                payrollId: payroll.id,
                payrollCode: payroll.payrollCode,
                period: payroll.formattedPeriod,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payroll.payrollCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    payroll.formattedPeriod,
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  if (payroll.hasMultiplePeriods == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x1A1E3A5F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x4D1E3A5F)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_work, size: 12, color: const Color(0xFF0A192F)),
                          const SizedBox(width: 4),
                          Text(
                            '${payroll.periodTypesCount} periods',
                            style: TextStyle(
                              color: const Color(0xFF0A192F),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          size: 16, color: const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        'Net: ${currencyFormat.format(payroll.totalNetAmount)}',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(payroll.totalGrossAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A3D),
                    ),
                  ),
                ],
              ),
              if (status == 'approved' || status == 'paid') ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _QuickExportButton(
                        label: 'CBE',
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
                        label: 'Cash',
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
