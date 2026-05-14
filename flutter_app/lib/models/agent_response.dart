import 'provider_model.dart';
import 'price_quote.dart';

class TopProvider {
  final String providerId;
  final String name;
  final double score;
  final String reasoning;
  final double rating;
  final int pricePerHour;
  final int onTimeScore;
  final String cancellationRate;
  final String specialization;
  final String area;
  final String phone;
  final bool available;

  const TopProvider({
    required this.providerId,
    required this.name,
    required this.score,
    required this.reasoning,
    this.rating = 0.0,
    this.pricePerHour = 0,
    this.onTimeScore = 0,
    this.cancellationRate = '',
    this.specialization = '',
    this.area = '',
    this.phone = '',
    this.available = false,
  });

  factory TopProvider.fromJson(Map<String, dynamic> json) {
    return TopProvider(
      providerId: json['provider_id']?.toString() ?? json['providerID']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      score: _d(json['score']),
      reasoning: json['reasoning']?.toString() ?? '',
      rating: _d(json['rating']),
      pricePerHour: _i(json['pricePerHour'] ?? json['PricePerHour'] ?? json['price_per_hour'] ?? 0),
      onTimeScore: _i(json['onTimeScore'] ?? json['OnTimeScore'] ?? json['on_time_score'] ?? 0),
      cancellationRate: json['cancellationRate']?.toString() ?? json['CancellationRate']?.toString() ?? json['cancellation_rate']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? json['Specialization']?.toString() ?? '',
      area: json['area']?.toString() ?? json['Area']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['Phone']?.toString() ?? '',
      available: json['available'] == true || json['Available'] == true,
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class ExtractedIntent {
  final String? serviceType;
  final String? location;
  final String? preferredTime;
  final String? urgency;
  final String? budgetSensitivity;

  const ExtractedIntent({
    this.serviceType,
    this.location,
    this.preferredTime,
    this.urgency,
    this.budgetSensitivity,
  });

  factory ExtractedIntent.fromJson(Map<String, dynamic> json) {
    return ExtractedIntent(
      serviceType: json['service_type']?.toString(),
      location: json['location']?.toString(),
      preferredTime: json['preferred_time']?.toString(),
      urgency: json['urgency']?.toString(),
      budgetSensitivity: json['budget_sensitivity']?.toString(),
    );
  }

  bool get hasAnyValue =>
      (serviceType?.isNotEmpty ?? false) ||
      (location?.isNotEmpty ?? false) ||
      (preferredTime?.isNotEmpty ?? false);
}

class RankingFactors {
  final double specialization;
  final double availability;
  final double reliability;
  final double distance;
  final double rating;
  final double price;

  const RankingFactors({
    this.specialization = 0,
    this.availability = 0,
    this.reliability = 0,
    this.distance = 0,
    this.rating = 0,
    this.price = 0,
  });

  factory RankingFactors.fromJson(Map<String, dynamic> json) {
    return RankingFactors(
      specialization: _d(json['specialization']),
      availability: _d(json['availability']),
      reliability: _d(json['reliability']),
      distance: _d(json['distance']),
      rating: _d(json['rating']),
      price: _d(json['price']),
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class AgentResponse {
  final double confidenceScore;
  final bool clarificationNeeded;
  final String? clarificationQuestion;
  final ExtractedIntent? extractedIntent;
  final List<TopProvider> topProviders;
  final RankingFactors? rankingFactors;
  final ProviderModel? recommendedProvider;
  final PriceQuote? priceQuote;
  final String? bookingAction;
  final List<String> agentReasoningTrace;

  const AgentResponse({
    required this.confidenceScore,
    required this.clarificationNeeded,
    this.clarificationQuestion,
    this.extractedIntent,
    required this.topProviders,
    this.rankingFactors,
    this.recommendedProvider,
    this.priceQuote,
    this.bookingAction,
    required this.agentReasoningTrace,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      confidenceScore: _d(json['confidence_score']),
      clarificationNeeded: json['clarification_needed'] == true,
      clarificationQuestion: json['clarification_question']?.toString(),
      extractedIntent: json['extracted_intent'] is Map
          ? ExtractedIntent.fromJson(json['extracted_intent'])
          : null,
      topProviders: (json['top_providers'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TopProvider.fromJson)
          .toList(),
      rankingFactors: json['ranking_factors'] is Map
          ? RankingFactors.fromJson(json['ranking_factors'])
          : null,
      recommendedProvider: json['recommended_provider'] is Map
          ? ProviderModel.fromJson(json['recommended_provider'])
          : null,
      priceQuote: json['price_quote'] is Map
          ? PriceQuote.fromJson(json['price_quote'])
          : null,
      bookingAction: json['booking_action']?.toString(),
      agentReasoningTrace: (json['agent_reasoning_trace'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
