import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/agent_response.dart';
import '../models/booking.dart';
import '../providers/chat_provider.dart';
import '../models/price_quote.dart';
import '../models/provider_model.dart';
import 'feedback_screen.dart';

class BookingConfirmScreen extends StatefulWidget {
  final AgentResponse agentResponse;
  final String sessionId;
  final String userName;

  const BookingConfirmScreen({
    super.key,
    required this.agentResponse,
    required this.sessionId,
    required this.userName,
  });

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _isLoading = false;
  bool _confirmed = false;
  Booking? _booking;
  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirm(bool yes) async {
    setState(() => _isLoading = true);
    final booking =
        await context.read<ChatProvider>().confirmBooking(yes);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _confirmed = yes;
      _booking = booking;
    });
  }

  Color get _avatarColor {
    final p = widget.agentResponse.recommendedProvider;
    if (p == null) return AppConstants.primaryGreen;
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF0277BD),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
    ];
    return colors[p.name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.agentResponse.recommendedProvider;
    final q = widget.agentResponse.priceQuote;
    final intent = widget.agentResponse.extractedIntent;

    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        title: Text(_confirmed ? 'Booking Confirmed' : 'Booking Confirm Karein',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _confirmed ? _SuccessView(
        booking: _booking,
        provider: p,
        quote: q,
        intent: intent,
        onFeedback: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FeedbackScreen(
            bookingId: _booking?.bookingId ?? '',
            providerName: p?.name ?? '',
          ),
        )),
        onDone: () =>
            Navigator.of(context).popUntil((r) => r.isFirst),
      ) : _ConfirmView(
        provider: p,
        quote: q,
        intent: intent,
        avatarColor: _avatarColor,
        isLoading: _isLoading,
        onConfirm: () => _confirm(true),
        onCancel: () => _confirm(false),
      ),
    );
  }
}

// ── Confirm view ─────────────────────────────────────────────────────────────

class _ConfirmView extends StatelessWidget {
  final dynamic provider;
  final dynamic quote;
  final dynamic intent;
  final Color avatarColor;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmView({
    this.provider,
    this.quote,
    this.intent,
    required this.avatarColor,
    required this.isLoading,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (provider == null) {
      return Center(
        child: Text('No provider selected',
            style: GoogleFonts.poppins(color: Colors.grey)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Provider card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: avatarColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2)
                      ],
                    ),
                    child: Center(
                      child: Text(
                        provider!.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    provider!.name.isNotEmpty ? provider!.name : 'Provider',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppConstants.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          'Best Match',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[800]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _DetailRow(
                      icon: Icons.build_outlined,
                      label: 'Service',
                      value: provider!.service),
                  _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Area',
                      value: provider!.area),
                  _DetailRow(
                      icon: Icons.star_outline,
                      label: 'Rating',
                      value: '${provider!.rating.toStringAsFixed(1)} / 5.0'),
                  _DetailRow(
                      icon: Icons.timer_outlined,
                      label: 'On-Time Rate',
                      value: '${provider!.onTimeScore.toStringAsFixed(0)}%'),
                  if (provider!.phone.isNotEmpty)
                    _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: provider!.phone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Booking slot
          if (intent?.preferredTime?.isNotEmpty ?? false)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined,
                    color: AppConstants.primaryGreen),
                title: Text('Booking Slot',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
                subtitle: Text(
                  intent!.preferredTime!,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // Price breakdown
          if (quote != null && (quote!.total) > 0) ...[
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PriceRow(
                        label: 'Base Fee',
                        value: 'PKR ${quote!.baseFee.toStringAsFixed(0)}'),
                    if (quote!.distanceAdjustment > 0)
                      _PriceRow(
                          label: 'Distance',
                          value:
                              '+ PKR ${quote!.distanceAdjustment.toStringAsFixed(0)}'),
                    if (quote!.urgencySurcharge > 0)
                      _PriceRow(
                          label: 'Urgency',
                          value:
                              '+ PKR ${quote!.urgencySurcharge.toStringAsFixed(0)}'),
                    if (quote!.loyaltyDiscount > 0)
                      _PriceRow(
                          label: 'Loyalty Discount',
                          value:
                              '- PKR ${quote!.loyaltyDiscount.toStringAsFixed(0)}',
                          color: Colors.green),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(
                          'PKR ${quote!.total.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppConstants.primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.errorRed,
                    side: const BorderSide(color: AppConstants.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Radd Karein',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Confirm Booking',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatefulWidget {
  final Booking? booking;
  final ProviderModel? provider;
  final PriceQuote? quote;
  final ExtractedIntent? intent;
  final VoidCallback onFeedback;
  final VoidCallback onDone;

  const _SuccessView({
    this.booking,
    this.provider,
    this.quote,
    this.intent,
    required this.onFeedback,
    required this.onDone,
  });

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          // Animated check circle
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.4),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 68),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                Text(
                  'Booking Ho Gayi!',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mubarak ho! Aapki service confirm ho gayi',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (widget.booking?.bookingId.isNotEmpty ?? false)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.confirmation_number_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'ID: ${widget.booking!.bookingId}',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Summary card
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined,
                                color: AppConstants.primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Booking Summary',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        if (widget.provider != null) ...[
                          _SummaryRow(
                              icon: Icons.person_outline,
                              label: 'Provider',
                              value: widget.provider!.name),
                          _SummaryRow(
                              icon: Icons.build_outlined,
                              label: 'Service',
                              value: widget.provider!.service),
                          _SummaryRow(
                              icon: Icons.location_on_outlined,
                              label: 'Area',
                              value: widget.provider!.area),
                        ],
                        if (widget.intent?.preferredTime?.isNotEmpty ?? false)
                          _SummaryRow(
                              icon: Icons.access_time_outlined,
                              label: 'Time',
                              value: widget.intent!.preferredTime!),
                        if (widget.quote != null &&
                            widget.quote!.total > 0)
                          _SummaryRow(
                              icon: Icons.currency_rupee,
                              label: 'Total',
                              value:
                                  'PKR ${widget.quote!.total.toStringAsFixed(0)}',
                              highlight: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Estimated arrival
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryGreen
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppConstants.primaryGreen
                            .withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          color: AppConstants.primaryGreen, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Arrival',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500]),
                            ),
                            Text(
                              'Kal subah 10:00 AM tak pahunch jayenge',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Share button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Booking details share ki gayi!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text('Share Booking',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                          color: AppConstants.primaryGreen
                              .withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      foregroundColor: AppConstants.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Rating button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onFeedback,
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: Text('Rating Dein',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppConstants.gold,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Done button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.onDone,
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                          color: AppConstants.primaryGreen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Home Par Jayen',
                      style: GoogleFonts.poppins(
                          color: AppConstants.primaryGreen,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[500])),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _PriceRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[600])),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[500])),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? AppConstants.primaryGreen
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
