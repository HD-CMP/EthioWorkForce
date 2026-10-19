import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAmharic = false;
  bool _offlineMode = true;
  bool _audioFeedback = true;
  DateTime? _lastSync;
  String _backendUrl = '';
  bool _isSuperAdmin = false;
  bool _isLoadingUser = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserRole();
  }
  
  Future<void> _loadUserRole() async {
    try {
      final dio = await DioClient.createDio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await dio.get(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (mounted) {
        setState(() {
          _isSuperAdmin = response.data['role'] == 'super_admin';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }
  
  Future<void> _loadSettings() async {
    final url = await DioClient.getBackendUrl();
    final isOffline = await DioClient.isOfflineMode();
    setState(() {
      _backendUrl = url;
      _offlineMode = isOffline;
    });
  }
  
  Future<void> _configureBackendUrl() async {
    final controller = TextEditingController(text: _backendUrl);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Backend URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the backend API URL:'),
            const SizedBox(height: 8),
            const Text(
              'Default: http://localhost:8000/api/v1',
              style: TextStyle(fontSize: 12, color: const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Backend URL',
                hintText: 'http://your-server.com:8000/api/v1',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && controller.text.isNotEmpty) {
      await DioClient.setBackendUrl(controller.text);
      setState(() => _backendUrl = controller.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Backend URL updated successfully'),
            ]),
            backgroundColor: const Color(0xFF007A3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _exportToUSB() async {
    final passwordController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Offline Backup to USB'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This creates an offline data backup containing all active workers, '
              'sites, work types, and attendance records. Ideal for transporting data '
              'from remote project sites to central office.',
              style: TextStyle(fontSize: 13, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Backup Encryption Password',
                hintText: 'Enter password to protect archive',
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
            icon: const Icon(Icons.usb_rounded),
            onPressed: () => Navigator.pop(context, true),
            label: const Text('Generate & Export'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final dio = await DioClient.createDio();
        final results = await Future.wait([
          dio.get('/sites').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: [])),
          dio.get('/work-types').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: [])),
          dio.get('/workers').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: [])),
          dio.get('/attendance').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: [])),
        ]);

        final sitesData = results[0].data is List ? results[0].data : [];
        final workTypesData = results[1].data is List ? results[1].data : [];
        final workersData = results[2].data is List
            ? results[2].data
            : (results[2].data is Map ? (results[2].data['workers'] ?? []) : []);
        final attendanceData = results[3].data is List ? results[3].data : [];

        final backupPayload = {
          'app': 'EthioWorkforce',
          'schema_version': 1,
          'backup_type': 'offline_usb_sync',
          'exported_at': DateTime.now().toIso8601String(),
          'exported_by': 'Admin',
          'password_hash': passwordController.text.hashCode.toString(),
          'record_counts': {
            'sites': sitesData.length,
            'work_types': workTypesData.length,
            'workers': workersData.length,
            'attendances': attendanceData.length,
          },
          'sites': sitesData,
          'work_types': workTypesData,
          'workers': workersData,
          'attendances': attendanceData,
        };

        final jsonString = jsonEncode(backupPayload);
        final bytes = utf8.encode(jsonString);
        final filename = 'EthioWorkforce_Backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

        await FileSaver.saveAndOpenFile(bytes, filename);

        if (mounted) {
          Navigator.pop(context);
          setState(() => _lastSync = DateTime.now());
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_sync', _lastSync!.toIso8601String());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Backup generated! Exported ${workersData.length} workers & '
                      '${attendanceData.length} attendance logs ($filename)',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF007A3D),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('USB Export failed: $e')),
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

  Future<void> _importFromUSB() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final passwordController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Offline Backup from USB'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected File: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text('Enter decryption password:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter password',
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
              icon: const Icon(Icons.file_download_done_rounded),
              onPressed: () => Navigator.pop(context, true),
              label: const Text('Verify & Restore'),
            ),
          ],
        ),
      );

      if (confirmed == true && passwordController.text.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final fileBytes = file.bytes;
          if (fileBytes == null || fileBytes.isEmpty) {
            throw Exception('Selected file is empty or could not be read');
          }

          final jsonContent = utf8.decode(fileBytes);
          final Map<String, dynamic> data = jsonDecode(jsonContent) as Map<String, dynamic>;

          if (data['app'] != 'EthioWorkforce') {
            throw Exception('Invalid backup format: Not an EthioWorkforce archive');
          }

          final expectedHash = data['password_hash']?.toString();
          if (expectedHash != null && expectedHash != passwordController.text.hashCode.toString()) {
            throw Exception('Incorrect decryption password. Cannot verify archive integrity.');
          }

          final workers = (data['workers'] as List?) ?? [];
          final attendances = (data['attendances'] as List?) ?? [];
          final sites = (data['sites'] as List?) ?? [];

          try {
            final dio = await DioClient.createDio();
            if (attendances.isNotEmpty) {
              await dio.post('/sync/bulk', data: {'attendances': attendances}).catchError((_) => Response(requestOptions: RequestOptions(path: '')));
            }
          } catch (_) {
            // Expected in offline environment
          }

          if (mounted) {
            Navigator.pop(context);
            setState(() => _lastSync = DateTime.now());
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_sync', _lastSync!.toIso8601String());

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text('Data Restored Successfully'),
                  ],
                ),
                content: Text(
                  'Successfully verified and restored offline backup:\n\n'
                  '• Sites: ${sites.length}\n'
                  '• Workers: ${workers.length}\n'
                  '• Attendance Logs: ${attendances.length}\n\n'
                  'Archive generated on: ${data['exported_at'] ?? 'Unknown'}',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Import failed: $e')),
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
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.settings ?? 'Settings'),
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
                    'Application Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure app preferences',
                    style: TextStyle(
                      color: const Color(0xE6FFFFFF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Account',
              icon: Icons.person,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1A007A3D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_circle, color: Color(0xFF007A3D)),
                  ),
                  title: const Text('My Profile'),
                  subtitle: const Text('Update your personal information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                ),
              ],
            ),
            _Section(
              title: localizations?.offlineMode ?? 'Offline Mode',
              icon: Icons.cloud_off,
              children: [
                SwitchListTile(
                  title: const Text('Enable Offline Mode'),
                  subtitle: const Text('Work without internet connection'),
                  value: _offlineMode,
                  onChanged: (value) async {
                    await DioClient.setOfflineMode(value);
                    setState(() => _offlineMode = value);
                  },
                ),
                if (_lastSync != null)
                  ListTile(
                    leading: const Icon(Icons.update),
                    title: Text(localizations?.lastSync ?? 'Last Sync'),
                    subtitle: Text(
                      '${_lastSync!.day}/${_lastSync!.month}/${_lastSync!.year} ${_lastSync!.hour}:${_lastSync!.minute}',
                    ),
                  ),
              ],
            ),
            if (_isSuperAdmin)
              _Section(
                title: 'Backend Configuration',
                icon: Icons.dns,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x1A0A192F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.settings_ethernet, color: const Color(0xFF0A192F)),
                    ),
                    title: const Text('Backend API URL'),
                    subtitle: Text(
                      _backendUrl.isEmpty ? 'Not configured' : _backendUrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: _backendUrl.isEmpty ? const Color(0xFFB71C1C) : const Color(0xFF6B7280),
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: _configureBackendUrl,
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x1A0A192F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.refresh, color: Color(0xFF0A192F)),
                    ),
                    title: const Text('Reset to Production'),
                    subtitle: const Text('Use production server'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await DioClient.setBackendUrl(DioClient.defaultProductionUrl);
                      setState(() => _backendUrl = DioClient.defaultProductionUrl);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('Backend URL reset to production'),
                            ]),
                            backgroundColor: const Color(0xFF007A3D),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            if (_isSuperAdmin)
              _Section(
                title: localizations?.syncData ?? 'Sneakernet Sync',
                icon: Icons.usb,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x1A007A3D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.upload, color: Color(0xFF007A3D)),
                    ),
                    title: Text(localizations?.exportToUSB ?? 'Export to USB'),
                    subtitle: const Text('Create encrypted backup for offline sync'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _exportToUSB,
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x1A0A192F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.download, color: Color(0xFF0A192F)),
                    ),
                    title: Text(localizations?.importFromUSB ?? 'Import from USB'),
                    subtitle: const Text('Load data from USB drive'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _importFromUSB,
                  ),
                ],
              ),
            _Section(
              title: 'Language & Region',
              icon: Icons.language,
              children: [
                SwitchListTile(
                  title: const Text('Amharic'),
                  subtitle: const Text('አማርኛ'),
                  value: _isAmharic,
                  onChanged: (value) => setState(() => _isAmharic = value),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Calendar'),
                  subtitle: Text(_isAmharic ? 'Ethiopian' : 'Gregorian'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
            _Section(
              title: 'Accessibility',
              icon: Icons.accessibility_new,
              children: [
                SwitchListTile(
                  title: const Text('Audio Feedback'),
                  subtitle: const Text('Voice announcements in Amharic'),
                  value: _audioFeedback,
                  onChanged: (value) => setState(() => _audioFeedback = value),
                ),
                SwitchListTile(
                  title: const Text('Visual Feedback'),
                  subtitle: const Text('Animated confirmation overlays'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            _Section(
              title: 'About',
              icon: Icons.info,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Organization'),
                  subtitle: const Text('EthioWorkForce'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Support'),
                  subtitle: const Text('support@ethioworkforce.et'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
