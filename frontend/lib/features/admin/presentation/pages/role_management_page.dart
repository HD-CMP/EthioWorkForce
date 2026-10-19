import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/roles_remote_datasource.dart';
import '../../data/models/role_model.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  List<RoleModel> _roles = [];
  bool _isLoading = false;
  late RolesRemoteDatasource _datasource;

  @override
  void initState() {
    super.initState();
    _datasource = RolesRemoteDatasource(getIt<Dio>());
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roles = await _datasource.getRoles();
      setState(() {
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Unable to load roles. Please try again.')),
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

  Future<void> _deleteRole(RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: Color(0xFFB71C1C),
            size: 32,
          ),
        ),
        title: const Text(
          'Delete Role',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to permanently delete "${role.displayName}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. Users with this role will lose their permissions.',
                      style: TextStyle(fontSize: 13),
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.delete),
            label: const Text('Delete Role'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _datasource.deleteRole(role.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('"${role.displayName}" deleted successfully'),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        _loadRoles();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Failed to delete role: $e')),
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

  void _showRoleDialog({RoleModel? role}) {
    final nameController = TextEditingController(text: role?.name);
    final displayNameController =
        TextEditingController(text: role?.displayName);
    final descriptionController =
        TextEditingController(text: role?.description);
    bool isActive = role?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role == null ? 'Create New Role' : 'Edit Role',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role == null
                                ? 'Define a custom role with specific permissions'
                                : 'Update role information and settings',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (role == null) ...[
                          const Text(
                            'Role Identifier',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Role Name (Internal)',
                              hintText: 'e.g., project_manager, team_lead',
                              helperText: 'Lowercase, no spaces, use underscores',
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: (value) {
                              final sanitized = value
                                  .toLowerCase()
                                  .replaceAll(' ', '_')
                                  .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                              if (sanitized != value) {
                                nameController.value = TextEditingValue(
                                  text: sanitized,
                                  selection: TextSelection.collapsed(
                                    offset: sanitized.length,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Text(
                          'Display Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            hintText: 'e.g., Project Manager, Team Lead',
                            helperText: 'User-friendly name shown in UI',
                            prefixIcon: Icon(Icons.label),
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText:
                                'Describe the role\'s responsibilities and permissions',
                            helperText: 'Help users understand this role',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SwitchListTile(
                            title: const Text('Active'),
                            subtitle: Text(
                              isActive
                                  ? 'Role can be assigned to users'
                                  : 'Role is disabled and cannot be assigned',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: isActive,
                            onChanged: (value) {
                              setDialogState(() {
                                isActive = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                if (displayNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('Please enter a display name'),
                      ]),
                      backgroundColor: const Color(0xFFE65100),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  return;
                }

                if (role == null && nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('Please enter a role identifier'),
                      ]),
                      backgroundColor: const Color(0xFFE65100),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  return;
                }

                try {
                  if (role == null) {
                    await _datasource.createRole(
                      RoleCreateUpdate(
                        name: nameController.text,
                        displayName: displayNameController.text,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        isActive: isActive,
                      ),
                    );
                  } else {
                    await _datasource.updateRole(
                      role.id,
                      {
                        'display_name': displayNameController.text,
                        'description': descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        'is_active': isActive,
                      },
                    );
                  }

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(role == null ? 'Role created successfully' : 'Role updated successfully'),
                      ]),
                      backgroundColor: const Color(0xFF007A3D),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  _loadRoles();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Failed to save role: $e')),
                      ]),
                      backgroundColor: const Color(0xFFB71C1C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
                      icon: Icon(role == null ? Icons.add : Icons.save),
                      label: Text(role == null ? 'Create Role' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Roles Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create custom roles to manage user permissions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showRoleDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Role'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRoles,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.admin_panel_settings,
                                label: 'Total Roles',
                                value: '${_roles.length}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.security,
                                label: 'System Roles',
                                value:
                                    '${_roles.where((r) => r.isSystemRole).length}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.check_circle,
                                label: 'Active',
                                value: '${_roles.where((r) => r.isActive).length}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _roles.length,
                          itemBuilder: (context, index) {
                  final role = _roles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: role.isActive
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            role.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (role.isSystemRole)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SYSTEM',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (!role.isActive)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (role.description != null)
                            Text(role.description!),
                          Text(
                            'ID: ${role.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: role.isSystemRole
                          ? Chip(
                              label: const Text(
                                'Protected',
                                style: TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.blue[50],
                              side: BorderSide.none,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Theme.of(context).primaryColor,
                                  tooltip: 'Edit role',
                                  onPressed: () => _showRoleDialog(role: role),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  tooltip: 'Delete role',
                                  onPressed: () => _deleteRole(role),
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
                ),
      floatingActionButton: _roles.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _showRoleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Role'),
      ),
    );
  }
}
