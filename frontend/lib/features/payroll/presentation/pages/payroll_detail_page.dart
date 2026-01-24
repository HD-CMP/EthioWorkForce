import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../widgets/cash_payment_sheet.dart';

class PayrollDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Payroll $payrollCode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payrollCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    period,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoChip(
                        label: 'Total: 125,500 ETB',
                        icon: Icons.account_balance_wallet,
                      ),
                      _InfoChip(
                        label: '50 Employees',
                        icon: Icons.people,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      _ExportButton(
                        label: localizations?.exportToDashen ?? 'Export to Dashen Bank',
                        icon: Icons.download,
                        color: Colors.green,
                        onTap: () {},
                      ),
                      _ExportButton(
                        label: localizations?.exportToAwash ?? 'Export to Awash Bank',
                        icon: Icons.download,
                        color: Colors.orange,
                        onTap: () {},
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
                        color: Colors.purple,
                        onTap: () {},
                      ),
                      _ExportButton(
                        label: 'Export to M-Pesa',
                        icon: Icons.download,
                        color: Colors.red,
                        onTap: () {},
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
                        color: Colors.teal,
                        onTap: () {},
                      ),
                      _ExportButton(
                        label: 'Pension Declaration (PDF)',
                        icon: Icons.picture_as_pdf,
                        color: Colors.red,
                        onTap: () {},
                      ),
                      _ExportButton(
                        label: localizations?.cashPaymentSheet ?? 'Cash Payment Sheet',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CashPaymentSheet(
                                payrollCode: payrollCode,
                                period: period,
                                records: [],
                              ),
                            ),
                          );
                        },
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
        color: Colors.white.withOpacity(0.2),
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
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
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
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
