import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/attendance.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import '../../../../core/widgets/ethiopian_date_picker.dart';
import '../../../../core/utils/ethiopian_calendar.dart';

class AttendanceDetailPage extends StatefulWidget {
  final Attendance? attendance;
  final int? workerId;
  final int siteId;

  const AttendanceDetailPage({
    super.key,
    this.attendance,
    this.workerId,
    required this.siteId,
  });

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _overrideReasonController = TextEditingController();
  final _dataSource = AttendanceRemoteDataSource();
  final _audioService = AudioFeedbackService();

  late DateTime _selectedDate;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  String _selectedStatus = 'present';
  int _regularHours = 8;
  double _overtimeHours = 0.0;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _showEthiopianCalendar = true;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'present', 'label': 'Present', 'icon': Icons.check_circle, 'color': Colors.green},
    {'value': 'absent', 'label': 'Absent', 'icon': Icons.cancel, 'color': Colors.red},
    {'value': 'late', 'label': 'Late', 'icon': Icons.access_time, 'color': Colors.orange},
    {'value': 'excused', 'label': 'Excused', 'icon': Icons.event_available, 'color': Colors.blue},
    {'value': 'leave', 'label': 'Leave', 'icon': Icons.beach_access, 'color': Colors.purple},
    {'value': 'half_day', 'label': 'Half Day', 'icon': Icons.schedule, 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.attendance != null;
    _selectedDate = widget.attendance?.attendanceDate ?? DateTime.now();
    
    if (widget.attendance != null) {
      _selectedStatus = widget.attendance!.status;
      _regularHours = widget.attendance!.regularHours;
      _overtimeHours = widget.attendance!.overtimeHours;
      _notesController.text = widget.attendance!.notes ?? '';
      _overrideReasonController.text = widget.attendance!.overrideReason ?? '';
      
      if (widget.attendance!.checkInTime != null) {
        final parts = widget.attendance!.checkInTime!.split(':');
        _checkInTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      
      if (widget.attendance!.checkOutTime != null) {
        final parts = widget.attendance!.checkOutTime!.split(':');
        _checkOutTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _overrideReasonController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showEthiopianDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      showEthiopian: _showEthiopianCalendar,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isCheckIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isCheckIn ? _checkInTime : _checkOutTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  String? _timeToString(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStatus == 'excused' && _overrideReasonController.text.trim().isEmpty) {
      VisualFeedbackOverlay.showFlashFeedback(
        context,
        type: FeedbackType.error,
        message: 'Override reason is required for Excused status',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing && widget.attendance != null) {
        await _dataSource.updateAttendance(
          id: widget.attendance!.id!,
          checkInTime: _timeToString(_checkInTime),
          checkOutTime: _timeToString(_checkOutTime),
          status: _selectedStatus,
          regularHours: _regularHours,
          overtimeHours: _overtimeHours,
          overrideReason: _overrideReasonController.text.trim().isNotEmpty 
              ? _overrideReasonController.text.trim() 
              : null,
          notes: _notesController.text.trim().isNotEmpty 
              ? _notesController.text.trim() 
              : null,
        );
        
        await _audioService.playAttendanceSuccess('Updated');
        
        if (mounted) {
          VisualFeedbackOverlay.showFlashFeedback(
            context,
            type: FeedbackType.success,
            message: 'Attendance Updated Successfully',
          );
          Navigator.pop(context, true);
        }
      } else {
        await _dataSource.createAttendance(
          workerId: widget.workerId!,
          siteId: widget.siteId,
          attendanceDate: _selectedDate,
          checkInTime: _timeToString(_checkInTime),
          checkOutTime: _timeToString(_checkOutTime),
          status: _selectedStatus,
          method: 'manual_entry',
          regularHours: _regularHours,
          overtimeHours: _overtimeHours,
          notes: _notesController.text.trim().isNotEmpty 
              ? _notesController.text.trim() 
              : null,
        );
        
        await _audioService.playAttendanceSuccess('Created');
        
        if (mounted) {
          VisualFeedbackOverlay.showFlashFeedback(
            context,
            type: FeedbackType.success,
            message: 'Attendance Recorded Successfully',
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      await _audioService.playAttendanceError();
      if (mounted) {
        VisualFeedbackOverlay.showFlashFeedback(
          context,
          type: FeedbackType.error,
          message: 'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isVerified = widget.attendance?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing 
            ? 'Edit Attendance'
            : (localizations?.markAttendance ?? 'Mark Attendance')),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              setState(() {
                _showEthiopianCalendar = !_showEthiopianCalendar;
              });
            },
            tooltip: 'Toggle Calendar Type',
          ),
          if (isVerified)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Icon(Icons.verified, color: Colors.white, size: 18),
                label: const Text('Verified', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.attendance != null) ...[
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildDateSection(localizations),
                  const SizedBox(height: 16),
                  
                  _buildTimeSection(localizations),
                  const SizedBox(height: 16),
                  
                  _buildStatusSection(localizations),
                  const SizedBox(height: 16),
                  
                  _buildHoursSection(localizations),
                  const SizedBox(height: 16),
                  
                  if (_selectedStatus == 'excused')
                    _buildOverrideReasonField(localizations),
                  
                  _buildNotesField(localizations),
                  const SizedBox(height: 24),
                  
                  _buildActionButtons(localizations),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attendance?.workerName ?? 'Worker',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ID: ${widget.attendance?.employeeId ?? 'N/A'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.attendance?.ethiopianYear != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    widget.attendance!.formattedEthiopianDate,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(AppLocalizations? localizations) {
    String dateText;
    String calendarLabel;
    
    if (_showEthiopianCalendar) {
      final ethiopianDate = EthiopianCalendar.fromGregorian(_selectedDate);
      final weekday = _selectedDate.weekday;
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      dateText = '${weekdays[weekday - 1]}, ${EthiopianCalendar.formatEthiopian(ethiopianDate)}';
      calendarLabel = 'Ethiopian Calendar';
    } else {
      dateText = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
      calendarLabel = 'Gregorian Calendar';
    }
    
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text('Date ($calendarLabel)'),
        subtitle: Text(dateText),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildTimeSection(AppLocalizations? localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Check In',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.login),
                      ),
                      child: Text(
                        _checkInTime != null 
                            ? _checkInTime!.format(context) 
                            : 'Not Set',
                        style: TextStyle(
                          color: _checkInTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Check Out',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.logout),
                      ),
                      child: Text(
                        _checkOutTime != null 
                            ? _checkOutTime!.format(context) 
                            : 'Not Set',
                        style: TextStyle(
                          color: _checkOutTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
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

  Widget _buildStatusSection(AppLocalizations? localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.status ?? 'Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((option) {
                final isSelected = _selectedStatus == option['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : option['color'] as Color,
                      ),
                      const SizedBox(width: 4),
                      Text(option['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: option['color'] as Color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = option['value'] as String;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSection(AppLocalizations? localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Working Hours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Regular Hours', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _regularHours > 0 
                                ? () => setState(() => _regularHours--) 
                                : null,
                          ),
                          Text(
                            '$_regularHours h',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _regularHours < 24 
                                ? () => setState(() => _regularHours++) 
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overtime Hours', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _overtimeHours > 0 
                                ? () => setState(() => _overtimeHours = (_overtimeHours - 0.5).clamp(0.0, 24.0)) 
                                : null,
                          ),
                          Text(
                            '${_overtimeHours.toStringAsFixed(_overtimeHours == _overtimeHours.roundToDouble() ? 0 : 1)} h',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _overtimeHours < 24 
                                ? () => setState(() => _overtimeHours = (_overtimeHours + 0.5).clamp(0.0, 24.0)) 
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverrideReasonField(AppLocalizations? localizations) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _overrideReasonController,
        decoration: InputDecoration(
          labelText: 'Override Reason *',
          hintText: 'Required for Excused status',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.notes),
          filled: true,
          fillColor: Colors.blue.withOpacity(0.05),
        ),
        maxLines: 2,
        validator: (value) {
          if (_selectedStatus == 'excused' && (value == null || value.trim().isEmpty)) {
            return 'Override reason is mandatory for Excused status';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNotesField(AppLocalizations? localizations) {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional notes...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Widget _buildActionButtons(AppLocalizations? localizations) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAttendance,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing 
                      ? 'Update'
                      : (localizations?.save ?? 'Save')),
            ),
          ),
        ),
      ],
    );
  }
}
