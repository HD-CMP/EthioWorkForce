import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enterprise typography & font size management service.
/// Provides reactive font scaling across the entire application.
class FontSettingsService {
  static const String _keyFontScale = 'app_font_scale';
  static const String _keyFontFamily = 'app_font_family';

  // Standard preset scale factors
  static const double scaleCompact = 0.85;
  static const double scaleStandard = 1.00;
  static const double scaleComfortable = 1.15;
  static const double scaleLarge = 1.30;

  static const double minScale = 0.80;
  static const double maxScale = 1.35;

  /// Global reactive notifier for the text scale factor.
  static final ValueNotifier<double> fontScaleNotifier =
      ValueNotifier<double>(scaleStandard);

  /// Global reactive notifier for font family preference.
  static final ValueNotifier<String> fontFamilyNotifier =
      ValueNotifier<String>('System');

  /// Initialize and load saved font preferences on app startup.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedScale = prefs.getDouble(_keyFontScale);
      if (savedScale != null) {
        fontScaleNotifier.value = savedScale.clamp(minScale, maxScale);
      }

      final savedFamily = prefs.getString(_keyFontFamily);
      if (savedFamily != null && savedFamily.isNotEmpty) {
        fontFamilyNotifier.value = savedFamily;
      }
    } catch (e) {
      debugPrint('FontSettingsService init error: $e');
    }
  }

  /// Update and persist font scale factor.
  static Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    fontScaleNotifier.value = clamped;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyFontScale, clamped);
    } catch (e) {
      debugPrint('Failed to save font scale: $e');
    }
  }

  /// Update and persist font family.
  static Future<void> setFontFamily(String family) async {
    fontFamilyNotifier.value = family;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFontFamily, family);
    } catch (e) {
      debugPrint('Failed to save font family: $e');
    }
  }

  /// Returns a human-friendly label for the current scale.
  static String getScaleLabel(double scale) {
    if (scale <= 0.88) return 'Compact (85%)';
    if (scale <= 1.05) return 'Standard (100%)';
    if (scale <= 1.20) return 'Comfortable (115%)';
    return 'Large (130%)';
  }
}
