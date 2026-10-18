class EthiopianBank {
  final String name;
  final String code;
  final String logo;
  final int accountNumberLength;
  final String accountPattern;

  const EthiopianBank({
    required this.name,
    required this.code,
    required this.logo,
    required this.accountNumberLength,
    required this.accountPattern,
  });

  bool validateAccountNumber(String accountNumber) {
    final cleaned = accountNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != accountNumberLength) return false;
    return RegExp(accountPattern).hasMatch(cleaned);
  }

  String formatAccountNumber(String accountNumber) {
    final cleaned = accountNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return '';
    
    switch (code) {
      case 'CBE':
        if (cleaned.length <= 7) return cleaned;
        return '${cleaned.substring(0, 7)}-${cleaned.substring(7)}';
      case 'BOA':
      case 'AIB':
        if (cleaned.length <= 4) return cleaned;
        if (cleaned.length <= 8) {
          return '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
        }
        return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}-${cleaned.substring(8)}';
      default:
        if (cleaned.length <= 4) return cleaned;
        return cleaned.replaceAllMapped(
          RegExp(r'(\d{4})(?=\d)'),
          (match) => '${match.group(0)}-',
        );
    }
  }
}

class EthiopianBanks {
  static const commercialBank = EthiopianBank(
    name: 'Commercial Bank of Ethiopia (CBE)',
    code: 'CBE',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const dashenBank = EthiopianBank(
    name: 'Dashen Bank',
    code: 'DSH',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const bankOfAbyssinia = EthiopianBank(
    name: 'Bank of Abyssinia',
    code: 'BOA',
    logo: '🏦',
    accountNumberLength: 12,
    accountPattern: r'^\d{12}$',
  );

  static const awashBank = EthiopianBank(
    name: 'Awash International Bank',
    code: 'AIB',
    logo: '🏦',
    accountNumberLength: 12,
    accountPattern: r'^\d{12}$',
  );

  static const nib = EthiopianBank(
    name: 'Nib International Bank',
    code: 'NIB',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const wegagen = EthiopianBank(
    name: 'Wegagen Bank',
    code: 'WEG',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const unitedBank = EthiopianBank(
    name: 'United Bank',
    code: 'UNI',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const oromiaBank = EthiopianBank(
    name: 'Oromia International Bank',
    code: 'OIB',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const cooperativeBank = EthiopianBank(
    name: 'Cooperative Bank of Oromia',
    code: 'CBO',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const lionBank = EthiopianBank(
    name: 'Lion International Bank',
    code: 'LIB',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const zemenBank = EthiopianBank(
    name: 'Zemen Bank',
    code: 'ZEM',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const bunnaBank = EthiopianBank(
    name: 'Bunna International Bank',
    code: 'BUN',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const berhanBank = EthiopianBank(
    name: 'Berhan International Bank',
    code: 'BER',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const abayBank = EthiopianBank(
    name: 'Abay Bank',
    code: 'ABY',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const addisBank = EthiopianBank(
    name: 'Addis International Bank',
    code: 'ADB',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const debubBank = EthiopianBank(
    name: 'Debub Global Bank',
    code: 'DGB',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const enatBank = EthiopianBank(
    name: 'Enat Bank',
    code: 'ENT',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const gadaBank = EthiopianBank(
    name: 'Gada Bank',
    code: 'GAD',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const sinaBank = EthiopianBank(
    name: 'Siinqee Bank',
    code: 'SIN',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static const hijraBank = EthiopianBank(
    name: 'Hijra Bank',
    code: 'HIJ',
    logo: '🏦',
    accountNumberLength: 13,
    accountPattern: r'^\d{13}$',
  );

  static final List<EthiopianBank> all = [
    commercialBank,
    dashenBank,
    bankOfAbyssinia,
    awashBank,
    nib,
    wegagen,
    unitedBank,
    oromiaBank,
    cooperativeBank,
    lionBank,
    zemenBank,
    bunnaBank,
    berhanBank,
    abayBank,
    addisBank,
    debubBank,
    enatBank,
    gadaBank,
    sinaBank,
    hijraBank,
  ];

  static EthiopianBank? findByCode(String code) {
    try {
      return all.firstWhere((bank) => bank.code == code);
    } catch (e) {
      return null;
    }
  }

  static EthiopianBank? detectBankFromAccount(String accountNumber) {
    final cleaned = accountNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;

    for (final bank in all) {
      if (bank.validateAccountNumber(cleaned)) {
        return bank;
      }
    }
    return null;
  }
}
