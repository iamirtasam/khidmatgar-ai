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

class _AgentResponseCardState extends State<AgentResponseCard> {
  bool _traceExpanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.response;
    final hasProviders = r.topProviders.isNotEmpty || r.recommendedProvider != null;

    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence bar
          _ConfidenceBar(score: r.confidenceScore),
          const SizedBox(height: 10),

          // Intent chips
          if (r.extractedIntent != null &&
              r.extractedIntent!.hasAnyValue) ...[
            IntentChipsRow(intent: r.extractedIntent!),
            const SizedBox(height: 12),
          ],

          // Top providers
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
              return ProviderCardWidget(
                provider: p,
                isRecommended: isRec,
              );
            }),
            // If recommended provider not in top list, show it separately
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

          // Price quote
          if (r.priceQuote != null && r.priceQuote!.total > 0) ...[
            PriceQuoteCard(quote: r.priceQuote!),
            const SizedBox(height: 10),
          ],

          // Reasoning trace accordion
          if (r.agentReasoningTrace.isNotEmpty) ...[
            InkWell(
              onTap: () =>
                  setState(() => _traceExpanded = !_traceExpanded),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'AI Reasoning Trace',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Icon(
                      _traceExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_traceExpanded) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: r.agentReasoningTrace.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],

          // Action buttons
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
