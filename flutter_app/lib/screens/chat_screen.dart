import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/chat_provider.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/agent_response_card.dart';
import 'booking_confirm_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _goToConfirm(BuildContext context) {
    final cp = context.read<ChatProvider>();
    final agent = cp.lastAgentResponse;
    if (agent == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookingConfirmScreen(
        agentResponse: agent,
        sessionId: cp.sessionId,
        userName: cp.userName,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryGreen,
        title: Column(
          children: [
            Text('KhidmatGar Agent',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            Text('خدمتگار ایجنٹ',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w500)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (_, cp, _) => IconButton(
              icon: const Icon(Icons.refresh_outlined, color: Colors.white),
              tooltip: 'Naya session',
              onPressed: () {
                cp.startNewSession();
                _scrollToBottom();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat list
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (_, cp, _) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom());
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount:
                        cp.messages.length + (cp.isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == cp.messages.length && cp.isTyping) {
                        return const TypingIndicator();
                      }
                      final msg = cp.messages[i];
                      if (msg.role == MessageRole.user) {
                        return _UserBubble(text: msg.text);
                      }
                      return _AgentBubble(
                        text: msg.text,
                        agentResponseCard: msg.agentResponse != null
                            ? AgentResponseCard(
                                response: msg.agentResponse!,
                                showActions: i == cp.messages.length - 1 &&
                                    msg.agentResponse!.recommendedProvider !=
                                        null &&
                                    !msg.agentResponse!.clarificationNeeded,
                                onConfirm: () => _goToConfirm(context),
                                onCancel: () {
                                  cp.confirmBooking(false);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Booking cancel kar di gayi'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                },
                              )
                            : null,
                        isError: msg.role == MessageRole.error,
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            _InputBar(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Agent bubble ─────────────────────────────────────────────────────────────

class _AgentBubble extends StatelessWidget {
  final String text;
  final Widget? agentResponseCard;
  final bool isError;

  const _AgentBubble({
    required this.text,
    this.agentResponseCard,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isError ? Colors.red : AppConstants.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isError ? '!' : 'خ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red[50]
                          : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isError ? Colors.red[700] : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (agentResponseCard != null) ...[
                    const SizedBox(height: 8),
                    agentResponseCard!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, cp, _) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: !cp.isTyping,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'AC repair chahiye... or plumber bulao...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => cp.isTyping ? null : widget.onSend(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                onPressed:
                    cp.isTyping || !_hasText ? null : widget.onSend,
                backgroundColor: cp.isTyping || !_hasText
                    ? Colors.grey[300]
                    : AppConstants.primaryGreen,
                elevation: _hasText ? 3 : 0,
                child: cp.isTyping
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
