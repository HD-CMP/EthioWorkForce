import 'package:flutter/material.dart';
import '../../domain/entities/payroll_item.dart';

class PayrollItemDetailCard extends StatelessWidget {
  final PayrollItem item;

  const PayrollItemDetailCard({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0A192F), const Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                    if (item.employeeId != null)
                      Text(
                        'ID: ${item.employeeId}',
                        style: const TextStyle(
                          color: const Color(0xB3FFFFFF),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Net Salary',
                        style: TextStyle(
                          color: const Color(0xB3FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${item.netSalary.toStringAsFixed(2)} ETB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earnings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF007A3D),
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Basic Salary',
                  value: item.basicSalary,
                  icon: Icons.attach_money,
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
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9AAFCA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calculate, color: const Color(0xFF0A192F), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Overtime',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A192F),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${item.totalOvertimePay.toStringAsFixed(2)} ETB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF0A192F),
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
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gross Salary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${item.grossSalary.toStringAsFixed(2)} ETB',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007A3D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Deductions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 12),
                if (item.incomeTax != null && item.incomeTax! > 0)
                  _DetailRow(
                    label: 'Income Tax',
                    value: item.incomeTax!,
                    icon: Icons.account_balance,
                    isDeduction: true,
                  ),
                if (item.pensionContribution != null && item.pensionContribution! > 0)
                  _DetailRow(
                    label: 'Pension Contribution',
                    value: item.pensionContribution!,
                    icon: Icons.savings,
                    isDeduction: true,
                  ),
                if (item.otherDeductions != null && item.otherDeductions! > 0)
                  _DetailRow(
                    label: 'Other Deductions',
                    value: item.otherDeductions!,
                    icon: Icons.remove_circle_outline,
                    isDeduction: true,
                  ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFE8F5EE), const Color(0xFFE8F5EE)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF66B28A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments, color: const Color(0xFF005C2E), size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Net Salary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${item.netSalary.toStringAsFixed(2)} ETB',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005C2E),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.daysWorked != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: const Color(0xFF9CA3AF)),
                      const SizedBox(width: 8),
                      Text(
                        'Days Worked: ${item.daysWorked}',
                        style: const TextStyle(color: const Color(0xFF9CA3AF)),
                      ),
                      if (item.hoursWorked != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.schedule, size: 16, color: const Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Text(
                          'Hours: ${item.hoursWorked!.toStringAsFixed(1)}',
                          style: const TextStyle(color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ],
                  ),
                ],
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
          Icon(icon, size: 18, color: rowColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${isDeduction ? "-" : ""}${value.toStringAsFixed(2)} ETB',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: rowColor,
            ),
          ),
        ],
      ),
    );
  }
}
