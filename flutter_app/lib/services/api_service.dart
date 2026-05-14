import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/agent_response.dart';
import '../models/booking.dart';
import '../models/provider_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ChatResult {
  final AgentResponse agent;
  final Booking? pendingBooking;
  const ChatResult({required this.agent, this.pendingBooking});
}

class ApiService {
  static const _base = AppConstants.baseUrl;
  static final _client = http.Client();
  static const _timeout = Duration(seconds: 45);

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_base$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
      throw ApiException(
        decoded['detail']?.toString() ?? 'Server error ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection error: $e');
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base$path'))
          .timeout(_timeout);
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
      throw ApiException(
        decoded['detail']?.toString() ?? 'Server error ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection error: $e');
    }
  }

  static Future<ChatResult> sendMessage({
    required String message,
    required String userName,
    required String sessionId,
    String responseLanguage = 'auto',
  }) async {
    final data = await _post('/chat', {
      'message': message,
      'user_name': userName,
      'session_id': sessionId,
      'response_language': responseLanguage,
    });
    final agent = AgentResponse.fromJson(data['agent'] as Map<String, dynamic>);
    Booking? pending;
    if (data['pending_booking'] is Map) {
      pending = Booking.fromJson(data['pending_booking'] as Map<String, dynamic>);
    }
    return ChatResult(agent: agent, pendingBooking: pending);
  }

  static Future<Booking> confirmBooking({
    required String sessionId,
    required String userName,
    required bool confirmed,
  }) async {
    final data = await _post('/confirm-booking', {
      'session_id': sessionId,
      'user_name': userName,
      'confirmed': confirmed,
    });
    return Booking.fromJson(data['booking'] as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> submitFeedback({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    return _post('/feedback', {
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
    });
  }

  static Future<List<ProviderModel>> getProviders() async {
    final data = await _get('/providers');
    return (data['providers'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProviderModel.fromJson)
        .toList();
  }

  static Future<Map<String, dynamic>> stressTestNoProvider() async {
    return _post('/stress-test/no-provider', {});
  }

  static Future<Map<String, dynamic>> stressTestCancellation() async {
    return _post('/stress-test/cancellation', {});
  }
}
