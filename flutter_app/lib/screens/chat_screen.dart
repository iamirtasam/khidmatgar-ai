import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
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
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Purani Baatein',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _ChatHistorySheet(),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (_, cp, _) {
              final lang = cp.responseLanguage;
              final label = lang == 'urdu'
                  ? 'UR'
                  : lang == 'english'
                      ? 'EN'
                      : 'AUTO';
              return Tooltip(
                message: 'Response language: tap to cycle AUTO → EN → UR',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    final next = lang == 'auto'
                        ? 'english'
                        : lang == 'english'
                            ? 'urdu'
                            : 'auto';
                    cp.setResponseLanguage(next);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(next == 'urdu'
                          ? 'Responses: Roman Urdu'
                          : next == 'english'
                              ? 'Responses: English only'
                              : 'Responses: Auto-detect'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              );
            },
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

class _InputBarState extends State<_InputBar> with TickerProviderStateMixin {
  bool _hasText = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _selectedLocale = 'auto';
  final SpeechToText _speech = SpeechToText();
  final List<AnimationController> _barCtrls = [];
  final List<Animation<double>> _barAnims = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _initBarAnimations();
    _initSpeech();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _initBarAnimations() {
    const durations = [280, 340, 260, 380, 300];
    for (int i = 0; i < 5; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durations[i]),
      );
      _barCtrls.add(ctrl);
      _barAnims.add(Tween<double>(begin: 0.12, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      ));
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (e) => _onSpeechError(),
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (!mounted) return;
      setState(() => _isListening = false);
      _stopBars();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (widget.controller.text.trim().isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) widget.onSend();
        });
      }
    }
  }

  void _onSpeechError() {
    if (!mounted) return;
    setState(() => _isListening = false);
    _stopBars();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _startBars() {
    for (int i = 0; i < _barCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 55), () {
        if (mounted && _isListening) _barCtrls[i].repeat(reverse: true);
      });
    }
  }

  void _stopBars() {
    for (final c in _barCtrls) {
      c.stop();
      c.animateTo(0.0, duration: const Duration(milliseconds: 150));
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      final messenger = ScaffoldMessenger.of(context);
      await _speech.stop();
      setState(() => _isListening = false);
      _stopBars();
      messenger.hideCurrentSnackBar();
      return;
    }
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Voice input not supported on this device'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isListening = true);
    _startBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        _selectedLocale == 'ur-PK'
            ? 'بول رہے ہیں... (Speaking...)'
            : 'Bol rahe hain... (Speaking...)',
      ),
      duration: const Duration(seconds: 60),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red[700],
    ));
    String localeId = 'en-US';
    try {
      if (_selectedLocale == 'auto' || _selectedLocale == 'ur-PK') {
        final locales = await _speech.locales();
        if (locales.isNotEmpty) {
          final preferred = locales.firstWhere(
            (l) => l.localeId.startsWith('ur'),
            orElse: () => locales.firstWhere(
              (l) => l.localeId.startsWith('en'),
              orElse: () => locales.first,
            ),
          );
          localeId = preferred.localeId;
        }
      } else {
        localeId = _selectedLocale;
      }
    } catch (_) {}
    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final text = result.recognizedWords;
          widget.controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (_) {
      _onSpeechError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Voice input error, please type instead'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('Select Language',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const Divider(),
          ListTile(
            leading: const Text('🌐', style: TextStyle(fontSize: 22)),
            title: Text('Auto-detect', style: GoogleFonts.poppins()),
            trailing: _selectedLocale == 'auto'
                ? const Icon(Icons.check_rounded,
                    color: AppConstants.primaryGreen)
                : null,
            onTap: () {
              setState(() => _selectedLocale = 'auto');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇵🇰', style: TextStyle(fontSize: 22)),
            title: Text('اردو (Urdu)', style: GoogleFonts.poppins()),
            subtitle: Text('ur-PK',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey)),
            trailing: _selectedLocale == 'ur-PK'
                ? const Icon(Icons.check_rounded,
                    color: AppConstants.primaryGreen)
                : null,
            onTap: () {
              setState(() => _selectedLocale = 'ur-PK');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
            title: Text('English (en-US)', style: GoogleFonts.poppins()),
            trailing: _selectedLocale == 'en-US'
                ? const Icon(Icons.check_rounded,
                    color: AppConstants.primaryGreen)
                : null,
            onTap: () {
              setState(() => _selectedLocale = 'en-US');
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _speech.stop();
    for (final c in _barCtrls) {
      c.dispose();
    }
    super.dispose();
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
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isListening) ...[_SoundWaveWidget(barAnims: _barAnims), const SizedBox(height: 4)],
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleListening,
                  onLongPress: _showLanguageSelector,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : Colors.grey[100],
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.45),
                                blurRadius: 14,
                                spreadRadius: 2,
                              )
                            ]
                          : [
                              const BoxShadow(
                                color: Colors.transparent,
                                blurRadius: 0,
                                spreadRadius: 0,
                              )
                            ],
                    ),
                    child: Icon(
                      _isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      color:
                          _isListening ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: !cp.isTyping,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'بول رہے ہیں...'
                          : 'AC repair chahiye... or plumber bulao...',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _isListening
                          ? Colors.red.withValues(alpha: 0.04)
                          : const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) =>
                        cp.isTyping ? null : widget.onSend(),
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
          ],
        ),
      ),
    );
  }
}

class _SoundWaveWidget extends StatelessWidget {
  final List<Animation<double>> barAnims;
  const _SoundWaveWidget({required this.barAnims});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: barAnims
                .map((anim) => AnimatedBuilder(
                      animation: anim,
                      builder: (_, _) => Container(
                        width: 4,
                        height: 6 + (22 * anim.value),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ── Chat history bottom sheet ─────────────────────────────────────────────────

class _ChatHistorySheet extends StatefulWidget {
  const _ChatHistorySheet();

  @override
  State<_ChatHistorySheet> createState() => _ChatHistorySheetState();
}

class _ChatHistorySheetState extends State<_ChatHistorySheet> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await context.read<ChatProvider>().loadConversationHistory();
    if (mounted) setState(() => _loading = false);
  }

  void _confirmClearAll(ChatProvider cp) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('History Clear Karein?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Sab purani baatein hamesha ke liye mit jayengi.',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              cp.clearAllHistory();
            },
            child: Text('Clear All',
                style: GoogleFonts.poppins(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, cp, _) {
        final history = cp.conversationHistory;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF1F8E9),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin:
                      const EdgeInsets.only(top: 12, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: AppConstants.primaryGreen, size: 22),
                    const SizedBox(width: 8),
                    Text('Purani Baatein',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                )
              else if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Koi purani baat nahi',
                          style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 14)),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height * 0.5),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const Divider(
                        height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final item = history[i];
                      final sid =
                          item['session_id'] as String? ?? '';
                      final ts =
                          item['timestamp'] as String? ?? '';
                      final preview =
                          item['preview'] as String? ?? '';
                      final count =
                          item['message_count'] as int? ?? 0;
                      String dateStr = '';
                      try {
                        dateStr = DateFormat('dd MMM, hh:mm a')
                            .format(DateTime.parse(ts).toLocal());
                      } catch (_) {}
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'Chat history view coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_rounded,
                              color: Colors.white, size: 18),
                        ),
                        title: Text(
                          preview.isEmpty ? 'Chat session' : preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(dateStr,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[500])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryGreen
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text('$count msgs',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color:
                                          AppConstants.primaryGreen,
                                      fontWeight:
                                          FontWeight.w600)),
                            ),
                            IconButton(
                              icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.red[400]),
                              onPressed: () =>
                                  cp.deleteSessionFromHistory(sid),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (!_loading && history.isNotEmpty) ...[
                const Divider(height: 1),
                TextButton.icon(
                  onPressed: () => _confirmClearAll(cp),
                  icon: Icon(Icons.delete_forever_rounded,
                      size: 16, color: Colors.red[700]),
                  label: Text('Clear All History',
                      style: GoogleFonts.poppins(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600)),
                ),
              ],
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}
