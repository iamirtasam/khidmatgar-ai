import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _counterCtrl;
  late Animation<double> _bookingsAnim;
  late Animation<double> _providersAnim;
  late AnimationController _dotCtrl;
  late AnimationController _activityCtrl;
  final List<Animation<Offset>> _activitySlides = [];
  final List<Animation<double>> _activityFades = [];
  bool _stressLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _counterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _bookingsAnim = Tween<double>(begin: 0, end: 47)
        .animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _providersAnim = Tween<double>(begin: 0, end: 23)
        .animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));

    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _activityCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    for (int i = 0; i < 4; i++) {
      final start = i * 0.18;
      final end = (start + 0.45).clamp(0.0, 1.0);
      _activitySlides.add(Tween<Offset>(
              begin: const Offset(0.25, 0), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _activityCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic))));
      _activityFades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _activityCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
    }

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        _counterCtrl.forward();
        _activityCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animCtrl.dispose();
    _counterCtrl.dispose();
    _dotCtrl.dispose();
    _activityCtrl.dispose();
    super.dispose();
  }

  void _startChat() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ChatProvider>()
      ..setUserName(_nameController.text)
      ..startNewSession();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, _) => const ChatScreen(),
      transitionsBuilder: (_, a, _, child) => SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 380),
    ));
  }

  void _showStressDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.science_outlined, color: Colors.orange),
            const SizedBox(width: 8),
            Text('AI Stress Tests',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Demo robustness scenarios for evaluation',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _StressBtn(
              icon: Icons.block_outlined,
              label: 'No Provider Available',
              sub: 'All providers temporarily offline',
              color: Colors.orange[700]!,
              onTap: () {
                Navigator.pop(ctx);
                _runStress('no-provider');
              },
            ),
            const SizedBox(height: 8),
            _StressBtn(
              icon: Icons.refresh,
              label: 'Provider Cancellation',
              sub: 'Auto-reassignment flow',
              color: Colors.red[700]!,
              onTap: () {
                Navigator.pop(ctx);
                _runStress('cancellation');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _runStress(String type) async {
    setState(() => _stressLoading = true);
    try {
      final result = type == 'no-provider'
          ? await ApiService.stressTestNoProvider()
          : await ApiService.stressTestCancellation();
      if (!mounted) return;
      _showStressResult(type, result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _stressLoading = false);
    }
  }

  void _showStressResult(String type, Map<String, dynamic> result) {
    final agent = (result['agent'] ?? result['reassigned'] ?? {})
        as Map<String, dynamic>;
    final action = (agent['booking_action'] ?? result['booking_action'] ?? 'N/A')
        .toString();
    final reassigned = result['reassigned'] as Map<String, dynamic>?;
    final newProvider =
        (reassigned?['recommended_provider'] as Map?)?['name'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stress Test: $type',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text('Agent Response:',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 4),
              Text(action, style: GoogleFonts.poppins(fontSize: 13)),
              if (type == 'cancellation') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reassigned to: $newProvider',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text('خ',
                                  style: TextStyle(
                                      fontSize: 34,
                                      color: Color(0xFF1B5E20),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                AppConstants.appNameUrdu,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppConstants.tagline,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // White card
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F8E9),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(26),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khush Aamdeed! 🇵🇰',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.primaryGreen,
                              ),
                            ),
                            Text(
                              'Find trusted home service experts near you',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 20),

                            // Service chips
                            const Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _ServiceChip(icon: Icons.plumbing, label: 'Plumber'),
                                _ServiceChip(icon: Icons.electric_bolt, label: 'Electrician'),
                                _ServiceChip(icon: Icons.ac_unit, label: 'AC Tech'),
                                _ServiceChip(icon: Icons.carpenter, label: 'Carpenter'),
                                _ServiceChip(icon: Icons.format_paint, label: 'Painter'),
                                _ServiceChip(icon: Icons.gas_meter, label: 'Gas Fitter'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const _PakistaniSkylineBanner(),
                            const SizedBox(height: 24),

                            // Name input
                            Text(
                              'Apna naam darj karein',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppConstants.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: GoogleFonts.poppins(fontSize: 15),
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'e.g. Ahmed Ali',
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: AppConstants.primaryGreen),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Naam zaroori hai'
                                      : null,
                            ),
                            const SizedBox(height: 22),

                            // Start button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _startChat,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Text('Shuru Karein   شروع کریں',
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Text(
                                'Urdu, Roman Urdu, ya English mein baat karein',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[500], fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Features row
                            Row(
                              children: [
                                _FeatureTile(
                                  icon: Icons.smart_toy_outlined,
                                  label: 'Gemini AI',
                                ),
                                const SizedBox(width: 8),
                                _FeatureTile(
                                  icon: Icons.verified_user_outlined,
                                  label: 'Verified',
                                ),
                                const SizedBox(width: 8),
                                _FeatureTile(
                                  icon: Icons.speed_outlined,
                                  label: 'Fast Book',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildStatsDashboard(),
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
      floatingActionButton: _stressLoading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.orange[700],
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _showStressDialog,
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.science_outlined, size: 20),
              label: Text('Stress Test',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
    );
  }

  static const _activityData = [
    ('🔧', 'Ahmed ne plumber book kiya - G-11', '2 min ago', Color(0xFF1B5E20)),
    ('❄️', 'Sara ki AC service complete', '15 min ago', Color(0xFF0277BD)),
    ('⚡', 'Bilal ne electrician request kiya - F-8', '32 min ago', Color(0xFFF57F17)),
    ('✅', 'Usman ki booking confirmed - G-13', '1 hour ago', Color(0xFF6A1B9A)),
  ];

  static const _trending = [
    ('🔥 AC Repair', '24 today'),
    ('⚡ Electrician', '18 today'),
    ('🔧 Plumber', '31 today'),
    ('🎨 Painter', '12 today'),
  ];

  Widget _buildStatsDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Aaj Ki Activity',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryGreen)),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _dotCtrl,
              builder: (_, _) => Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Color.lerp(AppConstants.primaryGreen,
                      const Color(0xFFA5D6A7), _dotCtrl.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryGreen
                          .withValues(alpha: 0.5 * _dotCtrl.value),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _AnimCounterCard(
              animation: _bookingsAnim,
              label: 'Bookings Today',
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF0277BD),
            ),
            const SizedBox(width: 8),
            _AnimCounterCard(
              animation: _providersAnim,
              label: 'Active Providers',
              icon: Icons.people_alt_rounded,
              color: AppConstants.primaryGreen,
            ),
            const SizedBox(width: 8),
            _ShimmerCountCard(
              label: 'Avg Response',
              value: '2.3 min',
              icon: Icons.timer_outlined,
              color: Colors.orange[700]!,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Recent Activity',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800])),
        const SizedBox(height: 10),
        ...List.generate(_activityData.length, (i) {
          final item = _activityData[i];
          return ClipRect(
            child: SlideTransition(
            position: _activitySlides[i],
            child: FadeTransition(
              opacity: _activityFades[i],
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item.$4.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(item.$1,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$2,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                            Text(item.$3,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (i < _activityData.length - 1)
                    Divider(
                        height: 16,
                        color: Colors.grey.withValues(alpha: 0.15)),
                ],
              ),
            ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Text('Trending Services',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800])),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _trending.map((t) {
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.$1,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryGreen)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryGreen
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t.$2,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryGreen)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AnimCounterCard extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final IconData icon;
  final Color color;
  const _AnimCounterCard(
      {required this.animation,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.06)],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            AnimatedBuilder(
              animation: animation,
              builder: (_, _) => Text(
                '${animation.value.round()}',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCountCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ShimmerCountCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.06)],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Shimmer.fromColors(
              baseColor: color,
              highlightColor: color.withValues(alpha: 0.4),
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppConstants.primaryGreen, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _StressBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _StressBtn(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: color)),
                  Text(sub,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ServiceChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14, color: AppConstants.primaryGreen),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppConstants.primaryGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
          color: AppConstants.primaryGreen.withValues(alpha: 0.35)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _PakistaniSkylineBanner extends StatelessWidget {
  const _PakistaniSkylineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _SkylinePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pakistan ke har sheher mein',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
              Text(
                'Trusted Experts',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFD700),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF081C0A),
          Color(0xFF1B5E20),
          Color(0xFF0C2B0E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    const buildingData = [
      [0.00, 0.08, 0.55], [0.09, 0.06, 0.38], [0.16, 0.10, 0.72],
      [0.27, 0.05, 0.42], [0.33, 0.12, 0.82], [0.46, 0.07, 0.52],
      [0.54, 0.09, 0.65], [0.64, 0.06, 0.44], [0.71, 0.10, 0.78],
      [0.82, 0.07, 0.55], [0.90, 0.10, 0.48],
    ];

    final bPaint1 = Paint()..color = const Color(0xFF061208);
    final bPaint2 = Paint()..color = const Color(0xFF0A1F0C);
    final winPaint = Paint()..color = const Color(0xB3FFD700);
    canvas.drawRect(Rect.fromLTWH(0, h - 10, w, 10),
        Paint()..color = const Color(0xFF040E05));

    for (int i = 0; i < buildingData.length; i++) {
      final bx = buildingData[i][0] * w;
      final bw = buildingData[i][1] * w;
      final bh = buildingData[i][2] * h;
      canvas.drawRect(Rect.fromLTWH(bx, h - bh - 10, bw, bh),
          i.isEven ? bPaint1 : bPaint2);
      final winRows = (bh / 18).floor().clamp(1, 4);
      for (int row = 0; row < winRows; row++) {
        if ((row + i) % 3 == 0) continue;
        final wy = h - bh - 10 + bh * 0.18 + row * 17.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(bx + bw * 0.18, wy, bw * 0.28, 8),
              const Radius.circular(1)),
          winPaint,
        );
        if (bw > w * 0.07) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(bx + bw * 0.56, wy, bw * 0.26, 8),
                const Radius.circular(1)),
            winPaint,
          );
        }
      }
    }

    final moonPaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(Offset(w * 0.78, h * 0.26), 13, moonPaint);
    canvas.drawCircle(Offset(w * 0.78 + 9, h * 0.26 - 4), 11,
        Paint()..color = const Color(0xFF0E2610));
    _drawStar(canvas, Offset(w * 0.91, h * 0.16), 6,
        Paint()..color = const Color(0xFFFFF9C4));
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.42;
      final a = (i * math.pi / 5) - math.pi / 2;
      final x = c.dx + rad * math.cos(a);
      final y = c.dy + rad * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
