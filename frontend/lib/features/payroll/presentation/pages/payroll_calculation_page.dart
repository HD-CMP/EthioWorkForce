import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/app_snackbar.dart';
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

/// Smart target category for construction & enterprise payrolls
enum PayrollTargetCategory {
  monthlyStaff,
  biweeklyLaborers,
  specificWorkType,
  allWorkforce,
}

/// Optional disbursement channel filter
enum DisbursementFilter {
  all,
  cashPreferred,
  bankTransfer,
  mobileMoney,
}

class PayrollCalculationPage extends StatefulWidget {
  final Site site;
  final bool embedded;

  const PayrollCalculationPage({
    super.key,
    required this.site,
    this.embedded = false,
  });

  @override
  State<PayrollCalculationPage> createState() => _PayrollCalculationPageState();
}

class _PayrollCalculationPageState extends State<PayrollCalculationPage> {
  final _formKey = GlobalKey<FormState>();
  final _workTypeDataSource = WorkTypeRemoteDataSource();
  final _workerDataSource = WorkerRemoteDataSource();

  // Selected Target Category
  PayrollTargetCategory _selectedCategory = PayrollTargetCategory.monthlyStaff;
  DisbursementFilter _selectedDisbursement = DisbursementFilter.all;

  // Specific Work Type Filter
  int? _selectedWorkTypeId;

  // Period Type sent to backend ('monthly', 'biweekly', 'weekly', 'custom')
  String _periodType = 'monthly';
  DateTime? _periodStart;
  DateTime? _periodEnd;

  final TextEditingController _ethiopianMonthController = TextEditingController();
  final TextEditingController _ethiopianYearController = TextEditingController();
  bool _showEthiopianCalendar = true;

  // Workplaces
  List<String> _workPlaces = [];
  final Map<String, int?> _workPlaceNameToId = {};
  String? _selectedWorkPlaceName;

  // Workers & WorkTypes
  List<Worker> _allWorkers = [];
  bool _isLoadingWorkers = false;
  List<WorkType> _workTypes = [];
  bool _isLoadingWorkTypes = false;

  @override
  void initState() {
    super.initState();
    _loadWorkTypes();
    _loadWorkers();
    _applyCategoryDefaults(PayrollTargetCategory.monthlyStaff);
  }

  @override
  void dispose() {
    _ethiopianMonthController.dispose();
    _ethiopianYearController.dispose();
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

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
    } catch (_) {
      if (mounted) setState(() => _isLoadingWorkTypes = false);
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
        AppSnackBar.showError(context, 'Error loading workers: ${e.toString()}');
      }
    }
  }

  // ─── Smart Category & Date Logic ───────────────────────────────────────────

  void _applyCategoryDefaults(PayrollTargetCategory category) {
    _selectedCategory = category;
    final now = DateTime.now();

    if (_showEthiopianCalendar) {
      final ethNow = EthiopianCalendar.fromGregorian(now);

      switch (category) {
        case PayrollTargetCategory.monthlyStaff:
          _periodType = 'monthly';
          _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 1);
          _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 30);
          break;

        case PayrollTargetCategory.biweeklyLaborers:
          _periodType = 'biweekly';
          if (ethNow.day <= 14) {
            _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 1);
            _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 14);
          } else {
            _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 15);
            _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 30);
          }
          break;

        case PayrollTargetCategory.specificWorkType:
          _periodType = 'monthly';
          _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 1);
          _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 30);
          break;

        case PayrollTargetCategory.allWorkforce:
          _periodType = 'custom';
          _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 1);
          _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 30);
          break;
      }
    } else {
      switch (category) {
        case PayrollTargetCategory.monthlyStaff:
          _periodType = 'monthly';
          _periodStart = DateTime(now.year, now.month, 1);
          _periodEnd = DateTime(now.year, now.month + 1, 0);
          break;

        case PayrollTargetCategory.biweeklyLaborers:
          _periodType = 'biweekly';
          if (now.day <= 14) {
            _periodStart = DateTime(now.year, now.month, 1);
            _periodEnd = DateTime(now.year, now.month, 14);
          } else {
            _periodStart = DateTime(now.year, now.month, 15);
            _periodEnd = DateTime(now.year, now.month + 1, 0);
          }
          break;

        case PayrollTargetCategory.specificWorkType:
          _periodType = 'monthly';
          _periodStart = DateTime(now.year, now.month, 1);
          _periodEnd = DateTime(now.year, now.month + 1, 0);
          break;

        case PayrollTargetCategory.allWorkforce:
          _periodType = 'custom';
          _periodStart = DateTime(now.year, now.month, 1);
          _periodEnd = DateTime(now.year, now.month + 1, 0);
          break;
      }
    }

    _updateEthiopianFields();
    setState(() {});
  }

  void _setCycle(int cycleNumber) {
    final now = DateTime.now();
    if (_showEthiopianCalendar) {
      final ethNow = EthiopianCalendar.fromGregorian(now);
      if (cycleNumber == 1) {
        _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 1);
        _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 14);
      } else {
        _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 15);
        _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 30);
      }
    } else {
      if (cycleNumber == 1) {
        _periodStart = DateTime(now.year, now.month, 1);
        _periodEnd = DateTime(now.year, now.month, 14);
      } else {
        _periodStart = DateTime(now.year, now.month, 15);
        _periodEnd = DateTime(now.year, now.month + 1, 0);
      }
    }
    _periodType = 'biweekly';
    _updateEthiopianFields();
    setState(() {});
  }

  void _setFullMonthPeriod() {
    final now = DateTime.now();
    if (_showEthiopianCalendar) {
      final ethNow = EthiopianCalendar.fromGregorian(now);
      _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 1);
      _periodEnd = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 30);
    } else {
      _periodStart = DateTime(now.year, now.month, 1);
      _periodEnd = DateTime(now.year, now.month + 1, 0);
    }
    _periodType = 'monthly';
    _updateEthiopianFields();
    setState(() {});
  }

  void _setCurrentToTodayPeriod() {
    final now = DateTime.now();
    if (_showEthiopianCalendar) {
      final ethNow = EthiopianCalendar.fromGregorian(now);
      _periodStart = EthiopianCalendar.toGregorian(ethNow.year, ethNow.month, 1);
      _periodEnd = now;
    } else {
      _periodStart = DateTime(now.year, now.month, 1);
      _periodEnd = now;
    }
    _updateEthiopianFields();
    setState(() {});
  }

  void _updateEthiopianFields() {
    if (_periodStart != null) {
      final ethDate = EthiopianCalendar.fromGregorian(_periodStart!);
      final monthName = EthiopianCalendar.monthsEnglish[ethDate.month - 1];
      _ethiopianMonthController.text = monthName;
      _ethiopianYearController.text = ethDate.year.toString();
    }
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
      });
    }
  }

  // ─── Filtered Workforce Getters ────────────────────────────────────────────

  List<Worker> get _filteredWorkers {
    return _allWorkers.where((w) {
      // 1. Workplace filter
      if (_selectedWorkPlaceName != null &&
          (w.workPlaceName ?? 'General Workforce') != _selectedWorkPlaceName) {
        return false;
      }

      // 2. Target Category filter
      switch (_selectedCategory) {
        case PayrollTargetCategory.monthlyStaff:
          final isStaff = (w.hierarchyLevel != null && w.hierarchyLevel! <= 4) ||
              (w.paymentPeriodDays != null && w.paymentPeriodDays! >= 28);
          if (!isStaff) return false;
          break;

        case PayrollTargetCategory.biweeklyLaborers:
          final isLaborer = (w.hierarchyLevel == null || w.hierarchyLevel! >= 5) ||
              (w.paymentPeriodDays == null || w.paymentPeriodDays! <= 14);
          if (!isLaborer) return false;
          break;

        case PayrollTargetCategory.specificWorkType:
          if (_selectedWorkTypeId != null && w.workTypeId != _selectedWorkTypeId) {
            return false;
          }
          break;

        case PayrollTargetCategory.allWorkforce:
          break;
      }

      // 3. Disbursement Preference filter
      switch (_selectedDisbursement) {
        case DisbursementFilter.all:
          break;
        case DisbursementFilter.cashPreferred:
          // Workers who don't have bank accounts, or designated cash recipients
          final hasBank = w.bankAccountNumber != null && w.bankAccountNumber!.trim().isNotEmpty;
          if (hasBank) return false;
          break;
        case DisbursementFilter.bankTransfer:
          final hasBank = w.bankAccountNumber != null && w.bankAccountNumber!.trim().isNotEmpty;
          if (!hasBank) return false;
          break;
        case DisbursementFilter.mobileMoney:
          final hasPhone = w.phoneNumber != null && w.phoneNumber!.trim().isNotEmpty;
          if (!hasPhone) return false;
          break;
      }

      return true;
    }).toList();
  }

  int get _matchingCount => _filteredWorkers.length;

  int get _cashRecipientCount => _filteredWorkers.where((w) =>
      w.bankAccountNumber == null || w.bankAccountNumber!.trim().isEmpty).length;

  int get _bankRecipientCount => _filteredWorkers.where((w) =>
      w.bankAccountNumber != null && w.bankAccountNumber!.trim().isNotEmpty).length;

  int get _mobileMoneyRecipientCount => _filteredWorkers.where((w) =>
      w.phoneNumber != null && w.phoneNumber!.trim().isNotEmpty).length;

  double get _estimatedBaseGross {
    double total = 0.0;
    for (final w in _filteredWorkers) {
      if (w.baseSalary != null && w.baseSalary! > 0) {
        total += w.baseSalary!;
      } else if (w.workTypeId != null && _workTypes.isNotEmpty) {
        final wt = _workTypes.where((t) => t.id == w.workTypeId).firstOrNull;
        if (wt != null) total += wt.baseRate;
      }
    }
    return total;
  }

  // ─── Payroll Calculation Submission ────────────────────────────────────────

  void _onCalculatePressed(PayrollBloc bloc) {
    if (!_formKey.currentState!.validate()) return;

    if (_periodStart == null || _periodEnd == null) {
      AppSnackBar.showWarning(context, 'Please select both start and end dates');
      return;
    }

    if (_periodEnd!.isBefore(_periodStart!)) {
      AppSnackBar.showWarning(context, 'End date must be after start date');
      return;
    }

    if (_matchingCount == 0) {
      AppSnackBar.showWarning(context, 'No active workers matched the selected criteria');
      return;
    }

    // Show Confirmation Sheet before generating
    _showConfirmationBottomSheet(bloc);
  }

  void _showConfirmationBottomSheet(PayrollBloc bloc) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final startFormatted = _showEthiopianCalendar
        ? EthiopianCalendar.formatEthiopian(EthiopianCalendar.fromGregorian(_periodStart!), useAmharic: true)
        : dateFormat.format(_periodStart!);
    final endFormatted = _showEthiopianCalendar
        ? EthiopianCalendar.formatEthiopian(EthiopianCalendar.fromGregorian(_periodEnd!), useAmharic: true)
        : dateFormat.format(_periodEnd!);

    String categoryTitle = 'Monthly Staff';
    if (_selectedCategory == PayrollTargetCategory.biweeklyLaborers) {
      categoryTitle = '14-Day Laborers (Bi-Weekly)';
    } else if (_selectedCategory == PayrollTargetCategory.specificWorkType) {
      final wt = _workTypes.where((t) => t.id == _selectedWorkTypeId).firstOrNull;
      categoryTitle = 'Specific Trade: ${wt?.name ?? "Selected Work Type"}';
    } else if (_selectedCategory == PayrollTargetCategory.allWorkforce) {
      categoryTitle = 'All Site Workforce (Multi-Cycle)';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calculate_rounded, color: Color(0xFF007A3D), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Payroll Calculation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
                      ),
                      Text(
                        'Audit batch parameters before calculation',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _buildAuditRow('Site', widget.site.name, Icons.location_on_outlined),
            _buildAuditRow('Target Group', categoryTitle, Icons.people_outline_rounded),
            _buildAuditRow('Period Dates', '$startFormatted → $endFormatted', Icons.date_range_rounded),
            _buildAuditRow('Eligible Workers', '$_matchingCount Active Workers', Icons.badge_outlined),
            _buildAuditRow(
              'Disbursement Modes',
              '💵 Cash: $_cashRecipientCount | 🏦 Bank: $_bankRecipientCount | 📱 Mobile: $_mobileMoneyRecipientCount',
              Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Review Settings'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeCalculation(bloc);
                    },
                    icon: const Icon(Icons.flash_on_rounded, size: 18),
                    label: const Text('Calculate Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A3D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
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

  Widget _buildAuditRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF007A3D)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }

  void _executeCalculation(PayrollBloc bloc) {
    // Map periodType appropriately
    String resolvedPeriodType = _periodType;
    if (_selectedCategory == PayrollTargetCategory.monthlyStaff) {
      resolvedPeriodType = 'monthly';
    } else if (_selectedCategory == PayrollTargetCategory.biweeklyLaborers) {
      resolvedPeriodType = 'biweekly';
    } else if (_selectedCategory == PayrollTargetCategory.allWorkforce) {
      resolvedPeriodType = 'custom';
    }

    final int? targetWorkTypeId =
        _selectedCategory == PayrollTargetCategory.specificWorkType ? _selectedWorkTypeId : null;
    final int? targetWorkPlaceId =
        _selectedWorkPlaceName != null ? _workPlaceNameToId[_selectedWorkPlaceName] : null;

    bloc.add(
      CreateAndCalculatePayroll(
        siteId: widget.site.id!,
        periodType: resolvedPeriodType,
        periodStart: _periodStart!,
        periodEnd: _periodEnd!,
        ethiopianMonth: _ethiopianMonthController.text.isEmpty ? null : _ethiopianMonthController.text,
        ethiopianYear: int.tryParse(_ethiopianYearController.text),
        workTypeId: targetWorkTypeId,
        workPlaceId: targetWorkPlaceId,
      ),
    );
  }

  // ─── Build Method ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return BlocProvider(
      create: (_) => getIt<PayrollBloc>(),
      child: BlocConsumer<PayrollBloc, PayrollState>(
        listener: (context, state) {
          if (state is PayrollCalculated) {
            AppSnackBar.showSuccess(
              context,
              'Payroll calculated successfully: ${state.payroll.payrollCode}',
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
            AppSnackBar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isCalculating = state is PayrollCalculating;

          return Scaffold(
            backgroundColor: const Color(0xFFF4F7F4),
            appBar: widget.embedded
                ? null
                : AppBar(
                    backgroundColor: const Color(0xFF007A3D),
                    foregroundColor: Colors.white,
                    title: const Text('Calculate Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
                    elevation: 0,
                  ),
            body: SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Branded Banner ──────────────────────────────────────────
                    _buildHeaderBanner(),

                    // ─── Workplaces Filter Strip ─────────────────────────────────
                    if (_isLoadingWorkers)
                      const LinearProgressIndicator(color: Color(0xFF007A3D))
                    else if (_workPlaces.isNotEmpty)
                      _buildWorkPlacesFilter(),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Card 1: Target Category Selector ───────────────
                            _buildTargetCategorySection(isCalculating),
                            const SizedBox(height: 16),

                            // ─── Card 2: Period & Calendar Configuration ─────────
                            _buildPeriodConfigurationCard(context, dateFormat, isCalculating),
                            const SizedBox(height: 16),

                            // ─── Card 3: Disbursement Preference Filter ───────────
                            _buildDisbursementFilterCard(isCalculating),
                            const SizedBox(height: 16),

                            // ─── Card 4: Live Pre-Calculation Workforce Audit ─────
                            _buildLiveAuditCard(),
                            const SizedBox(height: 24),

                            // ─── Submit Button ───────────────────────────────────
                            if (isCalculating)
                              _buildCalculatingCard()
                            else
                              _buildSubmitButton(context),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── UI Helper Widgets ─────────────────────────────────────────────────────

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF005C2E), Color(0xFF007A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Construction Payroll',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.site.name} • ${_allWorkers.length} Registered Workers',
                      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderBadge(
                '🏢 Monthly Staff: ${_allWorkers.where((w) => (w.hierarchyLevel != null && w.hierarchyLevel! <= 4) || (w.paymentPeriodDays != null && w.paymentPeriodDays! >= 28)).length}',
              ),
              _buildHeaderBadge(
                '👷 14-Day Laborers: ${_allWorkers.where((w) => (w.hierarchyLevel == null || w.hierarchyLevel! >= 5) || (w.paymentPeriodDays == null || w.paymentPeriodDays! <= 14)).length}',
              ),
              _buildHeaderBadge(
                '💳 Multi-Channel (Bank/Cash/Telebirr)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4DFFFFFF)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildWorkPlacesFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildWorkPlaceChip(null, 'All Workplaces', _allWorkers.length),
            const SizedBox(width: 8),
            ..._workPlaces.map((wp) {
              final count = _allWorkers.where((w) => (w.workPlaceName ?? 'General Workforce') == wp).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildWorkPlaceChip(wp, wp, count),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkPlaceChip(String? workPlaceName, String name, int count) {
    final isSelected = _selectedWorkPlaceName == workPlaceName;
    return FilterChip(
      label: Text('$name ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedWorkPlaceName = selected ? workPlaceName : null;
        });
      },
      backgroundColor: const Color(0xFFF3F4F6),
      selectedColor: const Color(0xFFE8F5EE),
      checkmarkColor: const Color(0xFF007A3D),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF007A3D) : const Color(0xFF374151),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  // ─── Target Category Card ──────────────────────────────────────────────────

  Widget _buildTargetCategorySection(bool isCalculating) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A3D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '1. Select Workforce Target Group',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Aligns calculation formulas, cycles, and tax deductions to real-world roles',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),

            // Target Option 1: Monthly Staff
            _buildCategoryTile(
              category: PayrollTargetCategory.monthlyStaff,
              title: 'Monthly Salaried Staff',
              amharicTitle: 'የወርሃዊ ቋሚ ሠራተኞች (መሐንዲሶችና አስተዳደር)',
              subtitle: 'Site Engineers, Foremen & Supervisory Management (Levels 1–4)',
              icon: Icons.business_center_rounded,
              badge: '${_allWorkers.where((w) => (w.hierarchyLevel != null && w.hierarchyLevel! <= 4) || (w.paymentPeriodDays != null && w.paymentPeriodDays! >= 28)).length} matched',
              isCalculating: isCalculating,
            ),
            const SizedBox(height: 10),

            // Target Option 2: 14-Day Laborers
            _buildCategoryTile(
              category: PayrollTargetCategory.biweeklyLaborers,
              title: '14-Day Workforce (Bi-Weekly)',
              amharicTitle: 'የ14 ቀን የቀን ሠራተኞች (ጉልበትና ሙያተኞች)',
              subtitle: 'Daily Laborers, Masons, Carpenters & Trades (Levels 5–6)',
              icon: Icons.engineering_rounded,
              badge: '${_allWorkers.where((w) => (w.hierarchyLevel == null || w.hierarchyLevel! >= 5) || (w.paymentPeriodDays == null || w.paymentPeriodDays! <= 14)).length} matched',
              isCalculating: isCalculating,
            ),
            const SizedBox(height: 10),

            // Target Option 3: Specific Work Type
            _buildCategoryTile(
              category: PayrollTargetCategory.specificWorkType,
              title: 'Specific Trade / Work Type',
              amharicTitle: 'በተወሰነ የሥራ ዓይነት ብቻ (ለምሳሌ ግንበኛ ብቻ)',
              subtitle: 'Filter and calculate payroll strictly for a single trade',
              icon: Icons.handyman_rounded,
              badge: _selectedWorkTypeId != null ? 'Trade selected' : 'Pick trade',
              isCalculating: isCalculating,
            ),

            if (_selectedCategory == PayrollTargetCategory.specificWorkType) ...[
              const SizedBox(height: 12),
              _isLoadingWorkTypes
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _selectedWorkTypeId,
                      decoration: InputDecoration(
                        labelText: 'Select Specific Work Type',
                        prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF007A3D)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF007A3D), width: 2),
                        ),
                      ),
                      items: _workTypes.map((wt) {
                        final modeLabel = wt.paymentMode == PaymentMode.monthlySalary
                            ? 'Monthly'
                            : '${wt.paymentPeriodDays ?? 14}d Cycle';
                        return DropdownMenuItem<int>(
                          value: wt.id,
                          child: Text('${wt.name} (${wt.baseRate.toStringAsFixed(0)} ETB - $modeLabel)'),
                        );
                      }).toList(),
                      onChanged: isCalculating
                          ? null
                          : (val) {
                              setState(() {
                                _selectedWorkTypeId = val;
                                if (val != null) {
                                  final wt = _workTypes.where((t) => t.id == val).firstOrNull;
                                  if (wt != null) {
                                    _periodType = wt.paymentMode == PaymentMode.monthlySalary ? 'monthly' : 'biweekly';
                                  }
                                }
                              });
                            },
                    ),
            ],
            const SizedBox(height: 10),

            // Target Option 4: All Workforce (Multi-Cycle)
            _buildCategoryTile(
              category: PayrollTargetCategory.allWorkforce,
              title: 'All Site Workforce (Smart Multi-Cycle)',
              amharicTitle: 'ጠቅላላ የሳይቱ ሠራተኞች (የተደባለቀ ዑደት)',
              subtitle: 'Full site run — backend applies dual-cycle intelligence without cross proration',
              icon: Icons.hub_rounded,
              badge: '${_allWorkers.length} total',
              isCalculating: isCalculating,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required PayrollTargetCategory category,
    required String title,
    required String amharicTitle,
    required String subtitle,
    required IconData icon,
    required String badge,
    required bool isCalculating,
  }) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: isCalculating ? null : () => _applyCategoryDefaults(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5EE) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                size: 20,
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
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF005C2E) : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0x33007A3D) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFF007A3D) : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amharicTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? const Color(0xFF007A3D) : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Period & Calendar Configuration Card ──────────────────────────────────

  Widget _buildPeriodConfigurationCard(
    BuildContext context,
    DateFormat dateFormat,
    bool isCalculating,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
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
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007A3D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '2. Payment Period & Calendar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
                    ),
                  ],
                ),
                // Ethiopian Calendar Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showEthiopianCalendar ? 'የኢትዮጵያ ዘመን (E.C.)' : 'Gregorian (G.C.)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _showEthiopianCalendar ? const Color(0xFF007A3D) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: _showEthiopianCalendar,
                      onChanged: isCalculating
                          ? null
                          : (value) {
                              setState(() {
                                _showEthiopianCalendar = value;
                                _applyCategoryDefaults(_selectedCategory);
                              });
                            },
                      activeColor: const Color(0xFF007A3D),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Cycle Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCyclePresetButton(
                    label: 'Full Month (1–30)',
                    icon: Icons.calendar_month_rounded,
                    isSelected: _periodType == 'monthly',
                    onTap: isCalculating ? null : _setFullMonthPeriod,
                  ),
                  const SizedBox(width: 8),
                  _buildCyclePresetButton(
                    label: 'Cycle 1 (1–14)',
                    icon: Icons.looks_one_rounded,
                    isSelected: _periodType == 'biweekly' && (_periodStart?.day ?? 0) <= 14,
                    onTap: isCalculating ? null : () => _setCycle(1),
                  ),
                  const SizedBox(width: 8),
                  _buildCyclePresetButton(
                    label: 'Cycle 2 (15–30)',
                    icon: Icons.looks_two_rounded,
                    isSelected: _periodType == 'biweekly' && (_periodStart?.day ?? 0) >= 15,
                    onTap: isCalculating ? null : () => _setCycle(2),
                  ),
                  const SizedBox(width: 8),
                  _buildCyclePresetButton(
                    label: 'To Today',
                    icon: Icons.today_rounded,
                    isSelected: false,
                    onTap: isCalculating ? null : _setCurrentToTodayPeriod,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date Selection Pickers
            Row(
              children: [
                Expanded(
                  child: _buildDateInputTile(
                    label: 'Period Start Date',
                    date: _periodStart,
                    dateFormat: dateFormat,
                    isStart: true,
                    onTap: isCalculating ? null : () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateInputTile(
                    label: 'Period End Date',
                    date: _periodEnd,
                    dateFormat: dateFormat,
                    isStart: false,
                    onTap: isCalculating ? null : () => _selectDate(context, false),
                  ),
                ),
              ],
            ),

            if (_periodStart != null && _periodEnd != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0A192F), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Calendar Days: ${_periodEnd!.difference(_periodStart!).inDays + 1} days '
                        '(${_periodType.toUpperCase()})',
                        style: const TextStyle(color: Color(0xFF0A192F), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Ethiopian Metadata Auto-Fill
            if (_periodStart != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF007A3D), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ethiopian Fiscal Month Tag',
                            style: TextStyle(fontSize: 11, color: Color(0xFF005C2E), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_ethiopianMonthController.text} ${_ethiopianYearController.text} ዓ.ም.',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF003D1F)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007A3D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Auto', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCyclePresetButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF4B5563)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInputTile({
    required String label,
    required DateTime? date,
    required DateFormat dateFormat,
    required bool isStart,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            if (date != null) ...[
              if (_showEthiopianCalendar) ...[
                Text(
                  EthiopianCalendar.formatEthiopian(
                    EthiopianCalendar.fromGregorian(date),
                    useAmharic: true,
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                ),
              ] else ...[
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
              ],
            ] else ...[
              const Text('Select Date', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Disbursement Filter Card ──────────────────────────────────────────────

  Widget _buildDisbursementFilterCard(bool isCalculating) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A3D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '3. Disbursement Channel Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Both 14-day workers and staff can receive via Cash Sheet, Bank, or Mobile Money',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDisbursementChip(
                  filter: DisbursementFilter.all,
                  label: 'All Channels',
                  icon: Icons.all_inclusive_rounded,
                  count: _matchingCount,
                  isCalculating: isCalculating,
                ),
                _buildDisbursementChip(
                  filter: DisbursementFilter.cashPreferred,
                  label: '💵 Cash Preferred',
                  icon: Icons.payments_outlined,
                  count: _cashRecipientCount,
                  isCalculating: isCalculating,
                ),
                _buildDisbursementChip(
                  filter: DisbursementFilter.bankTransfer,
                  label: '🏦 Bank Transfer (CBE/Dashen/Awash)',
                  icon: Icons.account_balance_outlined,
                  count: _bankRecipientCount,
                  isCalculating: isCalculating,
                ),
                _buildDisbursementChip(
                  filter: DisbursementFilter.mobileMoney,
                  label: '📱 Mobile Money (Telebirr/M-Pesa)',
                  icon: Icons.phone_android_outlined,
                  count: _mobileMoneyRecipientCount,
                  isCalculating: isCalculating,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisbursementChip({
    required DisbursementFilter filter,
    required String label,
    required IconData icon,
    required int count,
    required bool isCalculating,
  }) {
    final isSelected = _selectedDisbursement == filter;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: isCalculating
          ? null
          : (val) {
              setState(() {
                _selectedDisbursement = val ? filter : DisbursementFilter.all;
              });
            },
      backgroundColor: const Color(0xFFF3F4F6),
      selectedColor: const Color(0xFFE8F5EE),
      checkmarkColor: const Color(0xFF007A3D),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? const Color(0xFF007A3D) : const Color(0xFF374151),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF007A3D) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  // ─── Live Pre-Calculation Workforce Audit Card ─────────────────────────────

  Widget _buildLiveAuditCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF007A3D), width: 1.5),
      ),
      color: const Color(0xFFF9FDFB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF007A3D), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Live Pre-Calculation Audit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF005C2E)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A3D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_matchingCount Workers',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Base Gross', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      Text(
                        '${_estimatedBaseGross.toStringAsFixed(2)} ETB',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF007A3D)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disbursement Breakdown', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      Text(
                        '💵 Cash: $_cashRecipientCount | 🏦 Bank: $_bankRecipientCount',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
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

  // ─── Submit Action & Calculating State ─────────────────────────────────────

  Widget _buildCalculatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF007A3D)),
          SizedBox(height: 16),
          Text(
            'Calculating Smart Payroll...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
          ),
          SizedBox(height: 6),
          Text(
            'Auditing attendance records, overtime hours, and ERCA progressive tax brackets',
            style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      child: ElevatedButton.icon(
        onPressed: () => _onCalculatePressed(context.read<PayrollBloc>()),
        icon: const Icon(Icons.flash_on_rounded, size: 22),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Calculate & Generate Payroll ($_matchingCount Workers)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007A3D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
      ),
    );
  }
}
