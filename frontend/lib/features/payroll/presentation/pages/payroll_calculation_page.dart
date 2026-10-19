import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../core/widgets/ethiopian_date_picker.dart';
import '../../../workers/domain/entities/site.dart';
import '../../../workers/domain/entities/work_type.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../workers/data/datasources/work_type_remote_datasource.dart';
import '../../../workers/data/datasources/worker_remote_datasource.dart';
import '../bloc/payroll_bloc.dart';
import '../bloc/payroll_event.dart';
import '../bloc/payroll_state.dart';
import 'payroll_detail_page.dart';

class PayrollCalculationPage extends StatefulWidget {
  final Site site;

  const PayrollCalculationPage({
    super.key,
    required this.site,
  });

  @override
  State<PayrollCalculationPage> createState() => _PayrollCalculationPageState();
}

class _PayrollCalculationPageState extends State<PayrollCalculationPage> {
  final _formKey = GlobalKey<FormState>();
  final _workTypeDataSource = WorkTypeRemoteDataSource();
  final _workerDataSource = WorkerRemoteDataSource();
  
  String _periodType = 'monthly';
  DateTime? _periodStart;
  DateTime? _periodEnd;
  final TextEditingController _ethiopianMonthController = TextEditingController();
  final TextEditingController _ethiopianYearController = TextEditingController();
  late bool _showEthiopianCalendar;
  
  List<String> _workPlaces = [];
  Map<String, int?> _workPlaceNameToId = {};
  List<Worker> _allWorkers = [];
  String? _selectedWorkPlaceName;
  bool _isLoadingWorkers = false;
  bool _isCurrentCycleSelected = false;

  List<WorkType> _workTypes = [];
  bool _isLoadingWorkTypes = false;
  int? _referenceWorkTypeId;

  @override
  void initState() {
    super.initState();
    _showEthiopianCalendar = true;
    _setDefaultDates();
    _updateEthiopianFields();
    _loadWorkTypes();
    _loadWorkers();
  }
  
  Future<void> _loadWorkTypes() async {
    setState(() => _isLoadingWorkTypes = true);
    try {
      final types = await _workTypeDataSource.getWorkTypes(isActive: true);
      if (mounted) {
        setState(() {
          _workTypes = types;
          _isLoadingWorkTypes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWorkTypes = false);
      }
    }
  }
  
  Future<void> _loadWorkers() async {
    setState(() => _isLoadingWorkers = true);
    try {
      final workers = await _workerDataSource.getWorkers(siteId: widget.site.id!, status: 'active');
      
      if (mounted) {
        setState(() {
          _allWorkers = workers;
          _isLoadingWorkers = false;
          
          final Set<String> places = {};
          for (final worker in _allWorkers) {
            final wp = worker.workPlaceName ?? 'General Workforce';
            places.add(wp);
            _workPlaceNameToId[wp] = worker.workPlaceId;
          }
          _workPlaces = places.toList()..sort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWorkers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Error loading workers: ${e.toString()}')),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ethiopianMonthController.dispose();
    _ethiopianYearController.dispose();
    super.dispose();
  }

  void _updateEthiopianFields() {
    if (_periodStart != null) {
      final ethDate = EthiopianCalendar.fromGregorian(_periodStart!);
      final monthName = EthiopianCalendar.monthsEnglish[ethDate.month - 1];
      _ethiopianMonthController.text = monthName;
      _ethiopianYearController.text = ethDate.year.toString();
    }
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    if (_periodType == 'monthly') {
      _periodStart = DateTime(now.year, now.month, 1);
      _periodEnd = now;
    } else if (_periodType == 'biweekly') {
      _periodStart = now.subtract(Duration(days: now.weekday - 1));
      _periodEnd = now;
    } else {
      _periodStart = now.subtract(Duration(days: now.weekday - 1));
      _periodEnd = now;
    }
    _isCurrentCycleSelected = true; // Default to current period
    setState(() {});
  }
  
  void _applyWorkTypePeriodSettings(int workTypeId) {
    try {
      final workType = _workTypes.firstWhere((wt) => wt.id == workTypeId);
      if (workType.paymentPeriodDays != null && workType.paymentPeriodStartDate != null) {
        final cycleDays = workType.paymentPeriodDays!;
        final anchorDate = workType.paymentPeriodStartDate!;
        
        final now = DateTime.now();
        var currentStart = anchorDate;
        
        while (currentStart.add(Duration(days: cycleDays)).isBefore(now)) {
          currentStart = currentStart.add(Duration(days: cycleDays));
        }
        
        final periodEnd = currentStart.add(Duration(days: cycleDays - 1));
        
        setState(() {
          _periodStart = currentStart;
          _periodEnd = periodEnd.isBefore(now) ? periodEnd : now;
          _isCurrentCycleSelected = true;
          _updateEthiopianFields();
        });
      }
    } catch (e) {
      debugPrint("Error applying work type period: $e");
    }
  }

  void _setCurrentPeriod() {
    final now = DateTime.now();
    setState(() {
      _periodStart = DateTime(now.year, now.month, 1);
      _periodEnd = DateTime(now.year, now.month, now.day);
      _isCurrentCycleSelected = true;
      _updateEthiopianFields();
    });
  }

  void _setFullMonthPeriod() {
    final now = DateTime.now();
    setState(() {
      _periodStart = DateTime(now.year, now.month, 1);
      _periodEnd = DateTime(now.year, now.month + 1, 0);
      _isCurrentCycleSelected = false;
      _updateEthiopianFields();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked;
    
    if (_showEthiopianCalendar) {
      picked = await showEthiopianDatePicker(
        context: context,
        initialDate: isStart ? (_periodStart ?? DateTime.now()) : (_periodEnd ?? DateTime.now()),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        showEthiopian: true,
      );
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: isStart ? (_periodStart ?? DateTime.now()) : (_periodEnd ?? DateTime.now()),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
    }

    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
          _updateEthiopianFields();
        } else {
          _periodEnd = picked;
        }
        // Reset the selection state when manually picking dates
        // Check if end date is today - if so, mark as current cycle
        if (_periodEnd != null) {
          final now = DateTime.now();
          final normalizedNow = DateTime(now.year, now.month, now.day);
          final normalizedEnd = DateTime(_periodEnd!.year, _periodEnd!.month, _periodEnd!.day);
          _isCurrentCycleSelected = normalizedEnd.isAtSameMomentAs(normalizedNow);
        }
      });
    }
  }

  void _calculatePayroll(PayrollBloc bloc) {
    if (_formKey.currentState!.validate()) {
      if (_periodStart == null || _periodEnd == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Please select both start and end dates'),
            ]),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      if (_periodEnd!.isBefore(_periodStart!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('End date must be after start date'),
            ]),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      bloc.add(
        CreateAndCalculatePayroll(
          siteId: widget.site.id!,
          periodType: _periodType,
          periodStart: _periodStart!,
          periodEnd: _periodEnd!,
          ethiopianMonth: _ethiopianMonthController.text.isEmpty
              ? null
              : _ethiopianMonthController.text,
          ethiopianYear: _ethiopianYearController.text.isEmpty
              ? null
              : int.tryParse(_ethiopianYearController.text),
          workTypeId: null,
          workPlaceId: _selectedWorkPlaceName != null ? _workPlaceNameToId[_selectedWorkPlaceName] : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return BlocProvider(
      create: (_) => getIt<PayrollBloc>(),
      child: BlocConsumer<PayrollBloc, PayrollState>(
        listener: (context, state) {
          if (state is PayrollCalculated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Payroll calculated successfully: ${state.payroll.payrollCode}'),
                  ),
                ]),
                backgroundColor: const Color(0xFF007A3D),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PayrollDetailPage(
                  payrollId: state.payroll.id,
                  payrollCode: state.payroll.payrollCode,
                  period: state.payroll.formattedPeriod,
                ),
              ),
            );
          } else if (state is PayrollError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message)),
                ]),
                backgroundColor: const Color(0xFFB71C1C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          final isCalculating = state is PayrollCalculating;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Calculate Payroll'),
              elevation: 0,
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
                          const Color(0xB3007A3D),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calculate Payroll',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.site.name} · ${_allWorkers.where((w) => _selectedWorkPlaceName == null || (w.workPlaceName ?? 'General Workforce') == _selectedWorkPlaceName).length} Workers',
                          style: TextStyle(
                            color: const Color(0xE6FFFFFF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingWorkers)
                    const LinearProgressIndicator(),
                  if (!_isLoadingWorkers && _workPlaces.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildWorkPlaceChip(
                              null,
                              'All',
                              _allWorkers.length,
                            ),
                            const SizedBox(width: 8),
                            ..._workPlaces.map((wp) {
                              final count = _allWorkers.where((w) => (w.workPlaceName ?? 'General Workforce') == wp).length;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildWorkPlaceChip(
                                  wp,
                                  wp,
                                  count,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Period Configuration',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'ቀን',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: _showEthiopianCalendar ? FontWeight.bold : FontWeight.normal,
                                              color: _showEthiopianCalendar 
                                                  ? Theme.of(context).primaryColor 
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                          Switch(
                                            value: _showEthiopianCalendar,
                                            onChanged: isCalculating ? null : (value) {
                                              setState(() {
                                                _showEthiopianCalendar = value;
                                              });
                                            },
                                            activeColor: Theme.of(context).primaryColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isLoadingWorkTypes)
                                    const Center(child: CircularProgressIndicator())
                                  else
                                    DropdownButtonFormField<int>(
                                      value: _referenceWorkTypeId,
                                      decoration: const InputDecoration(
                                        labelText: 'Reference Work Type (Auto-configures dates)',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.settings_suggest),
                                      ),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Custom Period'),
                                        ),
                                        ..._workTypes.map((wt) => DropdownMenuItem<int>(
                                          value: wt.id,
                                          child: Text(wt.name),
                                        )),
                                      ],
                                      onChanged: isCalculating
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _referenceWorkTypeId = value;
                                                if (value != null) {
                                                  _applyWorkTypePeriodSettings(value);
                                                }
                                              });
                                            },
                                    ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _periodType,
                                    decoration: const InputDecoration(
                                      labelText: 'Period Type',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.event_repeat),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                      DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                                    ],
                                    onChanged: isCalculating
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _periodType = value!;
                                              _setDefaultDates();
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _isCurrentCycleSelected
                                            ? ElevatedButton.icon(
                                                onPressed: isCalculating ? null : _setCurrentPeriod,
                                                icon: const Icon(Icons.today, size: 18),
                                                label: const Text('Current Period'),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  backgroundColor: Theme.of(context).primaryColor,
                                                  foregroundColor: Colors.white,
                                                ),
                                              )
                                            : OutlinedButton.icon(
                                                onPressed: isCalculating ? null : _setCurrentPeriod,
                                                icon: const Icon(Icons.today, size: 18),
                                                label: const Text('Current Period'),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: !_isCurrentCycleSelected
                                            ? ElevatedButton.icon(
                                                onPressed: isCalculating ? null : _setFullMonthPeriod,
                                                icon: const Icon(Icons.calendar_month, size: 18),
                                                label: const Text('Full Month'),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  backgroundColor: Theme.of(context).primaryColor,
                                                  foregroundColor: Colors.white,
                                                ),
                                              )
                                            : OutlinedButton.icon(
                                                onPressed: isCalculating ? null : _setFullMonthPeriod,
                                                icon: const Icon(Icons.calendar_month, size: 18),
                                                label: const Text('Full Month'),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: isCalculating ? null : () => _selectDate(context, true),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Start Date',
                                              border: const OutlineInputBorder(),
                                              prefixIcon: Icon(
                                                _showEthiopianCalendar ? Icons.calendar_month : Icons.date_range,
                                              ),
                                            ),
                                            child: _periodStart != null
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (_showEthiopianCalendar) ...[
                                                        Text(
                                                          EthiopianCalendar.formatEthiopian(
                                                            EthiopianCalendar.fromGregorian(_periodStart!),
                                                            useAmharic: false,
                                                          ),
                                                          style: const TextStyle(
                                                            color: const Color(0xFF1A1A1A),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          dateFormat.format(_periodStart!),
                                                          style: TextStyle(
                                                            color: const Color(0xFF6B7280),
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ] else ...[
                                                        Text(
                                                          dateFormat.format(_periodStart!),
                                                          style: const TextStyle(
                                                            color: const Color(0xFF1A1A1A),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  )
                                                : const Text(
                                                    'Select date',
                                                    style: TextStyle(color: const Color(0xFF9CA3AF)),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: InkWell(
                                          onTap: isCalculating ? null : () => _selectDate(context, false),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'End Date',
                                              border: const OutlineInputBorder(),
                                              prefixIcon: Icon(
                                                _showEthiopianCalendar ? Icons.calendar_month : Icons.date_range,
                                              ),
                                            ),
                                            child: _periodEnd != null
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (_showEthiopianCalendar) ...[
                                                        Text(
                                                          EthiopianCalendar.formatEthiopian(
                                                            EthiopianCalendar.fromGregorian(_periodEnd!),
                                                            useAmharic: false,
                                                          ),
                                                          style: const TextStyle(
                                                            color: const Color(0xFF1A1A1A),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          dateFormat.format(_periodEnd!),
                                                          style: TextStyle(
                                                            color: const Color(0xFF6B7280),
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ] else ...[
                                                        Text(
                                                          dateFormat.format(_periodEnd!),
                                                          style: const TextStyle(
                                                            color: const Color(0xFF1A1A1A),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  )
                                                : const Text(
                                                    'Select date',
                                                    style: TextStyle(color: const Color(0xFF9CA3AF)),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_periodStart != null && _periodEnd != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0x1A1E3A5F),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0x4D1E3A5F),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: const Color(0xFF1E3A5F), size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Period: ${_periodEnd!.difference(_periodStart!).inDays + 1} days',
                                              style: const TextStyle(
                                                color: const Color(0xFF1E3A5F),
                                                fontWeight: FontWeight.w500,
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
                          ),
                          const SizedBox(height: 16),
                          if (_periodStart != null) Card(
                            elevation: 2,
                            color: const Color(0xFFE8F5EE),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        color: const Color(0xFF005C2E),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ethiopian Calendar Period',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF003D1F),
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF005C2E),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Auto-filled',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _ethiopianMonthController,
                                          decoration: InputDecoration(
                                            labelText: 'Ethiopian Month',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.white,
                                            prefixIcon: const Icon(Icons.event),
                                            suffixIcon: const Icon(Icons.lock_outline, size: 16),
                                          ),
                                          readOnly: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _ethiopianYearController,
                                          decoration: InputDecoration(
                                            labelText: 'Ethiopian Year',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.white,
                                            prefixIcon: const Icon(Icons.calendar_today),
                                            suffixIcon: const Icon(Icons.lock_outline, size: 16),
                                          ),
                                          readOnly: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'These values are automatically populated based on your selected start date',
                                    style: TextStyle(
                                      color: const Color(0xFF004A25),
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (isCalculating)
                            Card(
                              color: const Color(0xFFE8EDF4),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Calculating Payroll...',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF071020),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This may take a few moments',
                                      style: TextStyle(
                                        color: const Color(0xFF0A192F),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: isCalculating 
                                  ? null 
                                  : () => _calculatePayroll(context.read<PayrollBloc>()),
                              icon: const Icon(Icons.calculate),
                              label: const Text(
                                'Calculate Payroll',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 1,
                            color: const Color(0xFFE8EDF4),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: const Color(0xFF0A192F), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'What Gets Calculated',
                                        style: TextStyle(
                                          color: const Color(0xFF071020),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildCalculationItem(
                                    icon: Icons.event_available,
                                    text: 'Attendance records & work days',
                                    color: const Color(0xFF0A192F),
                                  ),
                                  _buildCalculationItem(
                                    icon: Icons.access_time,
                                    text: 'Overtime hours & rates',
                                    color: const Color(0xFF0A192F),
                                  ),
                                  _buildCalculationItem(
                                    icon: Icons.remove_circle_outline,
                                    text: 'Deductions & advances',
                                    color: const Color(0xFF0A192F),
                                  ),
                                  _buildCalculationItem(
                                    icon: Icons.receipt_long,
                                    text: 'Income tax & pension contributions',
                                    color: const Color(0xFF0A192F),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x1A007A3D),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x4D007A3D),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, color: const Color(0xFF005C2E), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quick Period Selection',
                                        style: TextStyle(
                                          color: const Color(0xFF003D1F),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '• Current Period: Calculate up to today for real-time earnings tracking\n'
                                        '• Full Month: Calculate entire month for advance planning and budgeting',
                                        style: TextStyle(
                                          color: const Color(0xFF004A25),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x1AE65100),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x4DE65100),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber, color: const Color(0xFFE65100), size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ensure all attendance has been verified before calculating to get accurate results.',
                                    style: TextStyle(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalculationItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Color.fromARGB(230, color.red, color.green, color.blue),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildWorkPlaceChip(String? workPlaceName, String name, int count) {
    final isSelected = _selectedWorkPlaceName == workPlaceName;
    final label = count > 0 ? '$name ($count)' : name == 'All' ? 'All ($count)' : name;

    // Determine if it should be completely hidden due to 0 count
    if (count == 0 && name != 'All') {
      return const SizedBox.shrink(); // Hide chip if count is 0
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedWorkPlaceName = selected ? workPlaceName : null;
        });
      },
      backgroundColor: const Color(0xFFE5E7EB),
      selectedColor: const Color(0x33007A3D),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF1A1A1A),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
