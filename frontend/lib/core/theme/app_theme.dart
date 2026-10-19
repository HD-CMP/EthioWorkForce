import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// BRAND COLOR PALETTE
// ---------------------------------------------------------------------------
class AppColors {
  // Brand primary — EthioWorkforce Emerald
  static const Color primary = Color(0xFF007A3D);
  static const Color primaryDark = Color(0xFF005C2E);
  static const Color primaryLight = Color(0xFF33A86A);
  static const Color primarySurface = Color(0xFFE8F5EE); // 10% emerald tint

  // Brand secondary — Navy
  static const Color navy = Color(0xFF0A192F);
  static const Color navyLight = Color(0xFF1E3A5F);
  static const Color navySurface = Color(0xFFE8EDF4);

  // Accent — Gold
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFFD54F);
  static const Color goldSurface = Color(0xFFFFFDE7);

  // Semantic
  static const Color success = Color(0xFF007A3D);
  static const Color successSurface = Color(0xFFE8F5EE);
  static const Color warning = Color(0xFFE65100);
  static const Color warningSurface = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFB71C1C);
  static const Color errorSurface = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0D47A1);
  static const Color infoSurface = Color(0xFFE3F2FD);

  // Neutrals
  static const Color background = Color(0xFFF4F7F4);
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8EDE8);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textInverse = Colors.white;
  static const Color icon = Color(0xFF374151);
  static const Color iconMuted = Color(0xFF9CA3AF);

  // Module card gradients — all brand-consistent
  static const List<Color> workersGradient = [Color(0xFF005C2E), Color(0xFF007A3D)];
  static const List<Color> attendanceGradient = [Color(0xFF004D40), Color(0xFF00796B)];
  static const List<Color> payrollGradient = [Color(0xFF0A192F), Color(0xFF1E3A5F)];
  static const List<Color> sitesGradient = [Color(0xFF1B4332), Color(0xFF2D6A4F)];
  static const List<Color> workTypesGradient = [Color(0xFF003049), Color(0xFF005F73)];
  static const List<Color> reportsGradient = [Color(0xFF1A237E), Color(0xFF283593)];
  static const List<Color> adminsGradient = [Color(0xFF1B5E20), Color(0xFF2E7D32)];
  static const List<Color> settingsGradient = [Color(0xFF2D3436), Color(0xFF4A5568)];
}

// ---------------------------------------------------------------------------
// TEXT STYLES
// ---------------------------------------------------------------------------
class AppTextStyles {
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );

  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.2,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.2,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.2,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textMuted, letterSpacing: 0.3,
  );

  // Status
  static const TextStyle statusSuccess = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: AppColors.success, letterSpacing: 0.2,
  );
  static const TextStyle statusError = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: AppColors.error, letterSpacing: 0.2,
  );
  static const TextStyle statusWarning = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: AppColors.warning, letterSpacing: 0.2,
  );

  // Currency / amounts
  static const TextStyle currencyLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold,
    color: AppColors.success, letterSpacing: -0.3,
  );
  static const TextStyle currencyMedium = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.success,
  );
}

// ---------------------------------------------------------------------------
// DECORATIONS
// ---------------------------------------------------------------------------
class AppDecorations {
  // Cards
  static const BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.all(Radius.circular(14)),
    boxShadow: [
      BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
  static const BoxDecoration cardElevated = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
  );

  // Gradient banners
  static const BoxDecoration brandBanner = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF005C2E), Color(0xFF007A3D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
  static const BoxDecoration navyBanner = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF0A192F), Color(0xFF1E3A5F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Status badges
  static const BoxDecoration successBadge = BoxDecoration(
    color: AppColors.successSurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const BoxDecoration errorBadge = BoxDecoration(
    color: AppColors.errorSurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const BoxDecoration warningBadge = BoxDecoration(
    color: AppColors.warningSurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const BoxDecoration infoBadge = BoxDecoration(
    color: AppColors.infoSurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  static const BoxDecoration navyBadge = BoxDecoration(
    color: AppColors.navySurface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
}

// ---------------------------------------------------------------------------
// SPACING
// ---------------------------------------------------------------------------
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

// ---------------------------------------------------------------------------
// THEME DATA
// ---------------------------------------------------------------------------
class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.gold;
  static const Color errorColor = AppColors.error;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shadowColor: Color(0x0D000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        color: AppColors.cardBg,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF8FAF8),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIconColor: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentTextStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        elevation: 12,
        backgroundColor: Colors.white,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF9CA3AF);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return const Color(0xFFE5E7EB);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.goldLight,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
