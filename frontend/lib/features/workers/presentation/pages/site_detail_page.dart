import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/site.dart';
import '../../domain/entities/work_place.dart';
import '../../data/datasources/work_place_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';
import 'work_place_form_dialog.dart';

class SiteDetailPage extends StatefulWidget {
  final Site site;

  const SiteDetailPage({super.key, required this.site});

  @override
  State<SiteDetailPage> createState() => _SiteDetailPageState();
}

class _SiteDetailPageState extends State<SiteDetailPage> {
  final _datasource = WorkPlaceRemoteDataSource();
  List<WorkPlace> _workPlaces = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkPlaces();
  }

  Future<void> _loadWorkPlaces() async {
    setState(() => _isLoading = true);
    try {
      final workPlaces = await _datasource.getWorkPlaces(siteId: widget.site.id);
      if (mounted) {
        setState(() {
          _workPlaces = workPlaces;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showWorkPlaceDialog([WorkPlace? workPlace]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WorkPlaceFormDialog(
        siteId: widget.site.id!,
        workPlace: workPlace,
      ),
    );

    if (result == true) {
      _loadWorkPlaces();
    }
  }

  Future<void> _deleteWorkPlace(WorkPlace workPlace) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Work Place'),
        content: Text('Are you sure you want to delete "${workPlace.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && workPlace.id != null) {
      try {
        await _datasource.deleteWorkPlace(workPlace.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('"${workPlace.name}" deleted successfully'),
              ]),
              backgroundColor: const Color(0xFF007A3D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          _loadWorkPlaces();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(e is ApiException ? e.displayMessage : 'Failed to delete work place')),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Site Details'),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.site.isActive ? const Color(0xFF007A3D) : const Color(0xFF9CA3AF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.site.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.site.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildBasicInformation(context),
            const SizedBox(height: 12),
            _buildLocationInformation(context),
            const SizedBox(height: 12),
            _buildWorkPlacesSection(context),
            if (widget.site.createdAt != null || widget.site.updatedAt != null) ...[
              const SizedBox(height: 12),
              _buildTimestamps(context),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWorkPlaceDialog(),
        icon: const Icon(Icons.add_location),
        label: const Text('Add Work Place'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.site.isActive
              ? [const Color(0xFF007A3D), const Color(0xFF005C2E)]
              : [const Color(0xFF6B7280), const Color(0xFF1F2937)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            widget.site.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Code: ${widget.site.code}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Basic Information',
      icon: Icons.info_outline,
      iconColor: const Color(0xFF1E3A5F),
      children: [
        if (widget.site.description != null && widget.site.description!.isNotEmpty)
          _buildFullWidthInfoTile(
            icon: Icons.description,
            label: 'Description',
            value: widget.site.description!,
            iconColor: const Color(0xFF0A192F),
          ),
        _buildInfoTile(
          icon: Icons.code,
          label: 'Site Code',
          value: widget.site.code,
          iconColor: const Color(0xFF0A192F),
        ),
        _buildInfoTile(
          icon: Icons.toggle_on,
          label: 'Status',
          value: widget.site.isActive ? 'Active' : 'Inactive',
          iconColor: widget.site.isActive ? const Color(0xFF005C2E) : const Color(0xFF374151),
        ),
      ],
    );
  }

  Widget _buildLocationInformation(BuildContext context) {
    return _buildSection(
      context,
      title: 'Location Information',
      icon: Icons.place,
      iconColor: const Color(0xFFB71C1C),
      children: [
        if (widget.site.locationAddress != null)
          _buildInfoTile(
            icon: Icons.location_on,
            label: 'Address',
            value: widget.site.locationAddress!,
            iconColor: const Color(0xFFB71C1C),
          ),
        if (widget.site.latitude != null)
          _buildInfoTile(
            icon: Icons.map,
            label: 'Coordinates',
            value: '${widget.site.latitude!.toStringAsFixed(6)}, ${widget.site.longitude!.toStringAsFixed(6)}',
            iconColor: const Color(0xFFE65100),
          ),
      ],
    );
  }

  Widget _buildWorkPlacesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1A0A192F),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: const Color(0xFF0A192F), size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Work Places',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A192F),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A192F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_workPlaces.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_workPlaces.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.business_outlined, size: 64, color: const Color(0xFFD1D5DB)),
                    const SizedBox(height: 16),
                    Text(
                      'No Work Places',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add work places to organize this site',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _workPlaces.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final workPlace = _workPlaces[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: workPlace.isActive ? const Color(0xFFE8EDF4) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: workPlace.isActive ? const Color(0xFF9AAFCA) : const Color(0xFFD1D5DB),
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
                              color: workPlace.isActive ? const Color(0xFF0A192F) : const Color(0xFF9CA3AF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.business, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workPlace.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Code: ${workPlace.code}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                if (workPlace.supervisorName != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.supervisor_account, size: 14, color: const Color(0xFF0A192F)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Manager: ${workPlace.supervisorName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(0xFF0A192F),
                                            fontWeight: FontWeight.w600,
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
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showWorkPlaceDialog(workPlace),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: const Color(0xFFB71C1C), size: 20),
                            onPressed: () => _deleteWorkPlace(workPlace),
                          ),
                        ],
                      ),
                      if (workPlace.locationAddress != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: const Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                workPlace.locationAddress!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimestamps(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    
    return _buildSection(
      context,
      title: 'Record Information',
      icon: Icons.history,
      iconColor: const Color(0xFF9CA3AF),
      children: [
        if (widget.site.createdAt != null)
          _buildInfoTile(
            icon: Icons.add_circle_outline,
            label: 'Created At',
            value: dateFormat.format(widget.site.createdAt!),
            iconColor: const Color(0xFF005C2E),
          ),
        if (widget.site.updatedAt != null)
          _buildInfoTile(
            icon: Icons.update,
            label: 'Last Updated',
            value: dateFormat.format(widget.site.updatedAt!),
            iconColor: const Color(0xFFE65100),
          ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromARGB(26, iconColor.red, iconColor.green, iconColor.blue),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color.fromARGB(26, iconColor.red, iconColor.green, iconColor.blue),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(26, iconColor.red, iconColor.green, iconColor.blue),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: const Color(0xFF1A1A1A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
