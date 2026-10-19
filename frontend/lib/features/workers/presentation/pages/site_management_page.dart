import 'package:flutter/material.dart';

import '../../domain/entities/site.dart';
import '../../data/datasources/site_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';
import 'site_detail_page.dart';

class SiteManagementPage extends StatefulWidget {
  const SiteManagementPage({super.key});

  @override
  State<SiteManagementPage> createState() => _SiteManagementPageState();
}

class _SiteManagementPageState extends State<SiteManagementPage> with SingleTickerProviderStateMixin {
  final _datasource = SiteRemoteDataSource();
  List<Site> _sites = [];
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadSites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sites = await _datasource.getSites();
      if (mounted) {
        setState(() {
          _sites = sites;
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
            errorMsg = 'No sites found in the system. Create your first site to get started.';
          } else if (e.statusCode == 401 || e.statusCode == 403) {
            errorMsg = e.displayMessage;
          } else if (e.userMessage?.toLowerCase().contains('not authenticated') ?? false) {
            errorMsg = 'Please log in to view sites.';
          } else if ((e.userMessage?.toLowerCase().contains('network') ?? false) || 
                     (e.userMessage?.toLowerCase().contains('connection') ?? false)) {
            errorMsg = 'Unable to connect to server. Check your internet or backend URL in settings.';
          } else {
            errorMsg = '${e.displayMessage}\n\nTechnical: ${e.message}';
          }
        } else {
          errorMsg = 'Failed to load sites: $e';
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  Future<void> _showSiteDialog([Site? site]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SiteFormDialog(site: site),
    );

    if (result == true) {
      _loadSites();
    }
  }

  Future<void> _deleteSite(Site site) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${site.name}"?'),
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

    if (confirm == true && site.id != null) {
      try {
        await _datasource.deleteSite(site.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('"${site.name}" deleted successfully'),
              ]),
              backgroundColor: const Color(0xFF007A3D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          _loadSites();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(e is ApiException ? e.displayMessage : 'Failed to delete site')),
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
        title: const Text('Sites'),
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
              onPressed: () => _showSiteDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Site'),
            )
          : null,
    );
  }

  Widget _buildManageTab() {
    if (_sites.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: _sites.length,
      itemBuilder: (context, index) {
        final site = _sites[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SiteDetailPage(site: site),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: site.isActive 
                  ? const Color(0xFF007A3D) 
                  : const Color(0xFF9CA3AF),
              child: const Icon(Icons.location_city, color: Colors.white),
            ),
            title: Text(
              site.name,
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
                    'Code: ${site.code}',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  if (site.locationAddress != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: const Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            site.locationAddress!,
                            style: TextStyle(
                              color: const Color(0xFF374151),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: site.isActive 
                        ? const Color(0xFFE8F5EE) 
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: site.isActive 
                          ? const Color(0xFF66B28A) 
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  child: Text(
                    site.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: site.isActive 
                          ? const Color(0xFF003D1F) 
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showSiteDialog(site),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: const Color(0xFFB71C1C), size: 20),
                  onPressed: () => _deleteSite(site),
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
    if (_sites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_outlined, size: 80, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No Sites Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create sites in the Manage tab',
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
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _sites.length,
      itemBuilder: (context, index) {
        final site = _sites[index];
        return _buildSiteCard(site);
      },
    );
  }

  Widget _buildSiteCard(Site site) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SiteDetailPage(site: site),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: site.isActive
                  ? [const Color(0xFFE8F5EE), const Color(0xFFE8F5EE)]
                  : [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: site.isActive
                          ? const Color(0xFF007A3D)
                          : const Color(0xFF6B7280),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_city,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: site.isActive ? const Color(0xFF007A3D) : const Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      site.isActive ? 'Active' : 'Inactive',
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
                site.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                site.code,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (site.locationAddress != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        site.locationAddress!,
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
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
                color: const Color(0xFFE8F5EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_city_outlined,
                size: 80,
                color: const Color(0xFF66B28A),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Sites Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sites are physical locations where your workers\nare assigned to perform their duties.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showSiteDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Site'),
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
    final bool isNoDataError = _errorMessage!.toLowerCase().contains('no sites found');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isNoDataError ? const Color(0xFFE8F5EE) : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoDataError ? Icons.info_outline : Icons.error_outline,
                size: 80,
                color: isNoDataError ? const Color(0xFF66B28A) : const Color(0xFFE57373),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNoDataError ? 'No Sites Found' : 'Unable to Load Sites',
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
                onPressed: () => _showSiteDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Site'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadSites,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ExpansionTile(
                title: Text(
                  'Troubleshooting Tips',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTroubleshootingTip(
                          Icons.wifi_off,
                          'Check your internet connection',
                        ),
                        _buildTroubleshootingTip(
                          Icons.login,
                          'Ensure you are logged in',
                        ),
                        _buildTroubleshootingTip(
                          Icons.storage,
                          'Verify the backend server is running',
                        ),
                        _buildTroubleshootingTip(
                          Icons.security,
                          'Check if you have the required permissions',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SiteFormDialog extends StatefulWidget {
  final Site? site;

  const SiteFormDialog({super.key, this.site});

  @override
  State<SiteFormDialog> createState() => _SiteFormDialogState();
}

class _SiteFormDialogState extends State<SiteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _datasource = SiteRemoteDataSource();
  
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late bool _isActive;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site?.name ?? '');
    _codeController = TextEditingController(text: widget.site?.code ?? '');
    _descriptionController = TextEditingController(text: widget.site?.description ?? '');
    _locationController = TextEditingController(text: widget.site?.locationAddress ?? '');
    _latitudeController = TextEditingController(
      text: widget.site?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.site?.longitude?.toString() ?? '',
    );
    _isActive = widget.site?.isActive ?? true;
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

  Future<void> _saveSite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final site = Site(
        id: widget.site?.id,
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
        isActive: _isActive,
      );

      if (widget.site == null) {
        await _datasource.createSite(site);
      } else {
        await _datasource.updateSite(site);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.site == null 
                    ? 'Site created successfully' 
                    : 'Site updated successfully'),
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
              Expanded(child: Text(e is ApiException ? e.displayMessage : 'Failed to save site')),
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
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      widget.site == null ? 'Add New Site' : 'Edit Site',
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Site Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true 
                            ? 'Site name is required' 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Site Code *',
                          border: OutlineInputBorder(),
                        ),
                        enabled: widget.site == null,
                        validator: (value) => value?.trim().isEmpty ?? true 
                            ? 'Site code is required' 
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
                      SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(_isActive ? 'Site is active' : 'Site is inactive'),
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
                    onPressed: _isLoading ? null : _saveSite,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.site == null ? 'Create' : 'Update'),
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
