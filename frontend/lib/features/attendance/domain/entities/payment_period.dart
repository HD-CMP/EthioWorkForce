class PaymentPeriod {
  final int id;
  final int siteId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int periodDays;
  final String status;
  final bool isCurrent;

  PaymentPeriod({
    required this.id,
    required this.siteId,
    required this.periodStart,
    required this.periodEnd,
    required this.periodDays,
    required this.status,
    required this.isCurrent,
  });

  factory PaymentPeriod.fromJson(Map<String, dynamic> json) {
    return PaymentPeriod(
      id: json['id'] as int,
      siteId: json['site_id'] as int,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      periodDays: json['period_days'] as int,
      status: json['status'] as String,
      isCurrent: json['is_current'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'period_days': periodDays,
      'status': status,
      'is_current': isCurrent,
    };
  }
}
