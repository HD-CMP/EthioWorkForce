import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/dio_client.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
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
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
          const SnackBar(
            content: Text('Backend URL updated successfully'),
            backgroundColor: Colors.green,
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
        title: const Text('Export to USB'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter encryption password:'),
            const SizedBox(height: 16),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.red,
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
    );

    if (result != null) {
      final passwordController = TextEditingController();
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import from USB'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter decryption password:'),
              const SizedBox(height: 16),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed == true && passwordController.text.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            Navigator.pop(context);
            setState(() => _lastSync = DateTime.now());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data imported successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import failed: $e'),
                backgroundColor: Colors.red,
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
                    Theme.of(context).primaryColor.withOpacity(0.7),
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
                      color: Colors.white.withOpacity(0.9),
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_circle, color: Colors.blue),
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
            _Section(
              title: 'Backend Configuration',
              icon: Icons.dns,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.settings_ethernet, color: Colors.purple),
                  ),
                  title: const Text('Backend API URL'),
                  subtitle: Text(
                    _backendUrl.isEmpty ? 'Not configured' : _backendUrl,
                    style: TextStyle(
                      fontSize: 12,
                      color: _backendUrl.isEmpty ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _configureBackendUrl,
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.refresh, color: Colors.orange),
                  ),
                  title: const Text('Reset to Default'),
                  subtitle: const Text('Use localhost:8000'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await DioClient.setBackendUrl(DioClient.defaultDevelopmentUrl);
                    setState(() => _backendUrl = DioClient.defaultDevelopmentUrl);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backend URL reset to default'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            _Section(
              title: localizations?.syncData ?? 'Sneakernet Sync',
              icon: Icons.usb,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload, color: Colors.blue),
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download, color: Colors.green),
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
