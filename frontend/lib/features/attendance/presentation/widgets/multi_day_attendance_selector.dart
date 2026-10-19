import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/attendance.dart';
import '../../domain/entities/payment_period.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../core/utils/app_snackbar.dart';

class MultiDayAttendanceSelector extends StatefulWidget {
  final Worker worker;
  final DateTime startDate;
  final List<Attendance> existingAttendances;
  final Function(List<DateTime> selectedDates, String status) onSave;
  final String mode;

  const MultiDayAttendanceSelector({
    super.key,
    required this.worker,
    required this.startDate,
    required this.existingAttendances,
    required this.onSave,
    this.mode = 'mark',
  });

  @override
  State<MultiDayAttendanceSelector> createState() => _MultiDayAttendanceSelectorState();
}

class _MultiDayAttendanceSelectorState extends State<MultiDayAttendanceSelector> {
  final Set<DateTime> _selectedDates = {};
  String _selectedStatus = 'present';
  bool _isUnmarkMode = false;
  bool _showEthiopianCalendar = true;
  final _dataSource = AttendanceRemoteDataSource();
  
  PaymentPeriod? _paymentPeriod;
  bool _isLoadingPeriod = true;
  int _periodOffset = 0;
  
  int get _paymentPeriodDays => _paymentPeriod?.periodDays ?? widget.worker.paymentPeriodDays ?? 14;
  
  DateTime get _periodStart {
    final baseStart = _paymentPeriod?.periodStart ?? widget.startDate;
    return baseStart.add(Duration(days: _periodOffset * _paymentPeriodDays));
  }
  
  DateTime get _periodEnd => _periodStart.add(Duration(days: _paymentPeriodDays - 1));

  int get _daysUntilToday {
    final today = DateTime.now();
    final daysDifference = today.difference(_periodStart).inDays + 1;
    return daysDifference > 0 ? daysDifference : 0;
  }

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

  Future<void> _fetchPaymentPeriod() async {
    if (widget.worker.id == null) {
      setState(() => _isLoadingPeriod = false);
      return;
    }

    try {
      final periodData = await _dataSource.getWorkerPaymentPeriod(
        workerId: widget.worker.id!,
        referenceDate: widget.startDate,
      );

      if (periodData != null && mounted) {
        setState(() {
          _paymentPeriod = PaymentPeriod.fromJson(periodData);
          _isLoadingPeriod = false;
        });
      } else {
        setState(() => _isLoadingPeriod = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPeriod = false);
      }
    }
  }

  bool _hasAttendance(DateTime date) {
    return widget.existingAttendances.any((a) => 
      a.attendanceDate.year == date.year &&
      a.attendanceDate.month == date.month &&
      a.attendanceDate.day == date.day
    );
  }

  Attendance? _getAttendance(DateTime date) {
    try {
      return widget.existingAttendances.firstWhere((a) => 
        a.attendanceDate.year == date.year &&
        a.attendanceDate.month == date.month &&
        a.attendanceDate.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF007A3D);
      case 'absent':
        return const Color(0xFFB71C1C);
      case 'late':
        return const Color(0xFFE65100);
      case 'excused':
        return const Color(0xFF1E3A5F);
      case 'leave':
        return const Color(0xFF0A192F);
      case 'half_day':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.event_available;
      case 'leave':
        return Icons.beach_access;
      case 'half_day':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      if (_selectedDates.contains(normalizedDate)) {
        _selectedDates.remove(normalizedDate);
      } else {
        _selectedDates.add(normalizedDate);
      }
    });
  }

  bool _validateDates() {
    if (_selectedDates.isEmpty) {
      return false;
    }

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    final futureDates = _selectedDates.where((date) => date.isAfter(todayNormalized)).toList();
    if (futureDates.isNotEmpty) {
      AppSnackBar.showWarning(
        context,
        widget.mode == 'verify'
            ? 'Future dates (grayed out) cannot be selected. Attendance can only be verified up to today for payroll accuracy.'
            : 'Future dates (grayed out) cannot be selected. Attendance can only be marked up to today for payroll accuracy.',
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    return true;
  }

  Future<void> _confirmAndSave() async {
    if (!_validateDates()) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _isUnmarkMode 
                  ? Icons.delete_outline 
                  : (widget.mode == 'verify' ? Icons.verified : Icons.warning_amber_rounded),
              color: _isUnmarkMode 
                  ? const Color(0xFFB71C1C) 
                  : (widget.mode == 'verify' ? const Color(0xFF005C2E) : const Color(0xFFE65100)),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(_isUnmarkMode 
                ? 'Confirm Unmark' 
                : (widget.mode == 'verify' ? 'Confirm Verification' : 'Confirm Attendance')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isUnmarkMode
                  ? 'You are about to unmark attendance for:'
                  : widget.mode == 'verify'
                      ? 'You are about to verify attendance for:'
                      : 'You are about to mark attendance for:',
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF1F2937),
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
                        '${_selectedDates.length} day${_selectedDates.length != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (widget.mode == 'mark' && !_isUnmarkMode) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(_selectedStatus),
                          size: 18,
                          color: _getStatusColor(_selectedStatus),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_selectedStatus),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isUnmarkMode 
                    ? const Color(0xFFFFEBEE) 
                    : (widget.mode == 'verify' ? const Color(0xFFE8F5EE) : const Color(0xFFFFEBEE)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isUnmarkMode 
                      ? const Color(0xFFEF9A9A) 
                      : (widget.mode == 'verify' ? const Color(0xFFB2DFCA) : const Color(0xFFEF9A9A)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _isUnmarkMode 
                        ? const Color(0xFFB71C1C) 
                        : (widget.mode == 'verify' ? const Color(0xFF005C2E) : const Color(0xFFB71C1C)),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isUnmarkMode
                          ? 'This will remove attendance records and affect payroll calculations. Please verify before confirming.'
                          : widget.mode == 'verify'
                              ? 'Verification locks attendance records and confirms them for payroll processing.'
                              : 'This will affect payroll calculations. Please verify before confirming.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isUnmarkMode 
                            ? const Color(0xFF7F0000) 
                            : (widget.mode == 'verify' ? const Color(0xFF003D1F) : const Color(0xFF7F0000)),
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
              backgroundColor: _getStatusColor(_selectedStatus),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_isUnmarkMode) {
        // Call onSave with special 'unmark' status to indicate deletion
        widget.onSave(_selectedDates.toList(), 'unmark');
      } else {
        widget.onSave(_selectedDates.toList(), _selectedStatus);
      }
      Navigator.pop(context);
    }
  }

  void _selectAll() {
    setState(() {
      _selectedDates.clear();
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      
      for (int i = 0; i < _paymentPeriodDays; i++) {
        final date = _periodStart.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        
        if (normalizedDate.isAfter(todayNormalized)) {
          break;
        }
        
        if (widget.mode == 'verify') {
          final attendance = _getAttendance(date);
          if (attendance != null && !attendance.isVerified) {
            _selectedDates.add(normalizedDate);
          }
        } else if (_isUnmarkMode) {
          if (_hasAttendance(date)) {
            _selectedDates.add(normalizedDate);
          }
        } else {
          if (!_hasAttendance(date)) {
            _selectedDates.add(normalizedDate);
          }
        }
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedDates.clear();
    });
  }

  void _goToPreviousPeriod() {
    setState(() {
      _periodOffset--;
      _selectedDates.clear();
    });
  }

  void _goToNextPeriod() {
    setState(() {
      _periodOffset++;
      _selectedDates.clear();
    });
  }

  void _goToToday() {
    setState(() {
      _periodOffset = 0;
      _selectedDates.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
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
                    Text(
                      widget.mode == 'verify' ? 'Multi-Day Verification' : 'Multi-Day Attendance',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                      'ID: ${widget.worker.employeeId} • ${widget.worker.workType ?? 'No work type'}',
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
          
          if (widget.mode == 'mark') ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isUnmarkMode = false;
                          _selectedDates.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isUnmarkMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isUnmarkMode
                              ? [BoxShadow(color: const Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: !_isUnmarkMode ? const Color(0xFF007A3D) : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Mark',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: !_isUnmarkMode ? FontWeight.bold : FontWeight.normal,
                                color: !_isUnmarkMode ? const Color(0xFF007A3D) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isUnmarkMode = true;
                          _selectedDates.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isUnmarkMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isUnmarkMode
                              ? [BoxShadow(color: const Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: _isUnmarkMode ? const Color(0xFFB71C1C) : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Unmark',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _isUnmarkMode ? FontWeight.bold : FontWeight.normal,
                                color: _isUnmarkMode ? const Color(0xFFB71C1C) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isUnmarkMode ? const Color(0xFFFFEBEE) : const Color(0xFFE8EDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isUnmarkMode ? const Color(0xFFEF9A9A) : const Color(0xFF90CAF9), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _isUnmarkMode ? const Color(0xFFB71C1C) : const Color(0xFF0A192F), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isUnmarkMode
                        ? 'Showing $_paymentPeriodDays-day payment period. Select marked dates to unmark attendance.'
                        : widget.mode == 'verify'
                            ? 'Showing $_paymentPeriodDays-day payment period. Select unverified attendance to verify.'
                            : 'Showing $_paymentPeriodDays-day payment period. Select unmarked dates to mark attendance.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isUnmarkMode ? const Color(0xFF7F0000) : const Color(0xFF0A192F),
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
                '${_selectedDates.length} day${_selectedDates.length != 1 ? 's' : ''} selected',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildPeriodNavigator(),
          
          const SizedBox(height: 16),
          
          Container(
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
                    physics: const NeverScrollableScrollPhysics(),
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
                      final isSelected = _selectedDates.contains(normalizedDate);
                      final attendance = _getAttendance(date);
                      final hasAttendance = attendance != null;
                      final isToday = date.year == DateTime.now().year &&
                          date.month == DateTime.now().month &&
                          date.day == DateTime.now().day;

                      return _buildDateCard(
                        date: date,
                        isSelected: isSelected,
                        hasAttendance: hasAttendance,
                        attendance: attendance,
                        isToday: isToday,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          
          if (widget.mode == 'mark' && !_isUnmarkMode) ...[
            Text(
              'Select Status',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip('present', 'Present', Icons.check_circle, const Color(0xFF007A3D)),
                _buildStatusChip('absent', 'Absent', Icons.cancel, const Color(0xFFB71C1C)),
                _buildStatusChip('late', 'Late', Icons.access_time, const Color(0xFFE65100)),
                _buildStatusChip('excused', 'Excused', Icons.event_available, const Color(0xFF1E3A5F)),
                _buildStatusChip('leave', 'Leave', Icons.beach_access, const Color(0xFF0A192F)),
                _buildStatusChip('half_day', 'Half Day', Icons.schedule, const Color(0xFFE65100)),
              ],
            ),
            const SizedBox(height: 20),
          ],
          
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
                  onPressed: _selectedDates.isEmpty ? null : _confirmAndSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isUnmarkMode 
                        ? const Color(0xFFB71C1C) 
                        : (widget.mode == 'verify' ? const Color(0xFF007A3D) : _getStatusColor(_selectedStatus)),
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
                        _isUnmarkMode 
                            ? Icons.remove_circle 
                            : (widget.mode == 'verify' ? Icons.verified : _getStatusIcon(_selectedStatus)),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDates.isEmpty
                            ? 'Select Days'
                            : _isUnmarkMode
                                ? 'Unmark ${_selectedDates.length} Day${_selectedDates.length != 1 ? 's' : ''}'
                                : widget.mode == 'verify'
                                    ? 'Verify ${_selectedDates.length} Day${_selectedDates.length != 1 ? 's' : ''}'
                                    : 'Mark ${_selectedDates.length} Day${_selectedDates.length != 1 ? 's' : ''}',
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

  Widget _buildDateCard({
    required DateTime date,
    required bool isSelected,
    required bool hasAttendance,
    required Attendance? attendance,
    required bool isToday,
  }) {
    final dayName = DateFormat('EEE').format(date);
    final dayNumber = _showEthiopianCalendar 
        ? EthiopianCalendar.fromGregorian(date).day 
        : date.day;
    
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final isFutureDate = date.isAfter(todayNormalized);

    Color borderColor;
    Color backgroundColor;
    Color textColor;

    final canSelect = _isUnmarkMode
        ? (hasAttendance && attendance != null && !isFutureDate)
        : widget.mode == 'verify'
            ? (hasAttendance && attendance != null && !attendance.isVerified && !isFutureDate)
            : (!hasAttendance && !isFutureDate);

    if (isFutureDate) {
      borderColor = const Color(0xFFE5E7EB);
      backgroundColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF9CA3AF);
    } else if (widget.mode == 'verify' && hasAttendance && attendance != null) {
      if (attendance.isVerified) {
        borderColor = const Color(0xFF005C2E);
        backgroundColor = const Color(0xFFE8F5EE);
        textColor = const Color(0xFF005C2E);
      } else if (isSelected) {
        borderColor = const Color(0xFF0A192F);
        backgroundColor = const Color(0xFFE8EDF4);
        textColor = const Color(0xFF0A192F);
      } else {
        final statusColor = _getStatusColor(attendance.status);
        borderColor = statusColor;
        backgroundColor = Color.fromARGB(38, statusColor.red, statusColor.green, statusColor.blue);
        textColor = Color.fromARGB(230, statusColor.red, statusColor.green, statusColor.blue);
      }
    } else if (hasAttendance) {
      final statusColor = _getStatusColor(attendance!.status);
      borderColor = statusColor;
      backgroundColor = Color.fromARGB(38, statusColor.red, statusColor.green, statusColor.blue);
      textColor = Color.fromARGB(230, statusColor.red, statusColor.green, statusColor.blue);
    } else if (isSelected) {
      borderColor = const Color(0xFF007A3D);
      backgroundColor = const Color(0x1A007A3D);
      textColor = const Color(0xFF007A3D);
    } else {
      borderColor = const Color(0xFFD1D5DB);
      backgroundColor = Colors.white;
      textColor = const Color(0xFF1F2937);
    }

    final dateStr = _showEthiopianCalendar
        ? () {
            final ethDate = EthiopianCalendar.fromGregorian(date);
            return '${EthiopianCalendar.monthsEnglish[ethDate.month - 1]} ${ethDate.day}, ${ethDate.year}';
          }()
        : DateFormat('MMM d, yyyy').format(date);
    
    String tooltipMessage;
    if (canSelect) {
      if (_isUnmarkMode) {
        tooltipMessage = 'Unmark attendance on $dateStr';
      } else if (widget.mode == 'verify') {
        tooltipMessage = 'Click to verify $dateStr';
      } else {
        tooltipMessage = 'Mark attendance on $dateStr';
      }
    } else {
      if (isFutureDate) {
        tooltipMessage = 'Future date - Cannot be selected';
      } else if (hasAttendance && attendance != null) {
        if (widget.mode == 'verify') {
          tooltipMessage = attendance.isVerified 
              ? 'Already verified' 
              : 'Already marked as ${attendance.status}';
        } else {
          tooltipMessage = 'Already marked as ${attendance.status}';
        }
      } else {
        tooltipMessage = 'No attendance recorded';
      }
    }
    
    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        onTap: canSelect ? () => _toggleDate(date) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: isSelected || hasAttendance ? 2 : 1,
            ),
            boxShadow: isSelected 
                ? [
                    BoxShadow(
                      color: Color.fromARGB(102, borderColor.red, borderColor.green, borderColor.blue),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] 
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isToday)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
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
              if (isSelected) ...[
                const SizedBox(height: 2),
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: textColor,
                ),
              ] else if (isFutureDate) ...[
                const SizedBox(height: 2),
                Icon(
                  Icons.block,
                  size: 14,
                  color: textColor,
                ),
              ] else if (widget.mode == 'verify' && hasAttendance && attendance != null) ...[
                const SizedBox(height: 2),
                Icon(
                  attendance.isVerified ? Icons.verified : Icons.circle,
                  size: attendance.isVerified ? 14 : 8,
                  color: textColor,
                ),
              ] else if (hasAttendance) ...[
                const SizedBox(height: 2),
                Icon(
                  Icons.circle,
                  size: 8,
                  color: textColor,
                ),
              ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatusChip(String status, String label, IconData icon, Color color) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      backgroundColor: Color.fromARGB(26, color.red, color.green, color.blue),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : Color.fromARGB(77, color.red, color.green, color.blue),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}
