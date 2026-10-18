import 'package:flutter/material.dart';

import '../../domain/entities/work_place.dart';
import '../../domain/entities/worker.dart';
import '../../data/datasources/work_place_remote_datasource.dart';
import '../../data/datasources/worker_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';

class WorkPlaceFormDialog extends StatefulWidget {
  final int siteId;
  final WorkPlace? workPlace;

  const WorkPlaceFormDialog({
    super.key,
    required this.siteId,
    this.workPlace,
  });

  @override
  State<WorkPlaceFormDialog> createState() => _WorkPlaceFormDialogState();
}

class _WorkPlaceFormDialogState extends State<WorkPlaceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _datasource = WorkPlaceRemoteDataSource();
  final _workerDataSource = WorkerRemoteDataSource();
  
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late bool _isActive;
  
  int? _selectedSupervisorId;
  List<Worker> _supervisors = [];
  bool _isLoading = false;
  bool _loadingSupervisors = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workPlace?.name ?? '');
    _codeController = TextEditingController(text: widget.workPlace?.code ?? '');
    _descriptionController = TextEditingController(text: widget.workPlace?.description ?? '');
    _locationController = TextEditingController(text: widget.workPlace?.locationAddress ?? '');
    _latitudeController = TextEditingController(
      text: widget.workPlace?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.workPlace?.longitude?.toString() ?? '',
    );
    _isActive = widget.workPlace?.isActive ?? true;
    _selectedSupervisorId = widget.workPlace?.supervisorId;
    
    _loadSupervisors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  int _getRoleHierarchyLevel(String? workType) {
    if (workType == null) return 999;
    final role = workType.toLowerCase();
    
    if (role.contains('site manager') || role.contains('project manager')) return 1;
    if (role.contains('supervisor') || role.contains('foreman')) return 2;
    if (role.contains('engineer')) return 3;
    if (role.contains('technician') || role.contains('skilled')) return 4;
    if (role.contains('operator')) return 5;
    if (role.contains('worker') || role.contains('laborer') || role.contains('daily')) return 6;
    
    return 7;
  }

  Future<void> _loadSupervisors() async {
    setState(() => _loadingSupervisors = true);
    try {
      final workers = await _workerDataSource.getWorkers(
        siteId: widget.siteId,
        status: 'active',
      );
      if (mounted) {
        workers.sort((a, b) {
          final hierarchyCompare = _getRoleHierarchyLevel(a.workType)
              .compareTo(_getRoleHierarchyLevel(b.workType));
          if (hierarchyCompare != 0) return hierarchyCompare;
          return a.fullName.compareTo(b.fullName);
        });
        setState(() {
          _supervisors = workers;
          _loadingSupervisors = false;
          
          if (_selectedSupervisorId != null) {
            final supervisorExists = _supervisors.any((s) => s.id == _selectedSupervisorId);
            if (!supervisorExists) {
              _selectedSupervisorId = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSupervisors = false);
      }
    }
  }

  Future<void> _saveWorkPlace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final workPlace = WorkPlace(
        id: widget.workPlace?.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        locationAddress: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        latitude: _latitudeController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_latitudeController.text.trim()),
        longitude: _longitudeController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_longitudeController.text.trim()),
        parentSiteId: widget.siteId,
        supervisorId: _selectedSupervisorId,
        isActive: _isActive,
      );

      if (widget.workPlace == null) {
        await _datasource.createWorkPlace(workPlace);
      } else {
        await _datasource.updateWorkPlace(workPlace);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.workPlace == null 
                ? 'Work place created successfully' 
                : 'Work place updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.displayMessage : 'Failed to save work place'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.workPlace == null ? 'Add New Work Place' : 'Edit Work Place',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Work Place Name *',
                          border: OutlineInputBorder(),
                          helperText: 'e.g., Daandii, Site 01, Building A',
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true 
                            ? 'Work place name is required' 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Work Place Code *',
                          border: OutlineInputBorder(),
                          helperText: 'Unique identifier for this work place',
                        ),
                        enabled: widget.workPlace == null,
                        validator: (value) => value?.trim().isEmpty ?? true 
                            ? 'Work place code is required' 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        value: _loadingSupervisors 
                            ? null 
                            : (_supervisors.any((s) => s.id == _selectedSupervisorId) 
                                ? _selectedSupervisorId 
                                : null),
                        decoration: const InputDecoration(
                          labelText: 'Supervisor (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.supervisor_account),
                          helperText: 'Assign a supervisor for this work place',
                        ),
                        menuMaxHeight: 400,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No Supervisor'),
                          ),
                          if (_loadingSupervisors)
                            ...[]
                          else
                            ..._supervisors
                                .where((s) => s.id != null)
                                .map((supervisor) {
                              final workType = supervisor.workType ?? 'Unknown';
                              return DropdownMenuItem<int?>(
                                value: supervisor.id!,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${supervisor.fullName} (${supervisor.employeeId})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' • $workType',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        ],
                        onChanged: _loadingSupervisors 
                            ? null 
                            : (value) {
                                setState(() => _selectedSupervisorId = value);
                              },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(_isActive 
                            ? 'Work place is active' 
                            : 'Work place is inactive'),
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
                    onPressed: _isLoading ? null : _saveWorkPlace,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.workPlace == null ? 'Create' : 'Update'),
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
