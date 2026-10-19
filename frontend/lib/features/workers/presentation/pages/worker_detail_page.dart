import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/worker.dart';
import '../../data/datasources/worker_remote_datasource.dart';
import 'worker_form_page.dart';

class WorkerDetailPage extends StatefulWidget {
  final Worker worker;

  const WorkerDetailPage({
    super.key,
    required this.worker,
  });

  @override
  State<WorkerDetailPage> createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends State<WorkerDetailPage> {
  final _datasource = WorkerRemoteDataSource();
  late Worker _worker;

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
  }

  String _generateQRData() {
    return 'WORKER|${_worker.id}|${_worker.employeeId}|${_worker.siteId}';
  }

  Future<void> _editWorker() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerFormPage(worker: _worker),
      ),
    );

    if (result == true && mounted) {
      try {
        final updated = await _datasource.getWorkerById(_worker.id!);
        setState(() => _worker = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Worker details updated successfully'),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        String errorMessage;
        if (e is ApiException) {
          errorMessage = e.displayMessage;
        } else {
          errorMessage = 'Failed to refresh worker details.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage)),
            ]),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _deleteWorker() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C), size: 26),
          SizedBox(width: 10),
          Text('Delete Worker'),
        ]),
        content: Text('Are you sure you want to permanently delete ${_worker.fullName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _datasource.deleteWorker(_worker.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('${_worker.fullName} has been removed.'),
              ]),
              backgroundColor: const Color(0xFF007A3D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage;
          if (e is ApiException) {
            errorMessage = e.displayMessage;
          } else {
            errorMessage = 'Failed to delete worker. Please try again.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMessage)),
              ]),
              backgroundColor: const Color(0xFFB71C1C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(label: 'Dismiss', textColor: Colors.white, onPressed: () {}),
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleActiveStatus() async {
    final newStatus = _worker.isActive ? 'inactive' : 'active';
    final updated = Worker(
      id: _worker.id,
      employeeId: _worker.employeeId,
      fullName: _worker.fullName,
      phoneNumber: _worker.phoneNumber,
      siteId: _worker.siteId,
      workPlaceId: _worker.workPlaceId,
      workTypeId: _worker.workTypeId,
      status: newStatus,
      bankName: _worker.bankName,
      bankAccountNumber: _worker.bankAccountNumber,
      hireDate: _worker.hireDate,
      overtimeHours: _worker.overtimeHours,
      overtimeRatePerHour: _worker.overtimeRatePerHour,
      supervisorId: _worker.supervisorId,
      baseSalary: _worker.baseSalary, // preserve individual salary
    );

    try {
      await _datasource.updateWorker(updated);
      setState(() => _worker = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(newStatus == 'active' ? 'Worker activated' : 'Worker deactivated'),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e is ApiException) {
          errorMessage = e.displayMessage;
        } else {
          errorMessage = 'Failed to update worker status. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage)),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Worker'),
              onTap: () {
                Navigator.pop(context);
                _editWorker();
              },
            ),
            ListTile(
              leading: Icon(_worker.isActive ? Icons.block : Icons.check_circle),
              title: Text(_worker.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _toggleActiveStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate QR Code'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: const Color(0xFFB71C1C)),
              title: const Text('Delete Worker', style: TextStyle(color: const Color(0xFFB71C1C))),
              onTap: () {
                Navigator.pop(context);
                _deleteWorker();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_worker.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editWorker,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    const Color(0xB3007A3D),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      _worker.fullName.isNotEmpty ? _worker.fullName.substring(0, 1).toUpperCase() : 'W',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _worker.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${_worker.employeeId}',
                    style: const TextStyle(
                      color: const Color(0xB3FFFFFF),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _worker.isActive
                          ? const Color(0x33007A3D)
                          : const Color(0x4D9CA3AF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _worker.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.scanQrCode ?? 'QR Code',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: QrImageView(
                              data: _generateQRData(),
                              version: QrVersions.auto,
                              size: 200,
                              gapless: false,
                              errorStateBuilder: (cxt, err) {
                                return const Center(
                                  child: Text(
                                    'QR Code Error',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Scan for attendance',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations?.fullName ?? 'Worker Information',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.badge,
                    title: localizations?.employeeId ?? 'Employee ID',
                    value: _worker.employeeId,
                  ),
                  if (_worker.phoneNumber != null)
                    _InfoCard(
                      icon: Icons.phone,
                      title: localizations?.phoneNumber ?? 'Phone',
                      value: _worker.phoneNumber!,
                    ),
                  _InfoCard(
                    icon: Icons.location_on,
                    title: localizations?.site ?? 'Site',
                    value: _worker.siteName ?? 'Site ${_worker.siteId}',
                  ),
                  if (_worker.workPlaceName != null)
                    _InfoCard(
                      icon: Icons.business,
                      title: 'Work Place',
                      value: _worker.workPlaceName!,
                    ),
                  if (_worker.workType != null)
                    _InfoCard(
                      icon: Icons.work,
                      title: localizations?.workType ?? 'Work Type',
                      value: _worker.workType!,
                    ),
                  // Individual base salary — shown only for hierarchy 1-4 workers
                  if (_worker.baseSalary != null && _worker.baseSalary! > 0)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFFFF3E0), const Color(0xFFFFF3E0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFB74D)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCC80),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.stars_rounded, color: const Color(0xFFE65100), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Individual Base Salary',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFFE65100),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ETB ${_worker.baseSalary!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF701700),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Personal salary — overrides Work Type rate in payroll',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFFA52800),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_worker.supervisorId != null || _worker.supervisorName != null)
                    _SupervisorCard(
                      supervisorId: _worker.supervisorId,
                      supervisorName: _worker.supervisorName,
                      datasource: _datasource,
                      iconColor: Theme.of(context).primaryColor,
                    ),
                  if (_worker.bankAccountNumber != null)
                    _BankInfoCard(
                      bankName: _worker.bankName,
                      accountNumber: _worker.bankAccountNumber!,
                    ),
                  if (_worker.tinNumber != null)
                    _InfoCard(
                      icon: Icons.numbers,
                      title: 'TIN Number',
                      value: _worker.tinNumber!,
                    ),
                  if (_worker.hireDate != null)
                    _InfoCard(
                      icon: Icons.calendar_today,
                      title: 'Hire Date',
                      value: '${_worker.hireDate!.day}/${_worker.hireDate!.month}/${_worker.hireDate!.year}',
                    ),
                  if ((_worker.overtimeHours ?? 0) > 0 || (_worker.overtimeRatePerHour ?? 0) > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Overtime Configuration',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFE8F5EE), const Color(0xFFE8F5EE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, color: const Color(0xFF005C2E), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Monthly Hours',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF003D1F),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(_worker.overtimeHours ?? 0).toStringAsFixed(2)} hrs',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF003D1F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: const Color(0xFF66B28A),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.payments, color: const Color(0xFF005C2E), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Hourly Rate',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF003D1F),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ETB ${(_worker.overtimeRatePerHour ?? 0).toStringAsFixed(2)}/hr',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF003D1F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005C2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calculate, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Text(
                                        'Monthly Overtime Payment',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(0xB3FFFFFF),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ETB ${_worker.totalOvertimePayment.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _editWorker,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Print QR'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
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
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Theme.of(context).primaryColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color.fromARGB(26, effectiveIconColor.red, effectiveIconColor.green, effectiveIconColor.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

class _SupervisorCard extends StatefulWidget {
  final int? supervisorId;
  final String? supervisorName;
  final WorkerRemoteDataSource datasource;
  final Color? iconColor;

  const _SupervisorCard({
    this.supervisorId,
    this.supervisorName,
    required this.datasource,
    this.iconColor,
  });

  @override
  State<_SupervisorCard> createState() => _SupervisorCardState();
}

class _SupervisorCardState extends State<_SupervisorCard> {
  Worker? _supervisor;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.supervisorId != null) {
      _loadSupervisor();
    }
  }

  Future<void> _loadSupervisor() async {
    setState(() => _loading = true);
    try {
      final supervisor = await widget.datasource.getWorkerById(widget.supervisorId!);
      if (mounted) {
        setState(() {
          _supervisor = supervisor;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  String _getHierarchyBadge(String? workType) {
    if (workType == null) return '';
    
    final lowerType = workType.toLowerCase();
    if (lowerType.contains('executive') || lowerType.contains('ceo') || lowerType.contains('director')) {
      return '⭐⭐⭐';
    } else if (lowerType.contains('manager') || lowerType.contains('head')) {
      return '⭐⭐';
    } else if (lowerType.contains('lead') || lowerType.contains('coordinator')) {
      return '⭐';
    } else if (lowerType.contains('supervisor') || lowerType.contains('foreman')) {
      return '👤';
    }
    return '•';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.iconColor ?? Theme.of(context).primaryColor;
    
    if (_loading) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(26, effectiveColor.red, effectiveColor.green, effectiveColor.blue),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.supervisor_account,
                  color: effectiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supervisor / Manager',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = _supervisor?.fullName ?? widget.supervisorName ?? 'Unknown';
    final workType = _supervisor?.workType;
    final employeeId = _supervisor?.employeeId;
    final hierarchyBadge = _getHierarchyBadge(workType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color.fromARGB(26, effectiveColor.red, effectiveColor.green, effectiveColor.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.supervisor_account,
                color: effectiveColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supervisor / Manager',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hierarchyBadge.isNotEmpty) ...[
                        Text(
                          hierarchyBadge,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (employeeId != null || workType != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (employeeId != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(26, effectiveColor.red, effectiveColor.green, effectiveColor.blue),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              employeeId,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color.fromARGB(204, effectiveColor.red, effectiveColor.green, effectiveColor.blue),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        if (employeeId != null && workType != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (workType != null)
                          Flexible(
                            child: Text(
                              workType,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _BankInfoCard extends StatelessWidget {
  final String? bankName;
  final String accountNumber;

  const _BankInfoCard({
    this.bankName,
    required this.accountNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x1A007A3D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance,
                color: const Color(0xFF007A3D),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bankName != null) ...[
                    Text(
                      bankName!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Bank Account',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAccountNumber(accountNumber),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
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

  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    
    final buffer = StringBuffer();
    for (int i = 0; i < accountNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(accountNumber[i]);
    }
    return buffer.toString();
  }
}


