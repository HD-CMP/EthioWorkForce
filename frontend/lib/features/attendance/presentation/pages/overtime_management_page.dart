import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../workers/domain/entities/site.dart';
import '../../../workers/domain/entities/work_type.dart';
import '../../../workers/data/datasources/worker_remote_datasource.dart';
import '../../../workers/data/datasources/site_remote_datasource.dart';
import '../../../workers/data/datasources/work_type_remote_datasource.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../domain/entities/attendance.dart';

class OvertimeManagementPage extends StatefulWidget {
  const OvertimeManagementPage({super.key});

  @override
  State<OvertimeManagementPage> createState() => _OvertimeManagementPageState();
}

class _OvertimeManagementPageState extends State<OvertimeManagementPage> {
  final _workerDatasource = WorkerRemoteDataSource();
  final _siteDatasource = SiteRemoteDataSource();
  final _workTypeDatasource = WorkTypeRemoteDataSource();
  final _attendanceDatasource = AttendanceRemoteDataSource();
  
  List<Worker> _workers = [];
  List<Site> _sites = [];
  Map<int, WorkType> _workTypesMap = {};
  List<Attendance> _attendances = [];
  Site? _selectedSite;
  DateTime _selectedDate = DateTime.now();
  
  final Map<int, TextEditingController> _overtimeControllers = {};
  final Map<int, double> _overtimeValues = {};
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  @override
  void dispose() {
    for (var controller in _overtimeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sites = await _siteDatasource.getSites(isActive: true);
      if (mounted) {
        setState(() {
          _sites = sites;
          if (sites.isNotEmpty && _selectedSite == null) {
            _selectedSite = sites.first;
            _loadWorkers();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiException ? e.displayMessage : 'Failed to load sites';
        });
      }
    }
  }

  Future<void> _loadWorkers() async {
    if (_selectedSite == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workers = await _workerDatasource.getWorkers(
        siteId: _selectedSite!.id,
        status: 'active',
      );
      
      final workTypes = await _workTypeDatasource.getWorkTypes(isActive: true);
      _workTypesMap = {for (var wt in workTypes) wt.id!: wt};
      
      // LEAK FIX: Only display workers whose Work Type explicitly allows overtime.
      // This prevents timekeepers from accidentally recording overtime for executives
      // or other non-eligible salaried staff.
      final eligibleWorkers = workers.where((worker) {
        if (worker.workTypeId == null) return false;
        final wt = _workTypesMap[worker.workTypeId];
        return wt != null && wt.overtimeEligible == true;
      }).toList();
      
      
      // Load 90 days before and after selected date to cover multiple payment periods
      final dateFrom = _selectedDate.subtract(const Duration(days: 90));
      final dateTo = _selectedDate.add(const Duration(days: 90));
      
      final attendances = await _attendanceDatasource.getAttendances(
        siteId: _selectedSite!.id!,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      if (mounted) {
        _overtimeControllers.clear();
        _overtimeValues.clear();
        
        for (var worker in eligibleWorkers) {
          // Get all attendances for this worker in the loaded period
          final workerAttendances = attendances.where((a) => a.workerId == worker.id).toList();
          
          // Get attendance for selected date to show current overtime
          final todayAttendance = workerAttendances.cast<dynamic>().firstWhere(
            (a) => a.attendanceDate.year == _selectedDate.year &&
                   a.attendanceDate.month == _selectedDate.month &&
                   a.attendanceDate.day == _selectedDate.day,
            orElse: () => null,
          );
          
          final overtimeHours = todayAttendance?.overtimeHours?.toDouble() ?? 0.0;
          _overtimeValues[worker.id!] = overtimeHours;
          _overtimeControllers[worker.id!] = TextEditingController(
            text: overtimeHours > 0 ? overtimeHours.toString() : '',
          );
        }

        setState(() {
          _workers = eligibleWorkers;
          _attendances = attendances;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiException ? e.displayMessage : 'Failed to load workers';
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadWorkers();
    }
  }

  Future<void> _saveOvertime() async {
    if (_selectedSite == null) return;

    final overtimeEntries = <Map<String, dynamic>>[];
    
    for (var entry in _overtimeValues.entries) {
      if (entry.value > 0) {
        overtimeEntries.add({
          'worker_id': entry.key,
          'overtime_hours': entry.value,
        });
      }
    }

    if (overtimeEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No overtime hours to save')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await _attendanceDatasource.bulkUpdateOvertime(
        siteId: _selectedSite!.id!,
        date: _selectedDate,
        overtimeEntries: overtimeEntries,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Overtime saved: ${result['updated']} updated, ${result['created']} created',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadWorkers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.displayMessage : 'Failed to save overtime'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updateOvertimeValue(int workerId, String value) {
    final hours = double.tryParse(value) ?? 0.0;
    setState(() {
      _overtimeValues[workerId] = hours;
    });
  }

  double _calculateTotalPay(Worker worker, double overtimeHours) {
    if (overtimeHours == 0.0 || worker.workTypeId == null) {
      return 0.0;
    }
    final workType = _workTypesMap[worker.workTypeId];
    if (workType?.overtimeRatePerHour == null) {
      return 0.0;
    }
    return (overtimeHours * workType!.overtimeRatePerHour!).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overtime Management'),
        actions: [
          if (_workers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveOvertime,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Overtime'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Site>(
                          value: _selectedSite,
                          decoration: const InputDecoration(
                            labelText: 'Site',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          items: _sites.map((site) {
                            return DropdownMenuItem(
                              value: site,
                              child: Text(site.name),
                            );
                          }).toList(),
                          onChanged: (site) {
                            setState(() {
                              _selectedSite = site;
                            });
                            _loadWorkers();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_workers.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _selectedSite == null
                      ? 'Select a site to begin'
                      : 'No active workers found at this site',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _workers.length,
                itemBuilder: (context, index) {
                  final worker = _workers[index];
                  final controller = _overtimeControllers[worker.id!]!;
                  final overtimeHours = _overtimeValues[worker.id!] ?? 0;
                  final totalPay = _calculateTotalPay(worker, overtimeHours);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : 'W',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${worker.employeeId} • ${worker.workType ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (worker.workTypeId != null)
                                      _workTypesMap[worker.workTypeId]?.overtimeRatePerHour != null
                                        ? Text(
                                            'OT Rate: ETB ${_workTypesMap[worker.workTypeId]!.overtimeRatePerHour!.toStringAsFixed(2)}/hr',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        : Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange[700]),
                                              const SizedBox(width: 4),
                                              Text(
                                                'OT Rate not configured',
                                                style: TextStyle(
                                                  color: Colors.orange[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Overtime Hours',
                                        border: OutlineInputBorder(),
                                        hintText: '0.0',
                                        suffixText: 'hrs',
                                        prefixIcon: Icon(Icons.access_time),
                                        helperText: 'e.g., 3.5 or 4.5',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                                      ],
                                      onChanged: (value) => _updateOvertimeValue(worker.id!, value),
                                    ),
                                    if (overtimeHours > 0 && 
                                        (worker.workTypeId == null || 
                                         _workTypesMap[worker.workTypeId]?.overtimeRatePerHour == null)) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange[300]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Overtime rate not set. Fallback calculation (1.5x base rate) will be used.',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange[900],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (totalPay > 0) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'OT Payment',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        'ETB ${totalPay.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
