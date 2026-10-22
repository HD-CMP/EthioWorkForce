import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/session_manager.dart';
import 'core/services/font_settings_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await configureDependencies();
  await FontSettingsService.initialize();
  
  runApp(const EthioWorkforceApp());
}

class EthioWorkforceApp extends StatefulWidget {
  const EthioWorkforceApp({super.key});

  @override
  State<EthioWorkforceApp> createState() => _EthioWorkforceAppState();
}

class _EthioWorkforceAppState extends State<EthioWorkforceApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionManager.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionManager.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      SessionManager.recordActivity(syncNow: true);
    } else if (state == AppLifecycleState.resumed) {
      SessionManager.checkAndHandleResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
      ],
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => SessionManager.recordActivity(),
        onPointerMove: (_) => SessionManager.recordActivity(),
        child: ValueListenableBuilder<double>(
          valueListenable: FontSettingsService.fontScaleNotifier,
          builder: (context, fontScale, _) {
            return MaterialApp(
              navigatorKey: AppRouter.navigatorKey,
              title: 'EthioWorkforce',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(fontScale),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('am', 'ET'),
              ],
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: AppRouter.splash,
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
