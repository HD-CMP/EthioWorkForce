class EthiopianCalendar {
  static const List<String> monthsEnglish = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit',
    'Megabit', 'Miazia', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagumen'
  ];

  static const List<String> monthsAmharic = [
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን'
  ];

  static EthiopianDate fromGregorian(DateTime gregorianDate) {
    int year = gregorianDate.year;
    int month = gregorianDate.month;
    int day = gregorianDate.day;

    int jdn = _gregorianToJDN(year, month, day);
    
    return _jdnToEthiopian(jdn);
  }

  static DateTime toGregorian(int ethYear, int ethMonth, int ethDay) {
    int jdn = _ethiopianToJDN(ethYear, ethMonth, ethDay);
    
    return _jdnToGregorian(jdn);
  }

  static int _gregorianToJDN(int year, int month, int day) {
    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    
    return day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    int a = jdn + 32044;
    int b = (4 * a + 3) ~/ 146097;
    int c = a - (146097 * b) ~/ 4;
    
    int d = (4 * c + 3) ~/ 1461;
    int e = c - (1461 * d) ~/ 4;
    int m = (5 * e + 2) ~/ 153;
    
    int day = e - (153 * m + 2) ~/ 5 + 1;
    int month = m + 3 - 12 * (m ~/ 10);
    int year = 100 * b + d - 4800 + m ~/ 10;
    
    return DateTime(year, month, day);
  }

  static EthiopianDate _jdnToEthiopian(int jdn) {
    int r = (jdn - 1723856) % 1461;
    int n = (r % 365) + 365 * (r ~/ 1460);
    
    int year = 4 * ((jdn - 1723856) ~/ 1461) + r ~/ 365 - r ~/ 1460;
    int month = (n ~/ 30) + 1;
    int day = (n % 30) + 1;
    
    return EthiopianDate(year, month, day);
  }

  static int _ethiopianToJDN(int year, int month, int day) {
    return (1723856 + 365) + 365 * (year - 1) + (year ~/ 4) + 30 * month + day - 31;
  }

  static String formatEthiopian(EthiopianDate date, {bool useAmharic = false}) {
    final months = useAmharic ? monthsAmharic : monthsEnglish;
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class EthiopianDate {
  final int year;
  final int month;
  final int day;

  EthiopianDate(this.year, this.month, this.day);

  @override
  String toString() => '$year-$month-$day';
}
