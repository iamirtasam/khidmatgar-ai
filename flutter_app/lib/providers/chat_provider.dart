import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/agent_response.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

enum MessageRole { user, agent, error }

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final AgentResponse? agentResponse;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    this.agentResponse,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatProvider extends ChangeNotifier {
  static final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _sessionId = _uuid.v4();
  String _userName = '';
  Booking? _pendingBooking;
  AgentResponse? _lastAgentResponse;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String get sessionId => _sessionId;
  String get userName => _userName;
  Booking? get pendingBooking => _pendingBooking;
  AgentResponse? get lastAgentResponse => _lastAgentResponse;
  String? get error => _error;
  bool get hasPendingBooking => _pendingBooking != null;

  void setUserName(String name) {
    _userName = name.trim();
    notifyListeners();
  }

  void startNewSession() {
    _sessionId = _uuid.v4();
    _messages.clear();
    _pendingBooking = null;
    _lastAgentResponse = null;
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(ChatMessage(
      id: _uuid.v4(),
      text: trimmed,
      role: MessageRole.user,
    ));
    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.sendMessage(
        message: trimmed,
        userName: _userName,
        sessionId: _sessionId,
      );

      final agent = result.agent;
      _lastAgentResponse = agent;
      _pendingBooking = result.pendingBooking;

      final String bubbleText;
      if (agent.clarificationNeeded &&
          (agent.clarificationQuestion?.isNotEmpty ?? false)) {
        bubbleText = agent.clarificationQuestion!;
      } else if (agent.recommendedProvider != null) {
        bubbleText =
            'Shukriya! Maine aapke liye best provider dhund liya. 🎯\n'
            'Neeche details dekhein aur booking confirm karein.';
      } else if (agent.bookingAction?.isNotEmpty ?? false) {
        bubbleText = agent.bookingAction!;
      } else {
        bubbleText = 'Request process ho gayi. Neeche details dekhein.';
      }

      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: bubbleText,
        role: MessageRole.agent,
        agentResponse: agent,
      ));
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: 'Maafi chahta hoon, ek masla aaya: $_error',
        role: MessageRole.error,
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<Booking?> confirmBooking(bool confirmed) async {
    try {
      final booking = await ApiService.confirmBooking(
        sessionId: _sessionId,
        userName: _userName,
        confirmed: confirmed,
      );
      _pendingBooking = null;
      notifyListeners();
      return booking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
