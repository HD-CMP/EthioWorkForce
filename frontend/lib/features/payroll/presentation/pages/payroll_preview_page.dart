import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../workers/domain/entities/site.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../workers/domain/entities/work_type.dart';
import '../../../workers/data/datasources/worker_remote_datasource.dart';
import '../../../workers/data/datasources/work_type_remote_datasource.dart';
import '../../../attendance/data/datasources/attendance_remote_datasource.dart';
import '../../../attendance/domain/entities/attendance.dart';
import '../../../attendance/presentation/widgets/worker_hierarchy_node.dart';
import '../../../overtime/data/datasources/overtime_remote_datasource.dart';
import '../../data/datasources/payroll_remote_datasource.dart';
import 'payroll_calculation_page.dart';

class WorkerEarnings {
  final Worker worker;
  final int daysWorked;
  final double regularHours;
  final double overtimeHours;
  final double estimatedGross;
  final double estimatedNet;

  WorkerEarnings({
    required this.worker,
    required this.daysWorked,
    required this.regularHours,
    required this.overtimeHours,
    required this.estimatedGross,
    required this.estimatedNet,
  });
}

class WorkTypePeriod {
  final DateTime start;
  final DateTime end;

  WorkTypePeriod(this.start, this.end);
}

class PayrollPreviewPage extends StatefulWidget {
  final Site site;

  const PayrollPreviewPage({
    super.key,
    required this.site,
  });

  @override
  State<PayrollPreviewPage> createState() => _PayrollPreviewPageState();
}

class _PayrollPreviewPageState extends State<PayrollPreviewPage> {
  final WorkerRemoteDataSource _workerDataSource = WorkerRemoteDataSource();
  final WorkTypeRemoteDataSource _workTypeDataSource = WorkTypeRemoteDataSource();
  final AttendanceRemoteDataSource _attendanceDataSource = AttendanceRemoteDataSource();
  final PayrollRemoteDataSource _payrollDataSource = PayrollRemoteDataSource();
  final OvertimeRemoteDataSource _overtimeDataSource = OvertimeRemoteDataSource();
  
  Map<String, List<WorkerEarnings>> _workersByWorkPlace = {};
  Map<int, WorkType> _workTypeMap = {};
  List<WorkType> _workTypes = [];
  Map<int, WorkTypePeriod> _workTypePeriods = {};
  List<String> _workPlaces = [];
  String? _selectedWorkPlace;
  bool _isLoading = false;
  String? _errorMessage;
  final Set<int> _expandedWorkerIds = {};
  final Set<String> _expandedWorkPlaces = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime _calculatePeriodStart(WorkType workType, DateTime now) {
    if (workType.paymentPeriodStartDate != null && workType.paymentPeriodDays != null) {
      final startDate = workType.paymentPeriodStartDate!;
      final periodDays = workType.paymentPeriodDays!;
      
      final daysSinceStart = now.difference(startDate).inDays;
      final periodsElapsed = daysSinceStart ~/ periodDays;
      
      return startDate.add(Duration(days: periodsElapsed * periodDays));
    }
    
    return now.subtract(const Duration(days: 30));
  }

  String _formatEthiopianPeriod(DateTime start, DateTime end) {
    final ethStart = EthiopianCalendar.fromGregorian(start);
    final ethEnd = EthiopianCalendar.fromGregorian(end);
    
    final startMonth = EthiopianCalendar.monthsEnglish[ethStart.month - 1];
    final endMonth = EthiopianCalendar.monthsEnglish[ethEnd.month - 1];
    
    return '$startMonth ${ethStart.day} - $endMonth ${ethEnd.day}, ${ethEnd.year}';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workTypes = await _workTypeDataSource.getWorkTypes(isActive: true);
      final workers = await _workerDataSource.getWorkers(
        siteId: widget.site.id!,
        status: 'active',
      );

      final now = DateTime.now();
      
      _workTypeMap = {for (var wt in workTypes) wt.id!: wt};
      
      final Map<int, WorkTypePeriod> periods = {};
      for (var workType in workTypes) {
        final periodStart = _calculatePeriodStart(workType, now);
        periods[workType.id!] = WorkTypePeriod(periodStart, now);
      }
      
      final earliestPeriodStart = periods.values.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
      
      final attendances = await _attendanceDataSource.getAttendances(
        siteId: widget.site.id!,
        dateFrom: earliestPeriodStart,
        dateTo: now,
        isVerified: true,
        limit: 1000,
      );

      final Map<int, List<Attendance>> attendancesByWorker = {};
      for (var a in attendances) {
        attendancesByWorker.putIfAbsent(a.workerId, () => []).add(a);
      }

      final overtimeRecords = await _overtimeDataSource.getOvertimes(
        siteId: widget.site.id!,
        dateFrom: earliestPeriodStart,
        dateTo: now,
        isVerified: true,
      );

      final Map<int, double> workerOvertimeLookup = {};
      for (final ot in overtimeRecords) {
        workerOvertimeLookup[ot.workerId] =
            (workerOvertimeLookup[ot.workerId] ?? 0.0) + ot.hours;
      }

      final Map<String, List<WorkerEarnings>> grouped = {};

      for (var worker in workers) {
        if (worker.workTypeId == null) continue;
        
        final workType = workTypes.firstWhere(
          (wt) => wt.id == worker.workTypeId,
          orElse: () => throw Exception('WorkType not found for worker ${worker.id}'),
        );

        final workerAttendances = attendancesByWorker[worker.id] ?? [];
        final verifiedOvertimeHours = workerOvertimeLookup[worker.id] ?? 0.0;
        final earnings = _calculateWorkerEarnings(worker, workerAttendances, verifiedOvertimeHours);
        
        final wp = worker.workPlaceName ?? 'General Workforce';
        grouped.putIfAbsent(wp, () => []).add(earnings);
      }

      if (mounted) {
        setState(() {
          _workTypes = workTypes;
          _workTypeMap = {for (var wt in workTypes) wt.id!: wt};
          _workPlaces = grouped.keys.toList()..sort();
          _workersByWorkPlace = grouped;
          _workTypePeriods = periods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load payroll data: ${e.toString()}';
        });
      }
    }
  }

  double _estimateIncomeTax(double grossSalary) {
    if (grossSalary <= 0) return 0;
    
    final taxBrackets = [
      (0.0, 600.0, 0.0),
      (600.0, 1650.0, 0.10),
      (1650.0, 3200.0, 0.15),
      (3200.0, 5250.0, 0.20),
      (5250.0, 7800.0, 0.25),
      (7800.0, 10900.0, 0.30),
      (10900.0, double.infinity, 0.35),
    ];
    
    double tax = 0;
    double remainingIncome = grossSalary;
    
    for (var i = 0; i < taxBrackets.length; i++) {
      if (remainingIncome <= 0) break;
      
      final (lower, upper, rate) = taxBrackets[i];
      final taxableInBracket = (remainingIncome).clamp(0.0, upper - lower);
      final bracketTax = taxableInBracket * rate;
      
      tax += bracketTax;
      remainingIncome -= taxableInBracket;
    }
    
    return tax;
  }

  WorkerEarnings _calculateWorkerEarnings(
    Worker worker,
    List<Attendance> attendances,
    double verifiedOvertimeHours,
  ) {
    int daysWorked = 0;
    double regularHours = 0;

    for (var attendance in attendances) {
      if (attendance.status == 'present' ||
          attendance.status == 'late' ||
          attendance.status == 'excused') {
        daysWorked++;
        regularHours += attendance.regularHours;
      }
    }

    final workType = _workTypeMap[worker.workTypeId];
    double estimatedGross = 0;

    if (workType != null) {
      final effectiveBaseRate =
          (worker.baseSalary != null && worker.baseSalary! > 0)
              ? worker.baseSalary!
              : workType.baseRate;

      switch (workType.paymentMode) {
        case PaymentMode.monthlySalary:
          final period = _workTypePeriods[worker.workTypeId];
          int totalWorkingDays = 0;
          if (period != null) {
            DateTime d = period.start;
            while (!d.isAfter(period.end)) {
              if (d.weekday != DateTime.sunday) totalWorkingDays++;
              d = d.add(const Duration(days: 1));
            }
          }
          if (totalWorkingDays > 0 && daysWorked < totalWorkingDays) {
            estimatedGross =
                (effectiveBaseRate / totalWorkingDays) * daysWorked;
          } else {
            estimatedGross = effectiveBaseRate;
          }
          break;

        case PaymentMode.dailyRate:
          estimatedGross = effectiveBaseRate * daysWorked;
          break;

        case PaymentMode.hourlyRate:
          estimatedGross = effectiveBaseRate * regularHours;
          break;

        case PaymentMode.pieceRate:
          estimatedGross = effectiveBaseRate * daysWorked;
          break;
      }

      if (workType.overtimeEligible && verifiedOvertimeHours > 0) {
        final overtimeRate = workType.overtimeRatePerHour ?? 0.0;
        estimatedGross += verifiedOvertimeHours * overtimeRate;
      }
    }

    double estimatedDeductions = 0;
    if (workType != null) {
      if (workType.taxRule == TaxRule.dailyCasual) {
        estimatedDeductions = 0;
      } else {
        double incomeTax = _estimateIncomeTax(estimatedGross);
        double pensionDeduction = 0;
        if (workType.pensionEligible && workType.employeePensionRate != null) {
          pensionDeduction = estimatedGross * workType.employeePensionRate!;
        }
        estimatedDeductions = incomeTax + pensionDeduction;
      }
    }

    return WorkerEarnings(
      worker: worker,
      daysWorked: daysWorked,
      regularHours: regularHours,
      overtimeHours: verifiedOvertimeHours,
      estimatedGross: estimatedGross,
      estimatedNet: estimatedGross - estimatedDeductions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payroll Preview - ${widget.site.name}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                          Row(
                            children: [
                              const Icon(Icons.preview, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Real-Time Payroll Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: [
                              _buildWorkPlaceChip(
                                'All',
                                null,
                                _workersByWorkPlace.values.fold(0, (sum, list) => sum + list.length),
                              ),
                              const SizedBox(width: 8),
                              ..._workPlaces.map((workPlace) {
                                final count = _workersByWorkPlace[workPlace]?.length ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildWorkPlaceChip(
                                    workPlace,
                                    workPlace,
                                    count,
                                  ),
                                );
                              }),
                            ],
                          ),
                      ),
                    ),
                    ..._buildWorkersList(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PayrollCalculationPage(site: widget.site),
            ),
          );
        },
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate Payroll'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildWorkPlaceChip(String label, String? workPlace, int count) {
    final isSelected = _selectedWorkPlace == workPlace;
    
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedWorkPlace = selected ? workPlace : null;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  List<Widget> _buildWorkersList() {
    List<MapEntry<String, List<WorkerEarnings>>> entries;
    
    if (_selectedWorkPlace == null) {
      entries = _workersByWorkPlace.entries.toList();
    } else {
      entries = [
        MapEntry(_selectedWorkPlace!, _workersByWorkPlace[_selectedWorkPlace] ?? [])
      ];
    }

    if (entries.isEmpty || entries.every((e) => e.value.isEmpty)) {
      return [
        Padding(
          padding: const EdgeInsets.all(48.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No workers found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        )
      ];
    }

    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final List<Widget> widgets = [];

    for (var entry in entries) {
      final workPlace = entry.key;
      final workers = entry.value;

      if (workers.isEmpty) continue;

      final totalGross = workers.fold(0.0, (sum, w) => sum + w.estimatedGross);
      final totalNet = workers.fold(0.0, (sum, w) => sum + w.estimatedNet);
      final groupName = workPlace;
      final isExpanded = _expandedWorkPlaces.contains(groupName);

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkPlaceHeader(groupName, workers.length, isExpanded),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              ...workers.map((workerEarning) {
                final wt = _workTypeMap[workerEarning.worker.workTypeId];
                return _buildWorkerCard(workerEarning, wt, currencyFormat);
              }),
              const SizedBox(height: 24),
            ],
          ],
        )
      );
    }
    
    widgets.add(const SizedBox(height: 80)); // Padding for FAB

    return widgets;
  }

  Widget _buildWorkPlaceHeader(String workPlaceName, int count, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedWorkPlaces.remove(workPlaceName);
          } else {
            _expandedWorkPlaces.add(workPlaceName);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[700]!, Colors.teal[500]!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                workPlaceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.teal[700],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(WorkerEarnings earnings, WorkType? workType, NumberFormat currencyFormat) {
    final worker = earnings.worker;
    final isExpanded = _expandedWorkerIds.contains(worker.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedWorkerIds.remove(worker.id);
              } else {
                _expandedWorkerIds.add(worker.id!);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Text(
                        worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : 'W',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  worker.fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(earnings.estimatedNet),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              if (isExpanded) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      worker.employeeId,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (worker.supervisorName != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Reports to: ${worker.supervisorName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Days Worked',
                        '${earnings.daysWorked}',
                        Icons.calendar_today,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Regular Hrs',
                        earnings.regularHours.toStringAsFixed(1),
                        Icons.access_time,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Overtime Hrs',
                        earnings.overtimeHours.toStringAsFixed(1),
                        Icons.timer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gross Earnings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(earnings.estimatedGross),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Net Pay (Est.)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(earnings.estimatedNet),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
