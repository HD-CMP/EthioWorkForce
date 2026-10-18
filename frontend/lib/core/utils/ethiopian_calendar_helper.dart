class EthiopianCalendarHelper {
  static const List<String> ethiopianMonthsEn = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit',
    'Megabit', 'Miazia', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagumen'
  ];

  static const List<String> ethiopianMonthsAm = [
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን'
  ];

  static Map<String, int> gregorianToEthiopian(DateTime gregorianDate) {
    const int jdOffset = 1723856;
    const int ethOffset = 2796;

    final int year = gregorianDate.year;
    final int month = gregorianDate.month;
    final int day = gregorianDate.day;

    final int a = (14 - month) ~/ 12;
    final int y = year + 4800 - a;
    final int m = month + 12 * a - 3;

    int jdn = day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;

    final int ethJDN = jdn - jdOffset + ethOffset;
    int ethYear = (ethJDN ~/ 365);
    int remainder = ethJDN % 365;

    if (remainder == 0) {
      ethYear--;
      remainder = 365;
    }

    int ethMonth = ((remainder - 1) ~/ 30) + 1;
    int ethDay = ((remainder - 1) % 30) + 1;

    return {
      'year': ethYear,
      'month': ethMonth,
      'day': ethDay,
    };
  }

  static DateTime ethiopianToGregorian(int ethYear, int ethMonth, int ethDay) {
    const int jdOffset = 1723856;
    const int ethOffset = 2796;

    final int ethJDN = (ethYear * 365) + ((ethMonth - 1) * 30) + ethDay;
    final int jdn = ethJDN + jdOffset - ethOffset;

    final int j = jdn + 32044;
    final int g = j ~/ 146097;
    final int dg = j % 146097;
    final int c = ((dg ~/ 36524) + 1) * 3 ~/ 4;
    final int dc = dg - c * 36524;
    final int b = dc ~/ 1461;
    final int db = dc % 1461;
    final int a = ((db ~/ 365) + 1) * 3 ~/ 4;
    final int da = db - a * 365;
    final int y = g * 400 + c * 100 + b * 4 + a;
    final int m = (da * 5 + 308) ~/ 153 - 2;
    final int d = da - (m + 4) * 153 ~/ 5 + 122;

    final int year = y - 4800 + (m + 2) ~/ 12;
    final int month = (m + 2) % 12 + 1;
    final int day = d + 1;

    return DateTime(year, month, day);
  }

  static String formatEthiopianDate(
    int year,
    int month,
    int day, {
    bool useAmharic = true,
  }) {
    if (month < 1 || month > 13) {
      return 'Invalid Date';
    }

    final monthName = useAmharic
        ? ethiopianMonthsAm[month - 1]
        : ethiopianMonthsEn[month - 1];

    return '$monthName $day, $year';
  }

  static String formatDualDate(DateTime gregorianDate, {bool useAmharic = true}) {
    final ethiopian = gregorianToEthiopian(gregorianDate);
    final ethDate = formatEthiopianDate(
      ethiopian['year']!,
      ethiopian['month']!,
      ethiopian['day']!,
      useAmharic: useAmharic,
    );

    final gregMonth = _getGregorianMonthName(gregorianDate.month);
    final gregDate = '$gregMonth ${gregorianDate.day}, ${gregorianDate.year}';

    return useAmharic ? '$ethDate\n$gregDate' : '$gregDate\n$ethDate';
  }

  static String _getGregorianMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  static int getCurrentEthiopianYear() {
    final today = DateTime.now();
    final ethiopian = gregorianToEthiopian(today);
    return ethiopian['year']!;
  }

  static Map<String, int> getCurrentEthiopianDate() {
    return gregorianToEthiopian(DateTime.now());
  }

  static String getEthiopianMonthName(int month, {bool useAmharic = true}) {
    if (month < 1 || month > 13) {
      return 'Invalid';
    }
    return useAmharic ? ethiopianMonthsAm[month - 1] : ethiopianMonthsEn[month - 1];
  }

  static int getEthiopianFiscalYear(DateTime gregorianDate) {
    final ethiopian = gregorianToEthiopian(gregorianDate);
    final month = ethiopian['month']!;
    final year = ethiopian['year']!;

    if (month >= 11) {
      return year + 1;
    }
    return year;
  }

  static bool isEthiopianLeapYear(int year) {
    return (year % 4) == 3;
  }

  static int getDaysInEthiopianMonth(int month, int year) {
    if (month >= 1 && month <= 12) {
      return 30;
    } else if (month == 13) {
      return isEthiopianLeapYear(year) ? 6 : 5;
    }
    return 0;
  }
}
