import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/work_type.dart';
import '../../../../core/utils/ethiopian_calendar.dart';

class WorkTypeDetailPage extends StatelessWidget {
  final WorkType workType;

  const WorkTypeDetailPage({super.key, required this.workType});

  String getHierarchyLevelName(int level) {
    switch (level) {
      case 1:
        return 'Executive (CEO, Director)';
      case 2:
        return 'Senior Management';
      case 3:
        return 'Middle Management';
      case 4:
        return 'Supervisory (Team Leads)';
      case 5:
        return 'Operational (Workers)';
      case 6:
        return 'Trainee / Apprentice';
      default:
        return 'Level $level';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Work Type Details'),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: workType.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  workType.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  workType.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildBasicInformation(context),
            const SizedBox(height: 12),
            _buildPaymentInformation(context),
            const SizedBox(height: 12),
            _buildTaxInformation(context),
            const SizedBox(height: 12),
            _buildBenefitsInformation(context),
            const SizedBox(height: 12),
            _buildHierarchyInformation(context),
            if (workType.createdAt != null || workType.updatedAt != null) ...[
              const SizedBox(height: 12),
              _buildTimestamps(context),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: workType.isActive
              ? [Colors.blue[600]!, Colors.blue[800]!]
              : [Colors.grey[600]!, Colors.grey[800]!],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.work, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            workType.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Code: ${workType.code}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Basic Information',
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      children: [
        if (workType.description != null && workType.description!.isNotEmpty)
          _buildFullWidthInfoTile(
            icon: Icons.description,
            label: 'Description',
            value: workType.description!,
            iconColor: Colors.blue[700]!,
          ),
        _buildInfoTile(
          icon: Icons.code,
          label: 'Work Type Code',
          value: workType.code,
          iconColor: Colors.purple[700]!,
        ),
        _buildInfoTile(
          icon: Icons.toggle_on,
          label: 'Status',
          value: workType.isActive ? 'Active' : 'Inactive',
          iconColor: workType.isActive ? Colors.green[700]! : Colors.grey[700]!,
        ),
      ],
    );
  }

  Widget _buildPaymentInformation(BuildContext context) {
    String _formatDate(DateTime date) {
      final ethDate = EthiopianCalendar.fromGregorian(date);
      return EthiopianCalendar.formatEthiopian(ethDate);
    }
    
    return _buildSection(
      context,
      title: 'Payment Information',
      icon: Icons.payments,
      iconColor: Colors.green,
      children: [
        _buildInfoTile(
          icon: Icons.account_balance_wallet,
          label: 'Payment Mode',
          value: workType.paymentMode.displayName,
          iconColor: Colors.green[700]!,
        ),
        if (workType.hierarchyLevel >= 5)
          _buildInfoTile(
            icon: Icons.attach_money,
            label: 'Base Rate (Shared for all workers)',
            value: 'ETB ${workType.baseRate.toStringAsFixed(2)}',
            subtitle: 'All ${workType.hierarchyLevel == 5 ? "Operational" : "Trainee"} workers earn this rate',
            iconColor: Colors.amber[700]!,
          )
        else
          _buildInfoTile(
            icon: Icons.stars_rounded,
            label: 'Salary Policy',
            value: 'Individual Salary per Worker',
            subtitle: 'Each worker has their own salary — set during registration',
            iconColor: Colors.amber[700]!,
          ),
        if (workType.paymentPeriodDays != null)
          _buildInfoTile(
            icon: Icons.calendar_today,
            label: 'Payment Period',
            value: '${workType.paymentPeriodDays} days',
            iconColor: Colors.blue[700]!,
          ),
        if (workType.paymentPeriodStartDate != null)
          _buildInfoTile(
            icon: Icons.event,
            label: 'Payment Period Start Date',
            value: _formatDate(workType.paymentPeriodStartDate!),
            subtitle: 'Anchor date for period calculations',
            iconColor: Colors.deepOrange[700]!,
          ),
      ],
    );
  }

  Widget _buildTaxInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Tax & Deductions',
      icon: Icons.receipt_long,
      iconColor: Colors.orange,
      children: [
        _buildInfoTile(
          icon: Icons.gavel,
          label: 'Tax Rule',
          value: workType.taxRule.displayName,
          iconColor: Colors.orange[700]!,
        ),
      ],
    );
  }

  Widget _buildBenefitsInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Benefits & Allowances',
      icon: Icons.card_giftcard,
      iconColor: Colors.teal,
      children: [
        _buildInfoTile(
          icon: Icons.access_time,
          label: 'Overtime Eligible',
          value: workType.overtimeEligible ? 'Yes' : 'No',
          iconColor: workType.overtimeEligible ? Colors.green[700]! : Colors.red[700]!,
        ),
        if (workType.overtimeEligible && workType.overtimeRatePerHour != null)
          _buildInfoTile(
            icon: Icons.monetization_on,
            label: 'Overtime Rate/Hour',
            value: 'ETB ${workType.overtimeRatePerHour!.toStringAsFixed(2)}',
            iconColor: Colors.amber[700]!,
          ),
        _buildInfoTile(
          icon: Icons.savings,
          label: 'Pension Eligible',
          value: workType.pensionEligible ? 'Yes' : 'No',
          iconColor: workType.pensionEligible ? Colors.green[700]! : Colors.red[700]!,
        ),
        if (workType.pensionEligible) ...[
          _buildInfoTile(
            icon: Icons.person,
            label: 'Employee Pension Rate',
            value: '${((workType.employeePensionRate ?? 0) * 100).toStringAsFixed(1)}%',
            iconColor: Colors.indigo[700]!,
          ),
          _buildInfoTile(
            icon: Icons.business,
            label: 'Employer Pension Rate',
            value: '${((workType.employerPensionRate ?? 0) * 100).toStringAsFixed(1)}%',
            iconColor: Colors.deepPurple[700]!,
          ),
        ],
      ],
    );
  }

  Widget _buildHierarchyInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Organizational Hierarchy',
      icon: Icons.stairs,
      iconColor: Colors.deepPurple,
      children: [
        _buildInfoTile(
          icon: Icons.trending_up,
          label: 'Hierarchy Level',
          value: 'Level ${workType.hierarchyLevel}',
          subtitle: getHierarchyLevelName(workType.hierarchyLevel),
          iconColor: Colors.deepPurple[700]!,
        ),
        _buildInfoTile(
          icon: Icons.supervisor_account,
          label: 'Requires Supervisor',
          value: workType.requiresSupervisor ? 'Yes' : 'No',
          subtitle: workType.requiresSupervisor
              ? 'Workers must report to someone'
              : 'Independent role',
          iconColor: workType.requiresSupervisor ? Colors.blue[700]! : Colors.grey[700]!,
        ),
        if (workType.maxSubordinates != null)
          _buildInfoTile(
            icon: Icons.people,
            label: 'Max Subordinates',
            value: '${workType.maxSubordinates}',
            subtitle: 'Maximum direct reports allowed',
            iconColor: Colors.cyan[700]!,
          ),
      ],
    );
  }

  Widget _buildTimestamps(BuildContext context) {
    String _formatDateTime(DateTime date) {
      final ethDate = EthiopianCalendar.fromGregorian(date);
      final timeFormat = DateFormat('hh:mm a');
      return '${EthiopianCalendar.formatEthiopian(ethDate)} - ${timeFormat.format(date)}';
    }
    
    return _buildSection(
      context,
      title: 'Record Information',
      icon: Icons.history,
      iconColor: Colors.grey,
      children: [
        if (workType.createdAt != null)
          _buildInfoTile(
            icon: Icons.add_circle_outline,
            label: 'Created At',
            value: _formatDateTime(workType.createdAt!),
            iconColor: Colors.green[700]!,
          ),
        if (workType.updatedAt != null)
          _buildInfoTile(
            icon: Icons.update,
            label: 'Last Updated',
            value: _formatDateTime(workType.updatedAt!),
            iconColor: Colors.orange[700]!,
          ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
