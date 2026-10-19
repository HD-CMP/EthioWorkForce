import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/datasources/payroll_remote_datasource.dart';
import '../../../../core/utils/app_snackbar.dart';

class CashPaymentSheet extends StatefulWidget {
  final int payrollId;
  final String payrollCode;
  final String period;
  final List<PaymentRecord> records;
  final bool isPayrollLocked;

  const CashPaymentSheet({
    Key? key,
    required this.payrollId,
    required this.payrollCode,
    required this.period,
    required this.records,
    this.isPayrollLocked = false,
  }) : super(key: key);

  @override
  State<CashPaymentSheet> createState() => _CashPaymentSheetState();
}

class PaymentRecord {
  final int itemId;
  final String employeeId;
  final String fullName;
  final double netAmount;
  final String? paymentPeriodDescription;
  final String? workTypeName;
  String? signatureData;
  DateTime? signedAt;
  bool isPaid;
  DateTime? paidAt;

  PaymentRecord({
    required this.itemId,
    required this.employeeId,
    required this.fullName,
    required this.netAmount,
    this.paymentPeriodDescription,
    this.workTypeName,
    this.signatureData,
    this.signedAt,
    this.isPaid = false,
    this.paidAt,
  });
}

class _CashPaymentSheetState extends State<CashPaymentSheet> with TickerProviderStateMixin {
  int? _selectedRecordIndex;
  late TabController _tabController;
  late TabController _workTypeTabController;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  bool _isLocked = false;
  String _selectedWorkType = 'All';
  final _dataSource = PayrollRemoteDataSource();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _workTypeTabController = TabController(length: _workTypeGroups.length, vsync: this);
    _isLocked = widget.isPayrollLocked;
  }

  List<String> get _workTypeGroups {
    final workTypes = widget.records
        .map((r) => r.workTypeName ?? 'Unknown')
        .toSet()
        .toList();
    
    // Sort work types by total net amount (highest first)
    workTypes.sort((a, b) {
      final aTotal = widget.records
          .where((r) => (r.workTypeName ?? 'Unknown') == a)
          .fold(0.0, (sum, r) => sum + r.netAmount);
      final bTotal = widget.records
          .where((r) => (r.workTypeName ?? 'Unknown') == b)
          .fold(0.0, (sum, r) => sum + r.netAmount);
      return bTotal.compareTo(aTotal);
    });
    
    return ['All', ...workTypes];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _workTypeTabController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  List<PaymentRecord> get _filteredRecords {
    List<PaymentRecord> filtered;
    if (_selectedWorkType == 'All') {
      filtered = List.from(widget.records);
    } else {
      filtered = widget.records.where((r) => r.workTypeName == _selectedWorkType).toList();
    }
    filtered.sort((a, b) => b.netAmount.compareTo(a.netAmount));
    return filtered;
  }

  int _getWorkTypeCount(String workType) {
    if (workType == 'All') return widget.records.length;
    return widget.records.where((r) => r.workTypeName == workType).length;
  }

  double _getWorkTypePaidAmount(String workType) {
    final records = workType == 'All' 
        ? widget.records 
        : widget.records.where((r) => r.workTypeName == workType);
    return records.where((r) => r.isPaid).fold(0.0, (sum, r) => sum + r.netAmount);
  }

  double _getWorkTypeUnpaidAmount(String workType) {
    final records = workType == 'All' 
        ? widget.records 
        : widget.records.where((r) => r.workTypeName == workType);
    return records.where((r) => !r.isPaid).fold(0.0, (sum, r) => sum + r.netAmount);
  }

  double get _totalAmount {
    return widget.records.fold(0.0, (sum, record) => sum + record.netAmount);
  }

  double get _totalPaid {
    return widget.records.where((r) => r.isPaid).fold(0.0, (sum, record) => sum + record.netAmount);
  }

  int get _signedCount {
    return widget.records.where((r) => r.signatureData != null).length;
  }

  int get _paidCount {
    return widget.records.where((r) => r.isPaid).length;
  }

  Future<void> _togglePayment(int index) async {
    if (_isLocked || _isSaving) return;
    
    final record = widget.records[index];
    final newStatus = !record.isPaid;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _dataSource.markPaymentStatus(
        payrollId: widget.payrollId,
        itemId: record.itemId,
        isPaid: newStatus,
      );
      
      setState(() {
        record.isPaid = newStatus;
        if (newStatus) {
          record.paidAt = DateTime.now();
        } else {
          record.paidAt = null;
        }
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to update payment status: $e');
      }
    }
  }

  Future<void> _confirmAndLock() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lock Payroll'),
        content: Text(
          'Are you sure you want to lock this payroll?\n\n'
          'Paid: $_paidCount / ${widget.records.length}\n'
          'Total: ${_totalPaid.toStringAsFixed(2)} ETB\n\n'
          'This will prevent any further changes to payment status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              setState(() {
                _isSaving = true;
              });
              
              try {
                await _dataSource.lockPayroll(widget.payrollId);
                
                setState(() {
                  _isLocked = true;
                  _isSaving = false;
                });
                
                if (mounted) {
                  AppSnackBar.showSuccess(context, 'Payroll locked successfully');
                }
              } catch (e) {
                setState(() {
                  _isSaving = false;
                });
                
                if (mounted) {
                  AppSnackBar.showError(context, 'Failed to lock payroll: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A3D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lock Payroll'),
          ),
        ],
      ),
    );
  }

  void _collectSignature(int index) {
    setState(() {
      _selectedRecordIndex = index;
      _signatureController.clear();
    });

    showDialog(
      context: context,
      builder: (context) => _SignatureDialog(
        employeeName: widget.records[index].fullName,
        amount: widget.records[index].netAmount,
        controller: _signatureController,
        onSave: () {
          final signatureData = _signatureController.toRawSVG();
          if (signatureData != null) {
            setState(() {
              widget.records[index].signatureData = signatureData;
              widget.records[index].signedAt = DateTime.now();
            });
          }
          Navigator.pop(context);
        },
        onClear: () {
          _signatureController.clear();
        },
      ),
    );
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CASH PAYMENT SHEET',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Payroll Code: ${widget.payrollCode}'),
              pw.Text('Period: ${widget.period}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['S/N', 'Employee ID', 'Full Name', 'Net Amount (ETB)', 'Signature', 'Date'],
                data: List.generate(
                  widget.records.length,
                  (index) => [
                    (index + 1).toString(),
                    widget.records[index].employeeId,
                    widget.records[index].fullName,
                    widget.records[index].netAmount.toStringAsFixed(2),
                    widget.records[index].signatureData != null ? 'Signed' : '',
                    widget.records[index].signedAt?.toString().split(' ')[0] ?? '',
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    '${_totalAmount.toStringAsFixed(2)} ETB',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Payment Sheet'),
        actions: [
          if (_isLocked)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Chip(
                label: Text('LOCKED', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: const Color(0xFFB71C1C),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _exportToPdf,
            tooltip: 'Export to PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xB3FFFFFF),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Signature Collection'),
            Tab(icon: Icon(Icons.toggle_on), text: 'Quick Payment'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSignatureTab(),
          _buildQuickPaymentTab(),
        ],
      ),
    );
  }

  Widget _buildSignatureTab() {
    return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE8EDF4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payroll: ${widget.payrollCode}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Period: ${widget.period}'),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: ${_totalAmount.toStringAsFixed(2)} ETB',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF007A3D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Signed: $_signedCount / ${widget.records.length}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.records.length,
              itemBuilder: (context, index) {
                final record = widget.records[index];
                final isSigned = record.signatureData != null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSigned ? const Color(0xFF007A3D) : const Color(0xFF9CA3AF),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      record.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${record.employeeId}'),
                        if (isSigned)
                          Text(
                            'Signed: ${record.signedAt?.toString().split(' ')[0]}',
                            style: const TextStyle(
                              color: const Color(0xFF007A3D),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${record.netAmount.toStringAsFixed(2)} ETB',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isSigned ? Icons.check_circle : Icons.edit,
                          color: isSigned ? const Color(0xFF007A3D) : const Color(0xFF1E3A5F),
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () => _collectSignature(index),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD1D5DB),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _signedCount == widget.records.length ? _exportToPdf : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Complete Payment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF007A3D),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }

  Map<String, List<int>> _groupRecordsByPeriod() {
    final groups = <String, List<int>>{};
    
    for (int i = 0; i < widget.records.length; i++) {
      final period = widget.records[i].paymentPeriodDescription ?? 'Standard Period';
      if (!groups.containsKey(period)) {
        groups[period] = [];
      }
      groups[period]!.add(i);
    }
    
    return groups;
  }

  Widget _buildQuickPaymentTab() {
    final paidAmount = _getWorkTypePaidAmount(_selectedWorkType);
    final unpaidAmount = _getWorkTypeUnpaidAmount(_selectedWorkType);
    final filteredRecords = _filteredRecords;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF004A25), const Color(0xFF007A3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF80C4A8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payrollCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.period,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xE6FFFFFF),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${filteredRecords.where((r) => r.isPaid).length} / ${filteredRecords.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xE6FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AmountCard(
                      title: 'Paid',
                      amount: paidAmount,
                      icon: Icons.check_circle,
                      color: Colors.white,
                      backgroundColor: const Color(0x33FFFFFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AmountCard(
                      title: 'Unpaid',
                      amount: unpaidAmount,
                      icon: Icons.pending,
                      color: Colors.white,
                      backgroundColor: const Color(0x33FFFFFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFFF3F4F6),
          child: TabBar(
            controller: _workTypeTabController,
            isScrollable: true,
            labelColor: const Color(0xFF004A25),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF004A25),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            onTap: (index) {
              setState(() {
                _selectedWorkType = _workTypeGroups[index];
              });
            },
            tabs: _workTypeGroups.map((workType) {
              final count = _getWorkTypeCount(workType);
              return Tab(
                child: Row(
                  children: [
                    Text(workType),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedWorkType == workType 
                            ? const Color(0xFF004A25) 
                            : const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: const Color(0xFF9CA3AF)),
                      const SizedBox(height: 16),
                      Text(
                        'No workers in this category',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, listIndex) {
                    final actualIndex = widget.records.indexOf(filteredRecords[listIndex]);
                    final record = filteredRecords[listIndex];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: record.isPaid ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: record.isPaid ? const Color(0xFF80C4A8) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      color: record.isPaid ? const Color(0xFFE8F5EE) : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: record.isPaid ? const Color(0xFF007A3D) : const Color(0xFF6B7280),
                              child: Text(
                                '${actualIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (record.isPaid)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: const Color(0xFF004A25),
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          record.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.badge, size: 12, color: const Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(
                                  record.employeeId,
                                  style: TextStyle(fontSize: 12, color: const Color(0xFF4B5563)),
                                ),
                              ],
                            ),
                            if (record.isPaid && record.paidAt != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: const Color(0xFF005C2E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Paid: ${record.paidAt?.toString().split(' ')[0]}',
                                    style: TextStyle(
                                      color: const Color(0xFF004A25),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${record.netAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: record.isPaid ? const Color(0xFF004A25) : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  'ETB',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: record.isPaid,
                                onChanged: _isLocked ? null : (_) => _togglePayment(actualIndex),
                                activeThumbColor: const Color(0xFF004A25),
                                activeTrackColor: const Color(0xFF80C4A8),
                              ),
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD1D5DB),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Auto-save status info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF9AAFCA)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: const Color(0xFF0A192F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isSaving 
                          ? 'Saving changes...' 
                          : 'Payment changes are saved automatically',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF0A192F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_isSaving)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF0A192F)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Lock Payroll button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLocked ? null : _confirmAndLock,
                  icon: Icon(_isLocked ? Icons.lock : Icons.lock_outline),
                  label: Text(_isLocked ? 'Payroll Locked' : 'Lock Payroll'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF007A3D),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _AmountCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromARGB(77, color.red, color.green, color.blue)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color.fromARGB(230, color.red, color.green, color.blue),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${amount.toStringAsFixed(2)} ETB',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureDialog extends StatelessWidget {
  final String employeeName;
  final double amount;
  final SignatureController controller;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const _SignatureDialog({
    required this.employeeName,
    required this.amount,
    required this.controller,
    required this.onSave,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Collect Signature',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Employee: $employeeName'),
            Text(
              'Amount: ${amount.toStringAsFixed(2)} ETB',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF007A3D),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF9CA3AF)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: controller,
                  height: 200,
                  backgroundColor: const Color(0xFFF3F4F6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A3D),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
