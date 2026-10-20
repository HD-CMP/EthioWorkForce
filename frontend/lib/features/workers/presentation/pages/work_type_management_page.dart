import 'package:flutter/material.dart';

import '../../domain/entities/work_type.dart';
import '../../data/datasources/work_type_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/ethiopian_date_picker.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import 'work_type_detail_page.dart';

class WorkTypeManagementPage extends StatefulWidget {
  const WorkTypeManagementPage({super.key});

  @override
  State<WorkTypeManagementPage> createState() => _WorkTypeManagementPageState();
}

class _WorkTypeManagementPageState extends State<WorkTypeManagementPage> with SingleTickerProviderStateMixin {
  final _datasource = WorkTypeRemoteDataSource();
  List<WorkType> _workTypes = [];
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _loadWorkTypes();
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workTypes = await _datasource.getWorkTypes();
      if (mounted) {
        setState(() {
          _workTypes = workTypes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg;
        
        if (e is ApiException) {
          if (e.message.toLowerCase().contains('offline mode')) {
            errorMsg = 'App is in offline mode. Please disable offline mode in settings.';
          } else if (e.statusCode == 404) {
            errorMsg = 'No work types found in the system. Create your first work type to get started.';
          } else if (e.statusCode == 401 || e.statusCode == 403) {
            errorMsg = e.displayMessage;
          } else if (e.userMessage?.toLowerCase().contains('not authenticated') ?? false) {
            errorMsg = 'Please log in to view work types.';
          } else if ((e.userMessage?.toLowerCase().contains('network') ?? false) || 
                     (e.userMessage?.toLowerCase().contains('connection') ?? false)) {
            errorMsg = 'Unable to connect to server. Check your internet or backend URL in settings.';
          } else {
            errorMsg = '${e.displayMessage}\n\nTechnical: ${e.message}';
          }
        } else {
          errorMsg = 'Failed to load work types: $e';
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  Future<void> _showWorkTypeDialog([WorkType? workType]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WorkTypeFormDialog(workType: workType),
    );

    if (result == true) {
      _loadWorkTypes();
    }
  }

  Future<void> _deleteWorkType(WorkType workType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Work Type'),
        content: Text('Are you sure you want to delete "${workType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB71C1C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && workType.id != null) {
      try {
        await _datasource.deleteWorkType(workType.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Work type deleted successfully'),
              ]),
              backgroundColor: const Color(0xFF007A3D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          _loadWorkTypes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(e is ApiException ? e.displayMessage : 'Failed to delete work type')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Types'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xB3FFFFFF),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.manage_accounts),
              text: 'Manage',
            ),
            Tab(
              icon: Icon(Icons.view_list),
              text: 'View All',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(context)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildManageTab(),
                    _buildViewAllTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 0 && _errorMessage == null
          ? FloatingActionButton.extended(
              onPressed: () => _showWorkTypeDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Work Type'),
            )
          : null,
    );
  }

  Widget _buildManageTab() {
    if (_workTypes.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: _workTypes.length,
      itemBuilder: (context, index) {
        final workType = _workTypes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: workType.isActive
                  ? const Color(0xFF007A3D)
                  : const Color(0xFF9CA3AF),
              child: const Icon(Icons.work, color: Colors.white),
            ),
            title: Text(
              workType.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code: ${workType.code}',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    workType.hierarchyLevel >= 5
                        ? '${workType.paymentMode.displayName} • ETB ${workType.baseRate.toStringAsFixed(2)}'
                        : '${workType.paymentMode.displayName} • ⭐ Per Worker',
                    style: TextStyle(
                      color: workType.hierarchyLevel >= 5 ? const Color(0xFF374151) : const Color(0xFFE65100),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: workType.isActive 
                        ? const Color(0xFFE8F5EE) 
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: workType.isActive 
                          ? const Color(0xFF66B28A) 
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  child: Text(
                    workType.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: workType.isActive 
                          ? const Color(0xFF003D1F) 
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showWorkTypeDialog(workType),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: const Color(0xFFB71C1C), size: 20),
                  onPressed: () => _deleteWorkType(workType),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewAllTab() {
    if (_workTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 80, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No Work Types Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create work types in the Manage tab',
              style: TextStyle(color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _workTypes.length,
      itemBuilder: (context, index) {
        final workType = _workTypes[index];
        return _buildWorkTypeCard(workType);
      },
    );
  }

  Widget _buildWorkTypeCard(WorkType workType) {
    String getHierarchyLabel(int level) {
      switch (level) {
        case 1: return 'Executive';
        case 2: return 'Senior Mgmt';
        case 3: return 'Middle Mgmt';
        case 4: return 'Supervisory';
        case 5: return 'Operational';
        case 6: return 'Trainee';
        default: return 'Level $level';
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkTypeDetailPage(workType: workType),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: workType.isActive ? Colors.white : const Color(0xFFF3F4F6),
            border: Border.all(
              color: workType.isActive
                  ? const Color(0x26007A3D)
                  : const Color(0xFFD1D5DB),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: workType.isActive ? const Color(0xFF007A3D) : const Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: workType.isActive ? const Color(0xFF007A3D) : const Color(0xFF6B7280),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workType.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                workType.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF1A1A1A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                workType.code,
                style: TextStyle(
                  color: const Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Divider(height: 16),
              Row(
                children: [
                  Icon(Icons.payments, size: 16, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      workType.paymentMode.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(
                    workType.hierarchyLevel >= 5
                        ? 'ETB ${workType.baseRate.toStringAsFixed(2)}'
                        : '⭐ Per Worker',
                    style: TextStyle(
                      fontSize: 12,
                      color: workType.hierarchyLevel >= 5
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.stairs, size: 16, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      getHierarchyLabel(workType.hierarchyLevel),
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_outline,
                size: 80,
                color: const Color(0xFF64B5F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Work Types Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Work types define payment structures, tax rules,\nand organizational hierarchy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showWorkTypeDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Work Type'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final bool isNoDataError = _errorMessage!.toLowerCase().contains('no work types found');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isNoDataError ? const Color(0xFFE8EDF4) : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoDataError ? Icons.info_outline : Icons.error_outline,
                size: 80,
                color: isNoDataError ? const Color(0xFF64B5F6) : const Color(0xFFE57373),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNoDataError ? 'No Work Types Found' : 'Unable to Load Work Types',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isNoDataError) ...[
              ElevatedButton.icon(
                onPressed: () => _showWorkTypeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Work Type'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _loadWorkTypes,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkTypeFormDialog extends StatefulWidget {
  final WorkType? workType;

  const WorkTypeFormDialog({super.key, this.workType});

  @override
  State<WorkTypeFormDialog> createState() => _WorkTypeFormDialogState();
}

class _WorkTypeFormDialogState extends State<WorkTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _datasource = WorkTypeRemoteDataSource();
  
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _baseRateController;
  late TextEditingController _paymentPeriodDaysController;
  late TextEditingController _overtimeRatePerHourController;
  late TextEditingController _employeePensionRateController;
  late TextEditingController _employerPensionRateController;
  late TextEditingController _maxSubordinatesController;
  
  late PaymentMode _paymentMode;
  late TaxRule _taxRule;
  late bool _isActive;
  late bool _overtimeEligible;
  late bool _pensionEligible;
  late int _hierarchyLevel;
  late bool _requiresSupervisor;
  DateTime? _paymentPeriodStartDate;
  bool _showEthiopianCalendar = true;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workType?.name ?? '');
    _codeController = TextEditingController(text: widget.workType?.code ?? '');
    _descriptionController = TextEditingController(text: widget.workType?.description ?? '');
    _baseRateController = TextEditingController(
      text: widget.workType?.baseRate.toString() ?? '',
    );
    _paymentPeriodDaysController = TextEditingController(
      text: widget.workType?.paymentPeriodDays?.toString() ?? '',
    );
    _overtimeRatePerHourController = TextEditingController(
      text: widget.workType?.overtimeRatePerHour?.toString() ?? '',
    );
    _employeePensionRateController = TextEditingController(
      text: widget.workType?.employeePensionRate?.toString() ?? '0.07',
    );
    _employerPensionRateController = TextEditingController(
      text: widget.workType?.employerPensionRate?.toString() ?? '0.11',
    );
    _maxSubordinatesController = TextEditingController(
      text: widget.workType?.maxSubordinates?.toString() ?? '',
    );
    
    _paymentMode = widget.workType?.paymentMode ?? PaymentMode.dailyRate;
    _taxRule = widget.workType?.taxRule ?? TaxRule.standardEmployee;
    _isActive = widget.workType?.isActive ?? true;
    _overtimeEligible = widget.workType?.overtimeEligible ?? false;
    _pensionEligible = widget.workType?.pensionEligible ?? true;
    _hierarchyLevel = widget.workType?.hierarchyLevel ?? 5;
    _requiresSupervisor = widget.workType?.requiresSupervisor ?? true;
    _paymentPeriodStartDate = widget.workType?.paymentPeriodStartDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _baseRateController.dispose();
    _paymentPeriodDaysController.dispose();
    _overtimeRatePerHourController.dispose();
    _employeePensionRateController.dispose();
    _employerPensionRateController.dispose();
    _maxSubordinatesController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // For hierarchy 1-4, base_rate is not used — salary is per worker.
      // We store 0.0 as a placeholder so the DB constraint is satisfied.
      final bool isIndividualSalaryLevel = _hierarchyLevel <= 4;
      final double effectiveBaseRate = isIndividualSalaryLevel
          ? 0.0
          : double.parse(_baseRateController.text.trim());

      final workType = WorkType(
        id: widget.workType?.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        paymentMode: _paymentMode,
        baseRate: effectiveBaseRate,
        paymentPeriodDays: _paymentPeriodDaysController.text.trim().isEmpty
            ? null
            : int.tryParse(_paymentPeriodDaysController.text.trim()),
        paymentPeriodStartDate: _paymentPeriodStartDate,
        taxRule: _taxRule,
        overtimeEligible: _overtimeEligible,
        overtimeRatePerHour: _overtimeEligible 
            ? double.tryParse(_overtimeRatePerHourController.text.trim()) 
            : null,
        pensionEligible: _pensionEligible,
        employeePensionRate: _pensionEligible 
            ? double.tryParse(_employeePensionRateController.text.trim()) 
            : null,
        employerPensionRate: _pensionEligible 
            ? double.tryParse(_employerPensionRateController.text.trim()) 
            : null,
        hierarchyLevel: _hierarchyLevel,
        requiresSupervisor: _requiresSupervisor,
        maxSubordinates: _maxSubordinatesController.text.trim().isEmpty
            ? null
            : int.tryParse(_maxSubordinatesController.text.trim()),
        isActive: _isActive,
      );

      if (widget.workType == null) {
        await _datasource.createWorkType(workType);
      } else {
        await _datasource.updateWorkType(workType);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.workType == null 
                    ? 'Work type created successfully' 
                    : 'Work type updated successfully'),
              ),
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(e is ApiException ? e.displayMessage : 'Failed to save work type')),
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
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.workType == null ? 'Add New Work Type' : 'Edit Work Type',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── STEP 1: Identity ─────────────────────────────────
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Work Type Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true 
                            ? 'Work type name is required' 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Work Type Code *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                          helperText: 'Short unique code (e.g. DL, SM, CEO)',
                        ),
                        enabled: widget.workType == null,
                        validator: (value) => value?.trim().isEmpty ?? true 
                            ? 'Work type code is required' 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 2,
                      ),

                      // ── STEP 2: Hierarchy (FIRST — drives salary logic) ──
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Organizational Hierarchy',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the hierarchy level first — it determines how salary is configured.',
                        style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _hierarchyLevel,
                        decoration: const InputDecoration(
                          labelText: 'Hierarchy Level *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.stairs),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 - Executive (CEO, Director)')),
                          DropdownMenuItem(value: 2, child: Text('2 - Senior Management')),
                          DropdownMenuItem(value: 3, child: Text('3 - Middle Management')),
                          DropdownMenuItem(value: 4, child: Text('4 - Supervisory (Team Leads)')),
                          DropdownMenuItem(value: 5, child: Text('5 - Operational (Workers)')),
                          DropdownMenuItem(value: 6, child: Text('6 - Trainee / Apprentice')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _hierarchyLevel = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── STEP 3: Salary Configuration (conditional) ───────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => SizeTransition(
                          sizeFactor: animation,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: _hierarchyLevel >= 5
                          ? Column(
                              key: const ValueKey('base_rate_field'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Info banner for operational/trainee
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EDF4),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF90CAF9)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.group_outlined, color: const Color(0xFF0A192F), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _hierarchyLevel == 5
                                            ? 'Operational workers share this base rate. All workers with this Work Type are paid the same rate.'
                                            : 'Trainee / Apprentice workers share this base rate. All workers with this Work Type are paid the same rate.',
                                          style: TextStyle(fontSize: 12, color: const Color(0xFF0A192F), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<PaymentMode>(
                                  value: _paymentMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Mode *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.payments_outlined),
                                  ),
                                  items: PaymentMode.values.map((mode) {
                                    return DropdownMenuItem(
                                      value: mode,
                                      child: Text(mode.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _paymentMode = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _baseRateController,
                                  decoration: InputDecoration(
                                    labelText: 'Base Rate (Shared for all workers) *',
                                    border: const OutlineInputBorder(),
                                    prefixText: 'ETB ',
                                    prefixIcon: const Icon(Icons.attach_money),
                                    helperText: _paymentMode == PaymentMode.dailyRate
                                        ? 'Daily rate applied to all ${_hierarchyLevel == 5 ? "Operational" : "Trainee"} workers'
                                        : _paymentMode == PaymentMode.monthlySalary
                                            ? 'Monthly salary applied to all ${_hierarchyLevel == 5 ? "Operational" : "Trainee"} workers'
                                            : 'Rate applied to all ${_hierarchyLevel == 5 ? "Operational" : "Trainee"} workers',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value?.trim().isEmpty ?? true) {
                                      return 'Base rate is required for this hierarchy level';
                                    }
                                    if (double.tryParse(value!) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('individual_salary_info'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Info banner for management/executive roles
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFFFFF3E0), const Color(0xFFFFF3E0)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFFB74D)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.stars_rounded, color: const Color(0xFFA52800), size: 22),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Individual Salary Role',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF701700),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'This role is Hierarchy Level $_hierarchyLevel. Each worker registered under this Work Type will have their own individual base salary specified during registration.',
                                        style: TextStyle(fontSize: 12, color: const Color(0xFF701700), height: 1.4),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'No shared base rate is needed here.',
                                        style: TextStyle(fontSize: 12, color: const Color(0xFFE65100), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Still allow setting payment mode for categorization
                                DropdownButtonFormField<PaymentMode>(
                                  value: _paymentMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Mode *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.payments_outlined),
                                    helperText: 'Used for payroll period calculation',
                                  ),
                                  items: PaymentMode.values.map((mode) {
                                    return DropdownMenuItem(
                                      value: mode,
                                      child: Text(mode.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _paymentMode = value);
                                  },
                                ),
                              ],
                            ),
                      ),

                      // ── STEP 4: Payment Period ────────────────────────────
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentPeriodDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Period Days',
                          border: OutlineInputBorder(),
                          helperText: 'e.g., 14 for bi-weekly, 30 for monthly (optional)',
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return null;
                          }
                          final days = int.tryParse(value!);
                          if (days == null || days < 1 || days > 365) {
                            return 'Enter a value between 1 and 365';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showEthiopianDatePicker(
                            context: context,
                            initialDate: _paymentPeriodStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            showEthiopian: _showEthiopianCalendar,
                          );
                          if (picked != null) {
                            setState(() {
                              _paymentPeriodStartDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Period Start Date',
                            border: OutlineInputBorder(),
                            helperText: 'Sets the anchor date for payment period calculations',
                            prefixIcon: Icon(Icons.event),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _paymentPeriodStartDate != null
                                ? _showEthiopianCalendar
                                    ? EthiopianCalendar.formatEthiopian(
                                        EthiopianCalendar.fromGregorian(_paymentPeriodStartDate!))
                                    : '${_paymentPeriodStartDate!.day.toString().padLeft(2, '0')}/${_paymentPeriodStartDate!.month.toString().padLeft(2, '0')}/${_paymentPeriodStartDate!.year}'
                                : 'Not set (will use dynamic periods)',
                            style: TextStyle(
                              color: _paymentPeriodStartDate != null ? Colors.black : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      if (_paymentPeriodStartDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _paymentPeriodStartDate = null;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text('Clear'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TaxRule>(
                        value: _taxRule,
                        decoration: const InputDecoration(
                          labelText: 'Tax Rule *',
                          border: OutlineInputBorder(),
                        ),
                        items: TaxRule.values.map((rule) {
                          return DropdownMenuItem(
                            value: rule,
                            child: Text(rule.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _taxRule = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Overtime Eligible'),
                        subtitle: const Text('Allow overtime payments'),
                        value: _overtimeEligible,
                        onChanged: (value) => setState(() => _overtimeEligible = value),
                      ),
                      if (_overtimeEligible) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _overtimeRatePerHourController,
                          decoration: const InputDecoration(
                            labelText: 'Overtime Rate Per Hour',
                            border: OutlineInputBorder(),
                            prefixText: 'ETB ',
                            helperText: 'Hourly rate for overtime work',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Pension Eligible'),
                        subtitle: const Text('Include pension contributions'),
                        value: _pensionEligible,
                        onChanged: (value) => setState(() => _pensionEligible = value),
                      ),
                      if (_pensionEligible) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _employeePensionRateController,
                                decoration: const InputDecoration(
                                  labelText: 'Employee Rate',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g., 0.07 for 7%',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _employerPensionRateController,
                                decoration: const InputDecoration(
                                  labelText: 'Employer Rate',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g., 0.11 for 11%',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // ── STEP 5: Org Structure ─────────────────────────
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Requires Supervisor'),
                        subtitle: const Text('Workers in this role must report to a supervisor'),
                        value: _requiresSupervisor,
                        onChanged: (value) => setState(() => _requiresSupervisor = value),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _maxSubordinatesController,
                        decoration: const InputDecoration(
                          labelText: 'Max Subordinates (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Maximum number of direct reports allowed',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) return null;
                          final num = int.tryParse(value!);
                          if (num == null || num < 1) {
                            return 'Must be a positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(_isActive ? 'Work type is active' : 'Work type is inactive'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveWorkType,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.workType == null ? 'Create' : 'Update'),
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
