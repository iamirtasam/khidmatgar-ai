class PriceQuote {
  final double baseFee;
  final double distanceAdjustment;
  final double urgencySurcharge;
  final double loyaltyDiscount;
  final double total;
  final String breakdownExplanation;

  const PriceQuote({
    required this.baseFee,
    required this.distanceAdjustment,
    required this.urgencySurcharge,
    required this.loyaltyDiscount,
    required this.total,
    required this.breakdownExplanation,
  });

  factory PriceQuote.fromJson(Map<String, dynamic> json) {
    return PriceQuote(
      baseFee: _d(json['base_fee']),
      distanceAdjustment: _d(json['distance_adjustment']),
      urgencySurcharge: _d(json['urgency_surcharge']),
      loyaltyDiscount: _d(json['loyalty_discount']),
      total: _d(json['total']),
      breakdownExplanation: (json['breakdown_explanation'] ?? '').toString(),
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
