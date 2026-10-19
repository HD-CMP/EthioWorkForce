import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/file_saver.dart';
import '../../data/datasources/payroll_remote_datasource.dart';
import '../bloc/payroll_bloc.dart';
import '../bloc/payroll_event.dart';
import '../bloc/payroll_state.dart';
import '../widgets/cash_payment_sheet.dart';

class PayrollDetailPage extends StatefulWidget {
  final int payrollId;
  final String payrollCode;
  final String period;

  const PayrollDetailPage({
    super.key,
    required this.payrollId,
    required this.payrollCode,
    required this.period,
  });

  @override
  State<PayrollDetailPage> createState() => _PayrollDetailPageState();
}

class _PayrollDetailPageState extends State<PayrollDetailPage> {
  Map<String, dynamic>? _periodBreakdown;
  bool _isLoadingBreakdown = true;
  final _dataSource = PayrollRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _loadPeriodBreakdown();
  }

  Future<void> _loadPeriodBreakdown() async {
    try {
      final breakdown = await _dataSource.getPayrollPeriodBreakdown(widget.payrollId);
      if (mounted) {
        setState(() {
          _periodBreakdown = breakdown;
          _isLoadingBreakdown = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBreakdown = false;
        });
      }
    }
  }

  Future<void> _handleExport(BuildContext context, Future<String> Function() exportAction) async {
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

  Future<void> _handleApprove(BuildContext context, int payrollId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Payroll Run'),
        content: const Text(
          'Are you sure you want to formally approve this payroll run? '
          'Once approved, statutory amounts and net payouts will be finalized.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _dataSource.approvePayroll(payrollId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Payroll run approved successfully!'),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.read<PayrollBloc>().add(LoadPayrollWithItems(payrollId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Approval failed: $e')),
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

  Future<void> _handleLock(BuildContext context, int payrollId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.lock_outline, color: Color(0xFFB71C1C), size: 26),
          SizedBox(width: 10),
          Text('Lock & Archive Payroll'),
        ]),
        content: const Text(
          'Locking this payroll will permanently seal all associated attendance '
          'and overtime records in this period. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lock & Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _dataSource.lockPayroll(payrollId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.lock, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Payroll locked and archived. Records are sealed.')),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.read<PayrollBloc>().add(LoadPayrollWithItems(payrollId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Lock failed: $e')),
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

  Future<void> _confirmDeletePayroll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C), size: 28),
          SizedBox(width: 12),
          Text('Delete Payroll?', style: TextStyle(fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to permanently delete:', style: TextStyle(color: const Color(0xFF374151))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.payrollCode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will permanently remove all associated payroll items. This action cannot be undone.',
              style: TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Delete'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final dio = await DioClient.createDio();
      await dio.delete('/payroll/${widget.payrollId}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Payroll deleted successfully'),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Cannot delete — payroll may be locked or approved.')),
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
    final localizations = AppLocalizations.of(context);

    return BlocProvider(
      create: (_) => getIt<PayrollBloc>()..add(LoadPayrollWithItems(widget.payrollId)),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payroll Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.payrollCode,
                style: const TextStyle(fontSize: 11, color: const Color(0xB3FFFFFF)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Payroll Report',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Export to PDF or Excel to share'),
                    ]),
                    backgroundColor: const Color(0xFF007A3D),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                    action: SnackBarAction(
                      label: 'EXPORT',
                      textColor: const Color(0xFFFFD54F),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeletePayroll(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, color: Color(0xFFB71C1C), size: 20),
                    SizedBox(width: 12),
                    Text('Delete Payroll', style: TextStyle(color: Color(0xFFB71C1C))),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<PayrollBloc, PayrollState>(
          builder: (context, state) {
            if (state is PayrollLoading || state is PayrollInitial || state is PayrollLoaded || state is PayrollDetailsLoaded || state is PayrollCalculating || state is PayrollCalculated || state is PayrollApproving || state is PayrollApproved) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PayrollError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Color(0xFFB71C1C)),
                      const SizedBox(height: 16),
                      const Text(
                        'Could not load payroll details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.read<PayrollBloc>().add(LoadPayrollWithItems(widget.payrollId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is! PayrollWithItemsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final payroll = state.payroll;
            final items = state.items;
            final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
            
            return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    const Color(0xB3007A3D),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payroll.payrollCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    payroll.formattedPeriod,
                    style: const TextStyle(
                      color: const Color(0xB3FFFFFF),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoChip(
                        label: 'Total: ${currencyFormat.format(payroll.totalNetAmount)}',
                        icon: Icons.account_balance_wallet,
                      ),
                      _InfoChip(
                        label: '${items.length} Employees',
                        icon: Icons.people,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          payroll.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (payroll.status.toLowerCase() != 'paid') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (payroll.status.toLowerCase() == 'calculated' || payroll.status.toLowerCase() == 'draft')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1B5E20),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Approve Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _handleApprove(context, widget.payrollId),
                          ),
                        if (payroll.status.toLowerCase() == 'approved')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD54F),
                              foregroundColor: const Color(0xFF1A1A1A),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Lock & Archive', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _handleLock(context, widget.payrollId),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_periodBreakdown != null && _periodBreakdown!['period_types_count'] > 1) ...[
                    Text(
                      'Payment Period Breakdown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This payroll includes workers with different payment cycles',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PeriodBreakdownCard(breakdown: _periodBreakdown!),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Workers by Work Type',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Workers are organized by their work type',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _WorkTypeGroupsCard(items: items),
                  const SizedBox(height: 24),
                  Text(
                    localizations?.exportPayroll ?? 'Export Options',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ExportSection(
                    title: 'Bank Transfers',
                    icon: Icons.account_balance,
                    children: [
                      _ExportButton(
                        label: localizations?.exportToCBE ?? 'Export to CBE',
                        icon: Icons.download,
                        color: const Color(0xFF1E3A5F),
                        onTap: () => _handleExport(context, () => _dataSource.exportPayrollCBE(widget.payrollId)),
                      ),
                      _ExportButton(
                        label: localizations?.exportToDashen ?? 'Export to Dashen Bank',
                        icon: Icons.download,
                        color: const Color(0xFF007A3D),
                        onTap: () => _handleExport(context, () => _dataSource.exportPayrollDashen(widget.payrollId)),
                      ),
                      _ExportButton(
                        label: localizations?.exportToAwash ?? 'Export to Awash Bank',
                        icon: Icons.download,
                        color: const Color(0xFFE65100),
                        onTap: () => _handleExport(context, () => _dataSource.exportPayrollAwash(widget.payrollId)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ExportSection(
                    title: 'Mobile Money',
                    icon: Icons.phone_android,
                    children: [
                      _ExportButton(
                        label: localizations?.exportToTelebirr ?? 'Export to Telebirr',
                        icon: Icons.download,
                        color: const Color(0xFF0A192F),
                        onTap: () => _handleExport(context, () => _dataSource.exportPayrollTelebirr(widget.payrollId)),
                      ),
                      _ExportButton(
                        label: 'Export to M-Pesa',
                        icon: Icons.download,
                        color: const Color(0xFFB71C1C),
                        onTap: () => _handleExport(context, () async {
                          final dio = await DioClient.createDio();
                          final fn = 'MPesa_Payroll_${widget.payrollId}.csv';
                          final resp = await dio.get(
                            '/reports/payroll/${widget.payrollId}/export/mpesa',
                            options: Options(responseType: ResponseType.bytes),
                          );
                          await FileSaver.saveAndOpenFile(List<int>.from(resp.data), fn);
                          return fn;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ExportSection(
                    title: 'Reports & Documentation',
                    icon: Icons.description,
                    children: [
                      _ExportButton(
                        label: localizations?.pensionDeclaration ?? 'Pension Declaration (Excel)',
                        icon: Icons.file_present,
                        color: const Color(0xFF007A3D),
                        onTap: () => _handleExport(context, () => _dataSource.exportPensionReport(widget.payrollId, 'excel')),
                      ),
                      _ExportButton(
                        label: 'Pension Declaration (PDF)',
                        icon: Icons.picture_as_pdf,
                        color: const Color(0xFFB71C1C),
                        onTap: () => _handleExport(context, () => _dataSource.exportPensionReport(widget.payrollId, 'pdf')),
                      ),
                      _ExportButton(
                        label: localizations?.cashPaymentSheet ?? 'Cash Payment Sheet',
                        icon: Icons.attach_money,
                        color: const Color(0xFF007A3D),
                        onTap: () async {
                          final paymentRecords = items.map((item) => PaymentRecord(
                            itemId: item.id!,
                            employeeId: item.employeeId ?? 'N/A',
                            fullName: item.workerName ?? 'Unknown',
                            netAmount: item.netSalary,
                            paymentPeriodDescription: item.paymentPeriodDescription,
                            workTypeName: item.workTypeName,
                            isPaid: item.isPaid,
                            paidAt: item.paymentDate != null ? DateTime.tryParse(item.paymentDate!) : null,
                          )).toList();
                          
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CashPaymentSheet(
                                payrollId: widget.payrollId,
                                payrollCode: widget.payrollCode,
                                period: widget.period,
                                records: paymentRecords,
                                isPayrollLocked: payroll.status.toLowerCase() == 'paid',
                              ),
                            ),
                          );
                          
                          // Reload payroll data when returning from cash payment sheet
                          if (context.mounted) {
                            context.read<PayrollBloc>().add(LoadPayrollWithItems(widget.payrollId));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ExportSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Color.fromARGB(77, color.red, color.green, color.blue)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(26, color.red, color.green, color.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: const Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;

  const _PeriodBreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final breakdownList = breakdown['breakdown'] as List<dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_work, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${breakdown['period_types_count']} Different Payment Cycles',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...breakdownList.map((periodData) {
              final periodType = periodData['period_type'] as String;
              final workerCount = periodData['worker_count'] as int;
              final totalNet = (periodData['total_net'] as num).toDouble();
              final proratedCount = periodData['prorated_count'] as int;

              final periodColor = _getPeriodColor(periodType);
              final periodIcon = _getPeriodIcon(periodType);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(26, periodColor.red, periodColor.green, periodColor.blue),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: periodColor, width: 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(51, periodColor.red, periodColor.green, periodColor.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(periodIcon, color: periodColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  periodType,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: periodColor,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(totalNet),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: periodColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$workerCount workers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                if (proratedCount > 0)
                                  Text(
                                    '$proratedCount prorated',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFFE65100),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getPeriodColor(String periodType) {
    switch (periodType.toLowerCase()) {
      case 'daily':
        return const Color(0xFF1E3A5F);
      case 'hourly':
        return Colors.cyan;
      case 'weekly':
        return const Color(0xFF007A3D);
      case 'bi-weekly':
        return const Color(0xFF007A3D);
      case 'monthly':
        return const Color(0xFF0A192F);
      default:
        return const Color(0xFFE65100);
    }
  }

  IconData _getPeriodIcon(String periodType) {
    switch (periodType.toLowerCase()) {
      case 'daily':
        return Icons.today;
      case 'hourly':
        return Icons.access_time;
      case 'weekly':
        return Icons.date_range;
      case 'bi-weekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.event;
    }
  }
}

class _WorkTypeGroupsCard extends StatelessWidget {
  final List items;

  const _WorkTypeGroupsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    
    // Group items by work type
    final Map<String, List> groupedItems = {};
    for (var item in items) {
      final workType = item.workTypeName ?? 'Unknown';
      if (!groupedItems.containsKey(workType)) {
        groupedItems[workType] = [];
      }
      groupedItems[workType]!.add(item);
    }
    
    // Sort work types by total net salary (highest first)
    final sortedWorkTypes = groupedItems.keys.toList()
      ..sort((a, b) {
        final aTotal = groupedItems[a]!.fold(0.0, (sum, item) => sum + item.netSalary);
        final bTotal = groupedItems[b]!.fold(0.0, (sum, item) => sum + item.netSalary);
        return bTotal.compareTo(aTotal);
      });
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${sortedWorkTypes.length} Work Types',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedWorkTypes.map((workType) {
              final workTypeItems = groupedItems[workType]!;
              final totalNet = workTypeItems.fold(0.0, (sum, item) => sum + item.netSalary);
              final totalGross = workTypeItems.fold(0.0, (sum, item) => sum + item.grossSalary);
              
              return _WorkTypeExpansionTile(
                workType: workType,
                items: workTypeItems,
                totalNet: totalNet,
                totalGross: totalGross,
                currencyFormat: currencyFormat,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _WorkTypeExpansionTile extends StatelessWidget {
  final String workType;
  final List items;
  final double totalNet;
  final double totalGross;
  final NumberFormat currencyFormat;

  const _WorkTypeExpansionTile({
    required this.workType,
    required this.items,
    required this.totalNet,
    required this.totalGross,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    // Sort workers by net salary (highest first)
    final sortedItems = List.from(items)
      ..sort((a, b) => b.netSalary.compareTo(a.netSalary));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2DFCA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.work_outline, color: const Color(0xFF004A25), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workType,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sortedItems.length} workers',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(totalNet),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004A25),
                    ),
                  ),
                  Text(
                    'Net Total',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFD1D5DB),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.workerName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.employeeId ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(item.netSalary),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF004A25),
                        ),
                      ),
                      Text(
                        'Net',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                border: Border(top: BorderSide(color: const Color(0xFFD1D5DB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gross Total:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    currencyFormat.format(totalGross),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
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
}
