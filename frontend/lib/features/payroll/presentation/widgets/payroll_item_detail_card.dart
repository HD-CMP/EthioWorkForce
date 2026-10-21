import 'package:flutter/material.dart';
import '../../domain/entities/payroll_item.dart';

class PayrollItemDetailCard extends StatelessWidget {
  final PayrollItem item;

  const PayrollItemDetailCard({
    super.key,
    required this.item,
  });

  /// Opens an interactive bottom sheet payslip for this worker
  static void show(BuildContext context, PayrollItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
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
              PayrollItemDetailCard(item: item),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTaxExempt = (item.incomeTax == null || item.incomeTax == 0.0) &&
        (item.pensionContribution == null || item.pensionContribution == 0.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A192F), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.workerName != null)
                            Text(
                              item.workerName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.employeeId != null)
                                Text(
                                  'ID: ${item.employeeId}',
                                  style: const TextStyle(
                                    color: Color(0xB3FFFFFF),
                                    fontSize: 13,
                                  ),
                                ),
                              if (item.workTypeName != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33FFFFFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.workTypeName!,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x26007A3D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x66007A3D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Net Payout',
                            style: TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${item.netSalary.toStringAsFixed(2)} ETB',
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.paymentPeriodDescription != null || item.paymentPeriodType != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_alt, size: 13, color: Color(0xCCFFFFFF)),
                        const SizedBox(width: 6),
                        Text(
                          item.paymentPeriodDescription ?? item.paymentPeriodType ?? 'Standard Cycle',
                          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
                        ),
                      ],
                    ),
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
                // Tax status banner
                if (isTaxExempt)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 16, color: Color(0xFF007A3D)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tax-Exempt / Daily Casual (0% Income Tax & Pension)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007A3D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Earnings Section
                const Text(
                  'Earnings Breakdown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A3D),
                  ),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Base / Daily Wage Pay',
                  value: item.basicSalary,
                  icon: Icons.payments_outlined,
                ),
                if (item.overtimePay != null && item.overtimePay! > 0)
                  _DetailRow(
                    label: 'Overtime Pay (Attendance)',
                    value: item.overtimePay!,
                    icon: Icons.access_time,
                    color: const Color(0xFF1E3A5F),
                  ),
                if (item.allocatedOvertimePay != null && item.allocatedOvertimePay! > 0)
                  _DetailRow(
                    label: 'Allocated Overtime Pay',
                    value: item.allocatedOvertimePay!,
                    icon: Icons.schedule,
                    color: const Color(0xFF0A192F),
                  ),
                if ((item.overtimePay ?? 0) > 0 || (item.allocatedOvertimePay ?? 0) > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9AAFCA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calculate, color: Color(0xFF0A192F), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Total Overtime',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A192F),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${item.totalOvertimePay.toStringAsFixed(2)} ETB',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0A192F),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.allowances != null && item.allowances! > 0)
                  _DetailRow(
                    label: 'Allowances',
                    value: item.allowances!,
                    icon: Icons.card_giftcard,
                  ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gross Salary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${item.grossSalary.toStringAsFixed(2)} ETB',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A3D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Deductions Section
                const Text(
                  'Statutory Deductions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 10),
                if (item.incomeTax != null && item.incomeTax! > 0)
                  _DetailRow(
                    label: 'Income Tax (ERCA Progressive)',
                    value: item.incomeTax!,
                    icon: Icons.account_balance,
                    isDeduction: true,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Color(0xFF9CA3AF)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Income Tax', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        ),
                        Text('0.00 ETB (Exempt)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF007A3D))),
                      ],
                    ),
                  ),
                if (item.pensionContribution != null && item.pensionContribution! > 0)
                  _DetailRow(
                    label: 'Employee Pension (7%)',
                    value: item.pensionContribution!,
                    icon: Icons.savings,
                    isDeduction: true,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Color(0xFF9CA3AF)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Employee Pension', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        ),
                        Text('0.00 ETB (Exempt)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF007A3D))),
                      ],
                    ),
                  ),
                if (item.otherDeductions != null && item.otherDeductions! > 0)
                  _DetailRow(
                    label: 'Other Deductions / Penalties',
                    value: item.otherDeductions!,
                    icon: Icons.remove_circle_outline,
                    isDeduction: true,
                  ),

                const Divider(height: 20),

                // Net payout banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF66B28A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments, color: Color(0xFF005C2E), size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Net Pay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005C2E),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${item.netSalary.toStringAsFixed(2)} ETB',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005C2E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Payment disbursement & attendance info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF4B5563)),
                          SizedBox(width: 6),
                          Text(
                            'Disbursement & Tracking',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (item.bankAccountNumber != null && item.bankAccountNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance, size: 14, color: Color(0xFF1E3A5F)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${item.bankName ?? "Bank"}: ${item.bankAccountNumber}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_android, size: 14, color: Color(0xFF007A3D)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Mobile Money: ${item.phoneNumber}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF007A3D)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.money, size: 14, color: Color(0xFFE65100)),
                              SizedBox(width: 6),
                              Text(
                                'Physical Cash Payout (Requires Signature)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                              ),
                            ],
                          ),
                        ),
                      if (item.daysWorked != null || item.hoursWorked != null) ...[
                        const Divider(height: 12),
                        Row(
                          children: [
                            if (item.daysWorked != null) ...[
                              const Icon(Icons.calendar_today, size: 13, color: Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text(
                                'Days: ${item.daysWorked}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                            if (item.hoursWorked != null) ...[
                              const SizedBox(width: 14),
                              const Icon(Icons.schedule, size: 13, color: Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text(
                                'Hours: ${item.hoursWorked!.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.isPaid ? const Color(0xFFE8F5EE) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isPaid ? 'PAID' : 'PENDING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item.isPaid ? const Color(0xFF007A3D) : const Color(0xFFE65100),
                                ),
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
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color? color;
  final bool isDeduction;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.isDeduction = false,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor = color ?? (isDeduction ? const Color(0xFFB71C1C) : const Color(0xFF007A3D));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: rowColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          Text(
            '${isDeduction ? "-" : ""}${value.toStringAsFixed(2)} ETB',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: rowColor,
            ),
          ),
        ],
      ),
    );
  }
}
