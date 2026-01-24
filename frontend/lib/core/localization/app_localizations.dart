import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String get appName => translate('app_name');
  String get home => translate('home');
  String get workers => translate('workers');
  String get attendance => translate('attendance');
  String get payroll => translate('payroll');
  String get reports => translate('reports');
  String get settings => translate('settings');
  
  String get checkIn => translate('check_in');
  String get checkOut => translate('check_out');
  String get present => translate('present');
  String get absent => translate('absent');
  String get late => translate('late');
  String get excused => translate('excused');
  
  String get markAttendance => translate('mark_attendance');
  String get scanQrCode => translate('scan_qr_code');
  String get manualEntry => translate('manual_entry');
  String get verifyAttendance => translate('verify_attendance');
  
  String get dailyWorker => translate('daily_worker');
  String get permanentStaff => translate('permanent_staff');
  String get calculatePayroll => translate('calculate_payroll');
  String get approvePayroll => translate('approve_payroll');
  String get exportPayroll => translate('export_payroll');
  
  String get fullName => translate('full_name');
  String get employeeId => translate('employee_id');
  String get phoneNumber => translate('phone_number');
  String get site => translate('site');
  String get workType => translate('work_type');
  String get status => translate('status');
  
  String get registered => translate('registered');
  String get error => translate('error');
  String get alreadyRegistered => translate('already_registered');
  String get welcome => translate('welcome');
  
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  
  String get success => translate('success');
  String get failed => translate('failed');
  String get loading => translate('loading');
  
  String get exportToCBE => translate('export_to_cbe');
  String get exportToDashen => translate('export_to_dashen');
  String get exportToAwash => translate('export_to_awash');
  String get exportToTelebirr => translate('export_to_telebirr');
  String get cashPaymentSheet => translate('cash_payment_sheet');
  String get pensionDeclaration => translate('pension_declaration');
  
  String get offlineMode => translate('offline_mode');
  String get syncData => translate('sync_data');
  String get lastSync => translate('last_sync');
  String get exportToUSB => translate('export_to_usb');
  String get importFromUSB => translate('import_from_usb');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'am'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
