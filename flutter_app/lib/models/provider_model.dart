class ProviderModel {
  final String id;
  final String name;
  final String service;
  final String area;
  final double rating;
  final double onTimeScore;
  final double pricePerHour;
  final String specialization;
  final bool available;
  final double cancellationRate;
  final String phone;
  final double? score;
  final String reasoning;

  const ProviderModel({
    required this.id,
    required this.name,
    required this.service,
    required this.area,
    required this.rating,
    required this.onTimeScore,
    required this.pricePerHour,
    required this.specialization,
    required this.available,
    required this.cancellationRate,
    required this.phone,
    this.score,
    this.reasoning = '',
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: _s(json['ID'] ?? json['id'] ?? json['provider_id'] ?? json['ProviderID']),
      name: _s(json['Name'] ?? json['name']),
      service: _s(json['Service'] ?? json['service']),
      area: _s(json['Area'] ?? json['area']),
      rating: _d(json['Rating'] ?? json['rating']),
      onTimeScore: _d(json['OnTimeScore'] ?? json['on_time_score'] ?? json['onTimeScore'] ?? json['ReliabilityScore']),
      pricePerHour: _d(json['PricePerHour'] ?? json['price_per_hour'] ?? json['pricePerHour'] ?? json['HourlyRate']),
      specialization: _s(json['Specialization'] ?? json['specialization']),
      available: _b(json['Available'] ?? json['available'] ?? json['Availability']),
      cancellationRate: _d(json['CancellationRate'] ?? json['cancellation_rate'] ?? json['cancellationRate']),
      phone: _s(json['Phone'] ?? json['phone']),
      score: json['score'] != null ? _d(json['score']) : null,
      reasoning: _s(json['reasoning']),
    );
  }

  static String _s(dynamic v) => v?.toString() ?? '';
  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
  static bool _b(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == 'yes' || s == '1';
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}
