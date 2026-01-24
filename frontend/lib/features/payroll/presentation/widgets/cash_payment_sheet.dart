import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CashPaymentSheet extends StatefulWidget {
  final String payrollCode;
  final String period;
  final List<PaymentRecord> records;

  const CashPaymentSheet({
    Key? key,
    required this.payrollCode,
    required this.period,
    required this.records,
  }) : super(key: key);

  @override
  State<CashPaymentSheet> createState() => _CashPaymentSheetState();
}

class PaymentRecord {
  final String employeeId;
  final String fullName;
  final double netAmount;
  String? signatureData;
  DateTime? signedAt;

  PaymentRecord({
    required this.employeeId,
    required this.fullName,
    required this.netAmount,
    this.signatureData,
    this.signedAt,
  });
}

class _CashPaymentSheetState extends State<CashPaymentSheet> {
  int? _selectedRecordIndex;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return widget.records.fold(0.0, (sum, record) => sum + record.netAmount);
  }

  int get _signedCount {
    return widget.records.where((r) => r.signatureData != null).length;
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
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _exportToPdf,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
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
                            color: Colors.green,
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
                      backgroundColor: isSigned ? Colors.green : Colors.grey,
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
                              color: Colors.green,
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
                          color: isSigned ? Colors.green : Colors.blue,
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
                  color: Colors.grey.shade300,
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: controller,
                  height: 200,
                  backgroundColor: Colors.grey.shade100,
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
                    backgroundColor: Colors.green,
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
