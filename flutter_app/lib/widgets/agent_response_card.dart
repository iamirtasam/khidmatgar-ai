import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/agent_response.dart';
import '../constants/app_constants.dart';
import 'intent_chips_row.dart';
import 'provider_card_widget.dart';
import 'price_quote_card.dart';

class AgentResponseCard extends StatefulWidget {
  final AgentResponse response;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showActions;

  const AgentResponseCard({
    super.key,
    required this.response,
    this.onConfirm,
    this.onCancel,
    this.showActions = true,
  });

  @override
  State<AgentResponseCard> createState() => _AgentResponseCardState();
}

class _AgentResponseCardState extends State<AgentResponseCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _completeCtrl;
  late Animation<double> _completeFade;
  final List<AnimationController> _stepCtrls = [];
  final List<Animation<double>> _stepFades = [];
  final List<Animation<Offset>> _stepSlides = [];
  int _visibleSteps = 0;
  bool _analysisComplete = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.35, end: 1.0).animate(_shimmerCtrl);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.3)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _completeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _completeFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _completeCtrl, curve: Curves.easeOut));

    for (final _ in widget.response.agentReasoningTrace) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 380));
      _stepCtrls.add(ctrl);
      _stepFades.add(Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)));
      _stepSlides.add(
          Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack)));
    }
    _startThinking();
  }

  Future<void> _startThinking() async {
    await Future.delayed(const Duration(milliseconds: 250));
    for (int i = 0; i < _stepCtrls.length; i++) {
      if (!mounted) return;
      setState(() => _visibleSteps = i + 1);
      _stepCtrls[i].forward();
      await Future.delayed(const Duration(milliseconds: 420));
    }
    if (!mounted) return;
    _shimmerCtrl.stop();
    _pulseCtrl.stop();
    setState(() => _analysisComplete = true);
    _completeCtrl.forward();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _completeCtrl.dispose();
    for (final c in _stepCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.response;
    final hasProviders =
        r.topProviders.isNotEmpty || r.recommendedProvider != null;

    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConfidenceBar(score: r.confidenceScore),
          const SizedBox(height: 10),

          if (r.extractedIntent != null && r.extractedIntent!.hasAnyValue) ...[
            IntentChipsRow(intent: r.extractedIntent!),
            const SizedBox(height: 12),
          ],

          if (hasProviders) ...[
            Text(
              'Top Providers',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ...r.topProviders.map((p) {
              final isRec = r.recommendedProvider != null &&
                  (p.providerId == r.recommendedProvider!.id ||
                      p.name == r.recommendedProvider!.name);
              return ProviderCardWidget(provider: p, isRecommended: isRec);
            }),
            if (r.recommendedProvider != null &&
                !r.topProviders.any((p) =>
                    p.providerId == r.recommendedProvider!.id ||
                    p.name == r.recommendedProvider!.name))
              ProviderCardWidget(
                provider: r.recommendedProvider!,
                isRecommended: true,
                isExpanded: true,
              ),
            const SizedBox(height: 10),
          ],

          if (r.priceQuote != null && r.priceQuote!.total > 0) ...[
            PriceQuoteCard(quote: r.priceQuote!),
            const SizedBox(height: 10),
          ],

          if (r.agentReasoningTrace.isNotEmpty) ...[
            _buildThinkingTimeline(r.agentReasoningTrace),
            const SizedBox(height: 10),
          ],

          if (widget.showActions &&
              r.recommendedProvider != null &&
              !r.clarificationNeeded) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close, size: 16),
                    label: Text('Cancel',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.errorRed,
                      side: const BorderSide(color: AppConstants.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.onConfirm,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text('Confirm Booking',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingTimeline(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppConstants.primaryGreen.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 18, color: AppConstants.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (_, _) => Opacity(
                    opacity: _analysisComplete ? 1.0 : _shimmerAnim.value,
                    child: Text(
                      _analysisComplete
                          ? 'Analysis Complete'
                          : 'AI Thinking...',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
              if (_analysisComplete)
                FadeTransition(
                  opacity: _completeFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('Done',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, _) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppConstants.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_visibleSteps > 0) ...[
            const SizedBox(height: 12),
            ...List.generate(_visibleSteps, (i) {
              final isAppearing = (i == _visibleSteps - 1) && !_analysisComplete;
              return SlideTransition(
                position: _stepSlides[i],
                child: FadeTransition(
                  opacity: _stepFades[i],
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 14,
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, _) => Transform.scale(
                                  scale: isAppearing ? _pulseAnim.value : 1.0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isAppearing
                                          ? Colors.green[400]
                                          : AppConstants.primaryGreen,
                                      shape: BoxShape.circle,
                                      boxShadow: isAppearing
                                          ? [
                                              BoxShadow(
                                                color: Colors.green
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 7,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : [],
                                    ),
                                  ),
                                ),
                              ),
                              if (i < _visibleSteps - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppConstants.primaryGreen
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    i < _visibleSteps - 1 ? 10.0 : 0.0),
                            child: Text(
                              steps[i],
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[700]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double score;
  const _ConfidenceBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score / 100).clamp(0.0, 1.0);
    final color = score >= 70
        ? AppConstants.primaryGreen
        : score >= 40
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Confidence',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            ),
            const Spacer(),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
