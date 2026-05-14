import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class DisputeScreen extends StatefulWidget {
  final String bookingId;
  final String providerName;

  const DisputeScreen({
    super.key,
    this.bookingId = '',
    this.providerName = '',
  });

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen>
    with TickerProviderStateMixin {
  static const _uuid = Uuid();
  static const _issues = [
    'Provider late tha',
    'Kaam theek nahi tha',
    'Price zyada tha',
    'Provider nahi aya',
  ];

  final Set<String> _selected = {};
  final _detailsCtrl = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;
  String? _complaintId;

  late AnimationController _resolutionCtrl;
  late Animation<Color?> _resolutionColor;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _resolutionCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _resolutionColor = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(begin: Colors.red[700], end: Colors.orange[700]),
          weight: 50),
      TweenSequenceItem(
          tween: ColorTween(begin: Colors.orange[700], end: Colors.green[700]),
          weight: 50),
    ]).animate(_resolutionCtrl);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    _resolutionCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  String get _resolutionText {
    if (_selected.contains('Provider nahi aya')) {
      return 'Aapko full refund milega. Provider ko blacklist kiya ja raha hai.';
    } else if (_selected.contains('Provider late tha')) {
      return 'Aapko 10% discount diya jayega agli booking par.';
    } else if (_selected.contains('Kaam theek nahi tha')) {
      return 'Ek free re-service schedule ki ja rahi hai.';
    } else {
      return 'Price review kiya ja raha hai. 24 ghante mein response milega.';
    }
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kripya masla select karein'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _submitted = true;
      _complaintId = _uuid.v4().substring(0, 8).toUpperCase();
    });
    _resolutionCtrl.forward();
  }

  void _showHumanSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headset_mic_rounded,
                      color: AppConstants.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Human Support',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                        child: Text('K',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6)
                        ],
                      ),
                      child: Text(
                        'Aapki complaint receive ho gayi hai. Agent 5 minuteon mein aapko contact karega.',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[800],
                            height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('OK, Shukriya',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        title: Text('Dispute & Support',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: _submitted ? _buildResolution() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.providerName.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.providerName,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700])),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text('Masla kya tha?',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Multiple select kar sakte hain',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _issues.map((issue) {
              final sel = _selected.contains(issue);
              return GestureDetector(
                onTap: () => setState(() => sel
                    ? _selected.remove(issue)
                    : _selected.add(issue)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? Colors.red[700] : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: sel
                            ? Colors.red[700]!
                            : Colors.red.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4)
                    ],
                  ),
                  child: Text(issue,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.red[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Additional Details',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsCtrl,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Jo hua woh detail mein batayein...',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.red.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.red, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.report_rounded, size: 18),
              label: Text('Submit Complaint',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showHumanSupport,
              icon: const Icon(Icons.headset_mic_outlined, size: 18),
              label: Text('Human Support Se Baat Karein',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryGreen,
                side: const BorderSide(
                    color: AppConstants.primaryGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolution() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _resolutionColor,
        builder: (_, _) {
          final col = _resolutionColor.value ?? Colors.red[700]!;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: col, width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: col, shape: BoxShape.circle),
                      child: const Icon(Icons.support_agent_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text('Complaint Darj Ho Gayi',
                        style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('ID: ${_complaintId ?? ''}',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                              letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_fix_high_rounded,
                              color: col, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_resolutionText,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                    height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Complaint ID: ${_complaintId ?? ''} — Processing'),
                    behavior: SnackBarBehavior.floating,
                  )),
                  icon: const Icon(Icons.track_changes_rounded, size: 16),
                  label: Text('Track Complaint',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showHumanSupport,
                  icon: const Icon(Icons.headset_mic_outlined, size: 16),
                  label: Text('Human Support Se Baat Karein',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryGreen,
                    side: const BorderSide(color: AppConstants.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Home Par Jayen',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
