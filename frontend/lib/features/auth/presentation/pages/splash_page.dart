import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _ctrl.forward();
    context.read<AuthBloc>().add(CheckAuthStatus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(top: -80, right: -60,
                child: Container(width: 280, height: 280,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0FFFFFFF)))),
              Positioned(bottom: -80, left: -60,
                child: Container(width: 240, height: 240,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0DFFFFFF)))),
              Positioned(top: 120, left: -40,
                child: Container(width: 120, height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0AFFFFFF)))),
              // Center content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: const Color(0x4D000000), blurRadius: 32, offset: const Offset(0, 12))],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0x4DFFFFFF), width: 2.5),
                              ),
                              child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 52),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'EthioWorkforce',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Workforce Management Platform',
                          style: TextStyle(color: const Color(0xBFFFFFFF), fontSize: 14, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 64),
                        SizedBox(
                          width: 28, height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xD9FFFFFF)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading…',
                          style: TextStyle(color: const Color(0x99FFFFFF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom version text
              Positioned(
                bottom: 32, left: 0, right: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    '© 2026 EthioWorkforce',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color(0x66FFFFFF), fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
