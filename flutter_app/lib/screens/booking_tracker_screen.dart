import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/booking.dart';
import '../models/provider_model.dart';
import '../models/agent_response.dart';
import 'feedback_screen.dart';
import 'dispute_screen.dart';

class BookingTrackerScreen extends StatefulWidget {
  final Booking? booking;
  final ProviderModel? provider;
  final ExtractedIntent? intent;

  const BookingTrackerScreen({
    super.key,
    this.booking,
    this.provider,
    this.intent,
  });

  @override
  State<BookingTrackerScreen> createState() => _BookingTrackerScreenState();
}

class _BookingTrackerScreenState extends State<BookingTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientCtrl;
  late Animation<Color?> _gradientColor;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final List<AnimationController> _stageCtrls = [];
  final List<Animation<double>> _stageFades = [];
  int _completedStages = 1;

  static const _stageData = [
    _StageInfo('Booking Confirmed', 'Your booking has been confirmed', Icons.check_circle_rounded, 0),
    _StageInfo('Provider Notified', '{{name}} has been notified', Icons.notifications_active_rounded, 2),
    _StageInfo('Provider Accepted', '{{name}} accepted your request', Icons.handshake_rounded, 4),
    _StageInfo('En Route', '{{name}} is on the way to you', Icons.directions_car_rounded, 6),
    _StageInfo('Arrived', '{{name}} has arrived at your location', Icons.home_rounded, 8),
  ];

  @override
  void initState() {
    super.initState();

    _gradientCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _gradientColor = ColorTween(
      begin: const Color(0xFF1B5E20),
      end: const Color(0xFF2E7D32),
    ).animate(_gradientCtrl);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    for (int i = 0; i < _stageData.length; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      _stageCtrls.add(ctrl);
      _stageFades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack)));
    }
    _stageCtrls[0].forward();
    _startTimeline();
  }

  Future<void> _startTimeline() async {
    for (int i = 1; i < _stageData.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _completedStages = i + 1);
      _stageCtrls[i].forward();
    }
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _pulseCtrl.dispose();
    for (final c in _stageCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final name = p?.name ?? widget.booking?.providerName ?? 'Provider';
    final allComplete = _completedStages >= _stageData.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Tracking',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _gradientColor,
        builder: (_, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _gradientColor.value ?? AppConstants.primaryGreen,
                const Color(0xFF388E3C),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildProviderCard(p, name),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildArrivalBanner(),
                            const SizedBox(height: 20),
                            _buildTimeline(name),
                            const SizedBox(height: 24),
                            _buildActionButtons(context, p, name, allComplete),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel? p, String name) {
    final avatarColors = [
      const Color(0xFF1B5E20), const Color(0xFF0277BD),
      const Color(0xFF6A1B9A), const Color(0xFFE65100),
    ];
    final avatarColor = avatarColors[name.length % avatarColors.length];
    final initials = () {
      if (p != null) return p.initials;
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return name.isNotEmpty ? name[0].toUpperCase() : '?';
    }();
    final service = p?.service ?? widget.booking?.service ?? '';
    final bookingId = widget.booking?.bookingId ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8)
              ],
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (service.isNotEmpty)
                  Text(service,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85))),
                if (bookingId.isNotEmpty)
                  Text('ID: $bookingId',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Active',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded,
                color: Colors.amber, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimated Arrival',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[500])),
              Text('Tomorrow 10:00 AM',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber[800])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String providerName) {
    return Column(
      children: List.generate(_stageData.length, (i) {
        final isComplete = i < _completedStages;
        final isActive = i == _completedStages - 1;
        final isPending = i >= _completedStages;
        final subtitle = _stageData[i].subtitle.replaceAll('{{name}}', providerName);
        final isLast = i == _stageData.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, _) => Transform.scale(
                        scale: isActive && !isComplete ? _pulseAnim.value : 1.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isComplete
                                ? AppConstants.primaryGreen
                                : isPending
                                    ? Colors.grey[200]
                                    : AppConstants.primaryGreen,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppConstants.primaryGreen
                                          .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            isComplete
                                ? Icons.check_rounded
                                : _stageData[i].icon,
                            size: 18,
                            color: isComplete
                                ? Colors.white
                                : isPending
                                    ? Colors.grey[400]
                                    : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 3,
                          color: isComplete
                              ? AppConstants.primaryGreen
                              : Colors.grey[200],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: isLast ? 0 : 16, top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _stageData[i].title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isComplete
                                  ? AppConstants.primaryGreen
                                  : isPending
                                      ? Colors.grey[400]
                                      : Colors.black87,
                            ),
                          ),
                          if (isComplete)
                            const SizedBox(width: 6),
                          if (isComplete)
                            FadeTransition(
                              opacity: _stageFades[i],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryGreen
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Done',
                                    style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppConstants.primaryGreen)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isPending
                              ? Colors.grey[350]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ProviderModel? p, String name, bool allComplete) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final phone = p?.phone ?? '';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(phone.isNotEmpty
                          ? 'Calling $phone...'
                          : 'Phone number not available'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.call_rounded, size: 16),
                label: Text('Call Provider',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking details shared!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 16),
                label: Text('Share',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryGreen,
                  side: const BorderSide(color: AppConstants.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DisputeScreen(
                bookingId: widget.booking?.bookingId ?? '',
                providerName: name,
              ),
            )),
            icon: const Icon(Icons.report_problem_outlined,
                size: 16, color: Colors.red),
            label: Text('Dispute / Problem',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700])),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red[700]!),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: allComplete
                ? () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FeedbackScreen(
                        bookingId: widget.booking?.bookingId ?? '',
                        providerName: name,
                      ),
                    ));
                  }
                : null,
            icon: const Icon(Icons.star_rounded, size: 16),
            label: Text(
              allComplete
                  ? 'Rate Service'
                  : 'Rate Service (after arrival)',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.gold,
              foregroundColor: Colors.black87,
              disabledBackgroundColor: Colors.grey[200],
              disabledForegroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final int delaySeconds;
  const _StageInfo(this.title, this.subtitle, this.icon, this.delaySeconds);
}
