import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/payment_period.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../overtime/domain/entities/overtime.dart';
import '../../../overtime/data/datasources/overtime_remote_datasource.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../core/utils/app_snackbar.dart';

class MultiDayOvertimeSelector extends StatefulWidget {
  final Worker worker;
  final DateTime startDate;
  final List<Overtime> existingOvertimes;
  final int siteId;
  final Future<void> Function(Map<DateTime, double> overtimeData)? onSave;
  final String mode;

  const MultiDayOvertimeSelector({
    super.key,
    required this.worker,
    required this.startDate,
    required this.existingOvertimes,
    required this.siteId,
    this.onSave,
    this.mode = 'entry',
  });

  @override
  State<MultiDayOvertimeSelector> createState() => _MultiDayOvertimeSelectorState();
}

class _MultiDayOvertimeSelectorState extends State<MultiDayOvertimeSelector> {
  final Map<DateTime, double> _overtimeData = {};
  final Map<DateTime, TextEditingController> _controllers = {};
  final Set<DateTime> _selectedDates = {};
  final _overtimeDataSource = OvertimeRemoteDataSource();
  final _attendanceDataSource = AttendanceRemoteDataSource();
  
  PaymentPeriod? _paymentPeriod;
  bool _isLoadingPeriod = true;
  int _periodOffset = 0;
  bool _showEthiopianCalendar = true;
  
  int get _paymentPeriodDays => _paymentPeriod?.periodDays ?? widget.worker.paymentPeriodDays ?? 14;
  
  DateTime get _periodStart {
    final baseStart = _paymentPeriod?.periodStart ?? widget.startDate;
    return baseStart.add(Duration(days: _periodOffset * _paymentPeriodDays));
  }
  
  DateTime get _periodEnd => _periodStart.add(Duration(days: _paymentPeriodDays - 1));

  bool get _hasFutureDates {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    return _periodEnd.isAfter(todayNormalized);
  }

  @override
  void initState() {
    super.initState();
    _fetchPaymentPeriod();
  }

  @override
  void didUpdateWidget(MultiDayOvertimeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingOvertimes != widget.existingOvertimes) {
      _overtimeData.clear();
      _initializeOvertimeData();
    }
  }

  Future<void> _fetchPaymentPeriod() async {
    if (widget.worker.id == null) {
      setState(() => _isLoadingPeriod = false);
      _initializeOvertimeData();
      return;
    }

    try {
      final periodData = await _attendanceDataSource.getWorkerPaymentPeriod(
        workerId: widget.worker.id!,
        referenceDate: widget.startDate,
      );

      if (periodData != null && mounted) {
        setState(() {
          _paymentPeriod = PaymentPeriod.fromJson(periodData);
          _isLoadingPeriod = false;
        });
        _initializeOvertimeData();
      } else {
        setState(() => _isLoadingPeriod = false);
        _initializeOvertimeData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPeriod = false);
        _initializeOvertimeData();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeOvertimeData() {
    if (mounted) {
      setState(() {
        debugPrint('?? Initializing overtime data for worker ${widget.worker.id}');
        debugPrint('?? Existing overtimes: ${widget.existingOvertimes.length}');
        for (final ot in widget.existingOvertimes) {
          debugPrint('   - ${ot.overtimeDate.toIso8601String().split('T')[0]}: hours=${ot.hours}h');
        }
        
        _overtimeData.clear();
        for (int i = 0; i < _paymentPeriodDays; i++) {
          final date = _periodStart.add(Duration(days: i));
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final overtime = _getOvertime(date);
          
          if (overtime != null && overtime.hours > 0) {
            debugPrint('? Found overtime: ${overtime.overtimeDate} = ${overtime.hours}h');
            _overtimeData[normalizedDate] = overtime.hours;
          }
        }
        debugPrint('?? Initialized overtime data: ${_overtimeData.length} days');
      });
    }
  }

  Overtime? _getOvertime(DateTime date) {
    try {
      return widget.existingOvertimes.firstWhere((o) => 
        o.overtimeDate.year == date.year &&
        o.overtimeDate.month == date.month &&
        o.overtimeDate.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  void _updateOvertimeForDate(DateTime date, double hours) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (hours > 0) {
        _overtimeData[normalizedDate] = hours;
      } else {
        _overtimeData.remove(normalizedDate);
      }
    });
  }

  void _toggleDate(DateTime date) {
    if (widget.mode == 'verify') {
      setState(() {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (_selectedDates.contains(normalizedDate)) {
          _selectedDates.remove(normalizedDate);
        } else {
          _selectedDates.add(normalizedDate);
        }
      });
    }
  }

  void _selectAll() {
    if (widget.mode == 'verify') {
      setState(() {
        _selectedDates.clear();
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        
        for (int i = 0; i < _paymentPeriodDays; i++) {
          final date = _periodStart.add(Duration(days: i));
          
          if (date.isAfter(todayNormalized)) break;
          
          final normalizedDate = DateTime(date.year, date.month, date.day);
          if (_overtimeData.containsKey(normalizedDate) && _overtimeData[normalizedDate]! > 0) {
            _selectedDates.add(normalizedDate);
          }
        }
      });
    }
  }

  void _clearAllSelection() {
    if (widget.mode == 'verify') {
      setState(() {
        _selectedDates.clear();
      });
    }
  }

  Future<void> _confirmAndSave() async {
    if (widget.mode == 'verify') {
      if (_selectedDates.isEmpty) {
        AppSnackBar.showWarning(context, 'No days selected for verification');
        return;
      }
    } else {
      if (_overtimeData.isEmpty) {
        AppSnackBar.showWarning(context, 'No overtime hours entered');
        return;
      }
    }

    final totalHours = widget.mode == 'verify'
        ? _selectedDates.fold<double>(0.0, (sum, date) => sum + (_overtimeData[date] ?? 0.0))
        : _overtimeData.values.fold<double>(0.0, (sum, hours) => sum + hours);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.mode == 'verify' ? Icons.verified : Icons.access_time,
              color: widget.mode == 'verify' ? const Color(0xFF005C2E) : const Color(0xFFE65100),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(widget.mode == 'verify' ? 'Confirm Overtime Verification' : 'Confirm Overtime'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mode == 'verify'
                  ? 'You are about to verify overtime for:'
                  : 'You are about to save overtime hours for:',
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: const Color(0xFF374151)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.worker.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: const Color(0xFF374151)),
                      const SizedBox(width: 8),
                      Text(
                        widget.mode == 'verify'
                            ? '${_selectedDates.length} day${_selectedDates.length != 1 ? 's' : ''}'
                            : '${_overtimeData.length} day${_overtimeData.length != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: const Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Text(
                        '$totalHours total hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFBF360C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.mode == 'verify' ? const Color(0xFFE8F5EE) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.mode == 'verify' ? const Color(0xFFB2DFCA) : const Color(0xFFFFCC80),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: widget.mode == 'verify' ? const Color(0xFF005C2E) : const Color(0xFFE65100),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.mode == 'verify'
                          ? 'Verification confirms overtime accuracy for payroll processing.'
                          : 'Overtime hours will affect payroll calculations. Please verify before confirming.',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.mode == 'verify' ? const Color(0xFF003D1F) : const Color(0xFFBF360C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.mode == 'verify' ? const Color(0xFF007A3D) : const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
            child: Text(widget.mode == 'verify' ? 'Verify' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (widget.mode == 'verify') {
          final verifyData = <DateTime, double>{};
          final overtimeIds = <int>[];
          
          for (final date in _selectedDates) {
            verifyData[date] = _overtimeData[date] ?? 0.0;
            final ot = _getOvertime(date);
            if (ot != null && ot.id != null) {
              overtimeIds.add(ot.id!);
            }
          }
          
          if (overtimeIds.isNotEmpty) {
            await _overtimeDataSource.verifyOvertimes(
              siteId: widget.siteId,
              overtimeIds: overtimeIds,
            );
          }
          
          if (widget.onSave != null) {
            await widget.onSave!(verifyData);
          }
        } else {
          // Entry mode - save multi-day overtime records
          await _overtimeDataSource.createMultiDayOvertime(
            workerId: widget.worker.id!,
            siteId: widget.siteId,
            overtimeData: _overtimeData,
            verify: false,
          );
          
          if (widget.onSave != null) {
            await widget.onSave!(_overtimeData);
          }
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Error saving overtime: $e');
        }
      }
    }
  }

  void _clearAll() {
    setState(() {
      _overtimeData.clear();
      for (var controller in _controllers.values) {
        controller.clear();
      }
    });
  }

  void _goToPreviousPeriod() {
    setState(() {
      _periodOffset--;
      _selectedDates.clear();
      _overtimeData.clear();
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _initializeOvertimeData();
    });
  }

  void _goToNextPeriod() {
    setState(() {
      _periodOffset++;
      _selectedDates.clear();
      _overtimeData.clear();
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _initializeOvertimeData();
    });
  }

  void _goToToday() {
    setState(() {
      _periodOffset = 0;
      _selectedDates.clear();
      _overtimeData.clear();
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _initializeOvertimeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _overtimeData.values.fold<double>(0.0, (sum, hours) => sum + hours);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.mode == 'verify' ? Icons.verified : Icons.access_time, 
                          color: widget.mode == 'verify' ? const Color(0xFF005C2E) : const Color(0xFFE65100), 
                          size: 24
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.mode == 'verify' ? 'Overtime Verification' : 'Overtime Entry',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.worker.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${widget.worker.employeeId} � ${widget.worker.workType ?? 'No work type'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {
                  setState(() {
                    _showEthiopianCalendar = !_showEthiopianCalendar;
                  });
                },
                tooltip: 'Toggle Calendar Type',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: 24),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.mode == 'verify' ? const Color(0xFFE8F5EE) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.mode == 'verify' ? const Color(0xFFB2DFCA) : const Color(0xFFFFCC80), 
                width: 1
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline, 
                  color: widget.mode == 'verify' ? const Color(0xFF005C2E) : const Color(0xFFE65100), 
                  size: 20
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.mode == 'verify'
                        ? 'Showing $_paymentPeriodDays-day payment period. Select days with overtime to verify.'
                        : 'Showing $_paymentPeriodDays-day payment period. Click dates to enter overtime (0-24 hours).',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.mode == 'verify' ? const Color(0xFF003D1F) : const Color(0xFFBF360C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasFutureDates)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: const Color(0xFF6B7280), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Future dates (grayed out) cannot be edited. Overtime can only be entered up to today.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.mode == 'verify'
                    ? '${_selectedDates.length} selected � ${_selectedDates.fold<double>(0.0, (sum, date) => sum + (_overtimeData[date] ?? 0.0))} hours'
                    : '${_overtimeData.length} day${_overtimeData.length != 1 ? 's' : ''} � $totalHours hours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.mode == 'verify' ? const Color(0xFF005C2E) : const Color(0xFFBF360C),
                ),
              ),
              if (widget.mode == 'verify')
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _selectAll,
                      icon: const Icon(Icons.select_all, size: 18),
                      label: const Text('Select All'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: _selectedDates.isEmpty ? null : _clearAllSelection,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: _overtimeData.isEmpty ? null : _clearAll,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildPeriodNavigator(),
          
          const SizedBox(height: 16),
          
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _paymentPeriodDays == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No available dates',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No payment period configured',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _paymentPeriodDays,
                      itemBuilder: (context, index) {
                  final date = _periodStart.add(Duration(days: index));
                  final normalizedDate = DateTime(date.year, date.month, date.day);
                  final overtime = _getOvertime(date);
                  final overtimeHours = _overtimeData[normalizedDate] ?? 0;
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

                  return _buildDateCard(
                    date: date,
                    overtime: overtime,
                    overtimeHours: overtimeHours,
                    isToday: isToday,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.mode == 'verify'
                      ? (_selectedDates.isEmpty ? null : _confirmAndSave)
                      : (_overtimeData.isEmpty ? null : _confirmAndSave),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: widget.mode == 'verify' ? const Color(0xFF007A3D) : const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    disabledForegroundColor: const Color(0xFF6B7280),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.mode == 'verify' ? Icons.verified : Icons.save,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.mode == 'verify'
                            ? (_selectedDates.isEmpty
                                ? 'No Selection'
                                : 'Verify ${_selectedDates.length} Day${_selectedDates.length != 1 ? 's' : ''}')
                            : (_overtimeData.isEmpty
                                ? 'No Overtime'
                                : 'Save ${_overtimeData.length} Day${_overtimeData.length != 1 ? 's' : ''}'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required DateTime date,
    required Overtime? overtime,
    required double overtimeHours,
    required bool isToday,
  }) {
    final dayName = DateFormat('EEE').format(date);
    final dayNumber = _showEthiopianCalendar 
        ? EthiopianCalendar.fromGregorian(date).day 
        : date.day;
    
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final isFutureDate = date.isAfter(todayNormalized);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isSelected = _selectedDates.contains(normalizedDate);

    Color borderColor;
    Color backgroundColor;
    Color textColor;

    if (isFutureDate) {
      borderColor = const Color(0xFFE5E7EB);
      backgroundColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF9CA3AF);
    } else if (widget.mode == 'verify' && isSelected) {
      borderColor = const Color(0xFF005C2E);
      backgroundColor = const Color(0xFFE8F5EE);
      textColor = const Color(0xFF003D1F);
    } else if (overtime?.isVerified == true && overtimeHours > 0) {
      borderColor = const Color(0xFF005C2E);
      backgroundColor = const Color(0xFFE8F5EE);
      textColor = const Color(0xFF003D1F);
    } else if (overtimeHours > 0) {
      borderColor = const Color(0xFFE65100);
      backgroundColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFBF360C);
    } else {
      borderColor = const Color(0xFFD1D5DB);
      backgroundColor = Colors.white;
      textColor = const Color(0xFF1F2937);
    }

    final hasOvertime = overtimeHours > 0;
    final isOvertimeLocked = overtime?.isLocked == true;
    final canInteract = !isFutureDate && !isOvertimeLocked && (widget.mode == 'entry' || hasOvertime);

    return InkWell(
      onTap: !canInteract ? null : () {
        if (widget.mode == 'verify') {
          _toggleDate(date);
        } else {
          _showOvertimeDialog(date, overtimeHours);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: (isSelected || overtimeHours > 0) ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isToday)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: widget.mode == 'verify' ? const Color(0xFF007A3D) : const Color(0xFFE65100),
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(179, textColor.red, textColor.green, textColor.blue),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (isFutureDate) ...[
                  const SizedBox(height: 2),
                  Icon(
                    Icons.block,
                    size: 14,
                    color: textColor,
                  ),
                ] else if (overtimeHours > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overtime?.isVerified == true) ...[
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: const Color(0xFF005C2E),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Text(
                        '${overtimeHours}h',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.mode == 'verify' && isSelected ? const Color(0xFF005C2E) : const Color(0xFFBF360C),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (widget.mode == 'verify' && hasOvertime && isSelected)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005C2E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOvertimeDialog(DateTime date, double currentHours) {
    final controller = TextEditingController(text: currentHours > 0 ? currentHours.toString() : '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.access_time, color: const Color(0xFFE65100), size: 24),
            const SizedBox(width: 12),
            const Text('Enter Overtime'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showEthiopianCalendar
                  ? () {
                      final ethiopianDate = EthiopianCalendar.fromGregorian(date);
                      final weekday = date.weekday;
                      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                      return '${weekdays[weekday - 1]}, ${EthiopianCalendar.formatEthiopian(ethiopianDate)}';
                    }()
                  : DateFormat('EEEE, MMMM d, y').format(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Overtime Hours',
                hintText: 'Enter hours (e.g., 1.5)',
                suffixText: 'hours',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFE65100), width: 2),
                ),
              ),
              onSubmitted: (value) {
                final hours = double.tryParse(value) ?? 0.0;
                if (hours >= 0 && hours <= 24) {
                  _updateOvertimeForDate(date, hours);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Valid range: 0-24 hours',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            if (widget.worker.overtimeRatePerHour == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: const Color(0xFFBF360C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Overtime rate not configured. Fallback calculation (1.5x base rate) will be used.',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFFBF360C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (currentHours > 0)
            TextButton(
              onPressed: () {
                _updateOvertimeForDate(date, 0);
                Navigator.pop(context);
              },
              child: Text(
                'Clear',
                style: TextStyle(color: const Color(0xFFB71C1C)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hours = double.tryParse(controller.text) ?? 0.0;
              if (hours >= 0 && hours <= 24) {
                _updateOvertimeForDate(date, hours);
                Navigator.pop(context);
              } else {
                AppSnackBar.showError(context, 'Please enter a value between 0 and 24');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodNavigator() {
    final bool canGoNext = _periodOffset < 0;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final isCurrentPeriod = _periodOffset == 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousPeriod,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Period',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF007A3D),
              padding: const EdgeInsets.all(12),
            ),
          ),
          
          Expanded(
            child: Column(
              children: [
                Text(
                  _showEthiopianCalendar
                      ? () {
                          final startEth = EthiopianCalendar.fromGregorian(_periodStart);
                          final endEth = EthiopianCalendar.fromGregorian(_periodEnd);
                          return '${EthiopianCalendar.monthsEnglish[startEth.month - 1]} ${startEth.day} - ${EthiopianCalendar.monthsEnglish[endEth.month - 1]} ${endEth.day}, ${endEth.year}';
                        }()
                      : DateFormat('MMM d').format(_periodStart) + ' - ' + DateFormat('MMM d, yyyy').format(_periodEnd),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isCurrentPeriod) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _goToToday,
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text('Go to Today'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          IconButton(
            onPressed: canGoNext ? _goToNextPeriod : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Period',
            style: IconButton.styleFrom(
              backgroundColor: canGoNext ? Colors.white : const Color(0xFFE5E7EB),
              foregroundColor: canGoNext ? const Color(0xFF007A3D) : const Color(0xFF9CA3AF),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
