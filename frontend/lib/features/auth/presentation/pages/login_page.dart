import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/services/session_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final expired = await SessionManager.consumeExpirationNotice();
      if (expired && mounted) {
        AppSnackBar.showWarning(
          context,
          'Session expired due to inactivity to protect funds. Please sign in.',
        );
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }


  Future<void> _showServerConfigDialog() async {
    final currentUrl = await DioClient.getBackendUrl();
    final urlController = TextEditingController(text: currentUrl);
    String? pingResult;
    bool isPinging = false;
    bool? isSuccess;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x1A007A3D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dns_rounded, color: Color(0xFF007A3D)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Backend Server',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select or enter the API server URL:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://ethioworkforce-api.onrender.com/api/v1',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('☁️ Cloud Production', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        urlController.text = 'https://ethioworkforce-api.onrender.com/api/v1';
                        setDialogState(() {
                          pingResult = null;
                          isSuccess = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('🏠 Local PC (192.168.8.250)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        urlController.text = 'http://192.168.8.250:8000/api/v1';
                        setDialogState(() {
                          pingResult = null;
                          isSuccess = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('📱 Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        urlController.text = 'http://10.0.2.2:8000/api/v1';
                        setDialogState(() {
                          pingResult = null;
                          isSuccess = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: isPinging
                          ? null
                          : () async {
                              setDialogState(() {
                                isPinging = true;
                                pingResult = 'Testing connection...';
                                isSuccess = null;
                              });
                              try {
                                final baseUrl = urlController.text.trim().replaceAll(RegExp(r'/api/v1/?$'), '');
                                final dio = Dio(BaseOptions(
                                  connectTimeout: const Duration(seconds: 6),
                                  receiveTimeout: const Duration(seconds: 6),
                                ));
                                final sw = Stopwatch()..start();
                                final res = await dio.get('$baseUrl/health');
                                sw.stop();
                                setDialogState(() {
                                  isPinging = false;
                                  isSuccess = res.statusCode == 200;
                                  pingResult = 'Connected! (${sw.elapsedMilliseconds}ms)';
                                });
                              } catch (e) {
                                setDialogState(() {
                                  isPinging = false;
                                  isSuccess = false;
                                  pingResult = 'Cannot reach server: ${e is DioException ? (e.message ?? e.type.name) : e.toString()}';
                                });
                              }
                            },
                      icon: isPinging
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check_rounded, size: 16),
                      label: const Text('Test Connection'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (pingResult != null)
                      Expanded(
                        child: Text(
                          pingResult!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSuccess == true
                                ? const Color(0xFF007A3D)
                                : isSuccess == false
                                    ? const Color(0xFFB71C1C)
                                    : const Color(0xFF6B7280),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final trimmed = urlController.text.trim();
                        if (trimmed.isNotEmpty) {
                          await DioClient.setBackendUrl(trimmed);
                          if (mounted) {
                            Navigator.pop(ctx);
                            AppSnackBar.showSuccess(context, 'Server configured to: $trimmed');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007A3D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save & Apply'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacementNamed(AppRouter.home);
          } else if (state is AuthError) {
            AppSnackBar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF005C2E), Color(0xFF007A3D), Color(0xFF005C2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Decorative circles
              Positioned(top: -80, right: -60,
                child: Container(width: 260, height: 260,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0FFFFFFF)))),
              Positioned(top: 80, right: 30,
                child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0DFFFFFF)))),
              Positioned(bottom: -60, left: -40,
                child: Container(width: 200, height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0DFFFFFF)))),
              // Top server settings button
              Positioned(
                top: 10,
                right: 14,
                child: SafeArea(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x4DFFFFFF)),
                      ),
                      child: const Icon(Icons.dns_rounded, color: Colors.white, size: 18),
                    ),
                    tooltip: 'Server Connection Settings',
                    onPressed: _showServerConfigDialog,
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top branding area
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 90, height: 90,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [BoxShadow(color: const Color(0x40000000), blurRadius: 24, offset: const Offset(0, 8))],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0x26FFFFFF),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0x4DFFFFFF), width: 2),
                                          ),
                                          child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 42),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'EthioWorkforce',
                                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Workforce Management Platform',
                                      style: TextStyle(color: const Color(0xBFFFFFFF), fontSize: 13, letterSpacing: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Login card
                          Expanded(
                            flex: 3,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(32),
                                      topRight: Radius.circular(32),
                                    ),
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4))],
                                  ),
                                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), letterSpacing: -0.4)),
                                        const SizedBox(height: 6),
                                        Text('Sign in to your account', style: TextStyle(fontSize: 14, color: const Color(0xFF9CA3AF))),
                                        const SizedBox(height: 32),

                                        // Username field
                                        _buildLabel('Username'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _usernameController,
                                          enabled: !isLoading,
                                          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                                          decoration: _inputDecoration(
                                            hint: 'Enter your username',
                                            icon: Icons.person_outline_rounded,
                                          ),
                                          textInputAction: TextInputAction.next,
                                          validator: (v) => (v == null || v.isEmpty) ? 'Username is required' : null,
                                        ),
                                        const SizedBox(height: 20),

                                        // Password field
                                        _buildLabel('Password'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _passwordController,
                                          enabled: !isLoading,
                                          obscureText: _obscurePassword,
                                          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                                          decoration: _inputDecoration(
                                            hint: 'Enter your password',
                                            icon: Icons.lock_outline_rounded,
                                            suffix: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                color: const Color(0xFF9CA3AF),
                                                size: 20,
                                              ),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                          ),
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => isLoading ? null : _handleLogin(),
                                          validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                                        ),
                                        const SizedBox(height: 32),

                                        // Sign in button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton(
                                            onPressed: isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF007A3D),
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor: Color(0x99007A3D),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 22, height: 22,
                                                    child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                                                      SizedBox(width: 8),
                                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Footer
                                        Center(
                                          child: Text(
                                            '© 2026 EthioWorkforce. All rights reserved.',
                                            style: TextStyle(fontSize: 11, color: const Color(0xFF9CA3AF)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333), letterSpacing: 0.2),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF007A3D), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF007A3D), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
      ),
    );
  }
}
