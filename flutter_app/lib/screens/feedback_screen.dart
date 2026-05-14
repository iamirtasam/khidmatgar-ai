import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String bookingId;
  final String providerName;

  const FeedbackScreen({
    super.key,
    required this.bookingId,
    required this.providerName,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  static const _uuid = Uuid();
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final Set<String> _selectedIssues = {};
  bool _isLoading = false;
  bool _submitted = false;
  bool _isDispute = false;
  String? _complaintId;
  String? _error;

  late AnimationController _thankCtrl;
  late Animation<double> _thankScale;
  late Animation<double> _thankFade;
  late AnimationController _resolutionCtrl;
  late Animation<Color?> _resolutionColor;

  @override
  void initState() {
    super.initState();
    _thankCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _thankScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _thankCtrl, curve: Curves.elasticOut));
    _thankFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _thankCtrl, curve: Curves.easeIn));
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
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _detailsCtrl.dispose();
    _thankCtrl.dispose();
    _resolutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Kripya rating dein (1-5 sitare)');
      return;
    }
    if (_rating <= 2 && _selectedIssues.isEmpty) {
      setState(() => _error = 'Kripya masla select karein');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final comment = _rating <= 2
          ? 'Dispute: ${_selectedIssues.join(', ')}. ${_detailsCtrl.text.trim()}'
          : _commentCtrl.text.trim();
      await ApiService.submitFeedback(
        bookingId: widget.bookingId,
        rating: _rating,
        comment: comment,
      );
      if (!mounted) return;
      final isDispute = _rating <= 2;
      setState(() {
        _isLoading = false;
        _submitted = true;
        _isDispute = isDispute;
        if (isDispute) {
          _complaintId = _uuid.v4().substring(0, 8).toUpperCase();
        }
      });
      if (isDispute) {
        _resolutionCtrl.forward();
      } else {
        _thankCtrl.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Bohot Bura 😞';
      case 2:
        return 'Kuch Theek 😐';
      case 3:
        return 'Theek Hai 🙂';
      case 4:
        return 'Acha Hai 😊';
      case 5:
        return 'Zabardast! 🌟';
      default:
        return 'Rating dein';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        title: Text(
          _submitted ? 'Shukriya!' : 'Apna Tajurba Batayein',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _submitted
            ? (_isDispute
                ? _DisputeResolutionView(
                    colorAnim: _resolutionColor,
                    complaintId: _complaintId ?? '',
                    selectedIssues: _selectedIssues,
                    onDone: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  )
                : _ThankYouView(
                    scale: _thankScale,
                    fade: _thankFade,
                    rating: _rating,
                    onDone: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ))
            : _FeedbackForm(
                providerName: widget.providerName,
                rating: _rating,
                ratingLabel: _ratingLabel,
                commentCtrl: _commentCtrl,
                detailsCtrl: _detailsCtrl,
                selectedIssues: _selectedIssues,
                onIssueToggle: (issue) => setState(() {
                  if (_selectedIssues.contains(issue)) {
                    _selectedIssues.remove(issue);
                  } else {
                    _selectedIssues.add(issue);
                  }
                }),
                isLoading: _isLoading,
                error: _error,
                onRatingUpdate: (r) => setState(() {
                  _rating = r.round();
                  _error = null;
                }),
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// ── Feedback form ─────────────────────────────────────────────────────────────

class _FeedbackForm extends StatelessWidget {
  final String providerName;
  final int rating;
  final String ratingLabel;
  final TextEditingController commentCtrl;
  final TextEditingController detailsCtrl;
  final Set<String> selectedIssues;
  final ValueChanged<String> onIssueToggle;
  final bool isLoading;
  final String? error;
  final ValueChanged<double> onRatingUpdate;
  final VoidCallback onSubmit;

  const _FeedbackForm({
    required this.providerName,
    required this.rating,
    required this.ratingLabel,
    required this.commentCtrl,
    required this.detailsCtrl,
    required this.selectedIssues,
    required this.onIssueToggle,
    required this.isLoading,
    this.error,
    required this.onRatingUpdate,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.thumb_up_alt_outlined,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Service kaisi rahi?',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  if (providerName.isNotEmpty)
                    Text(
                      providerName,
                      style: GoogleFonts.poppins(
                          color: Colors.grey[600], fontSize: 14),
                    ),
                  const SizedBox(height: 22),

                  // Star rating
                  RatingBar.builder(
                    initialRating: rating.toDouble(),
                    minRating: 1,
                    maxRating: 5,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 48,
                    unratedColor: Colors.grey[200],
                    itemBuilder: (_, _) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD700),
                    ),
                    onRatingUpdate: onRatingUpdate,
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      ratingLabel,
                      key: ValueKey(rating),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: rating >= 4
                            ? AppConstants.primaryGreen
                            : rating >= 3
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (rating <= 2 && rating > 0) ...[AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.report_problem_outlined,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text('Kya hua? (What went wrong?)',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.red[700])),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Provider late tha',
                    'Kaam theek nahi tha',
                    'Price zyada tha',
                    'Provider nahi aya',
                  ].map((issue) {
                    final sel = selectedIssues.contains(issue);
                    return GestureDetector(
                      onTap: () => onIssueToggle(issue),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? Colors.red[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? Colors.red[700]!
                                  : Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Text(issue,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    sel ? Colors.white : Colors.red[700])),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Aur details batayein (optional)...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ), const SizedBox(height: 16)],

          // Comment field
          TextField(
            controller: commentCtrl,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Apna tajurba share karein... (Urdu ya English mein)',
              hintStyle:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: AppConstants.primaryGreen, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error!,
                        style: GoogleFonts.poppins(
                            color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    rating <= 2 ? Colors.red[700] : AppConstants.primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            rating <= 2
                                ? Icons.report_rounded
                                : Icons.send_rounded,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                            rating <= 2
                                ? 'Submit Complaint'
                                : 'Rating Submit Karein',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thank you view ────────────────────────────────────────────────────────────

class _ThankYouView extends StatelessWidget {
  final Animation<double> scale;
  final Animation<double> fade;
  final int rating;
  final VoidCallback onDone;

  const _ThankYouView({
    required this.scale,
    required this.fade,
    required this.rating,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeTransition(
          opacity: fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: scale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 28),
              Text('Shukriya! جزاک اللہ',
                  style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Aapki rating ${List.generate(rating, (_) => '⭐').join()} de di gayi.',
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Aapka feedback hamare providers ko behtar banata hai.',
                style: GoogleFonts.poppins(
                    color: Colors.grey[500], fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppConstants.primaryGreen,
                  ),
                  child: Text('Home Par Jayen',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dispute resolution view ───────────────────────────────────────────────────

class _DisputeResolutionView extends StatelessWidget {
  final Animation<Color?> colorAnim;
  final String complaintId;
  final Set<String> selectedIssues;
  final VoidCallback onDone;

  const _DisputeResolutionView({
    required this.colorAnim,
    required this.complaintId,
    required this.selectedIssues,
    required this.onDone,
  });

  String get _resolutionText {
    if (selectedIssues.contains('Provider nahi aya')) {
      return 'Aapko full refund milega. Provider ko blacklist kiya ja raha hai.';
    } else if (selectedIssues.contains('Provider late tha')) {
      return 'Aapko 10% discount diya jayega agli booking par.';
    } else if (selectedIssues.contains('Kaam theek nahi tha')) {
      return 'Ek free re-service schedule ki ja rahi hai.';
    } else {
      return 'Price review kiya ja raha hai. 24 ghante mein response milega.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: colorAnim,
        builder: (_, _) {
          final col = colorAnim.value ?? Colors.red[700]!;
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
                    const SizedBox(height: 16),
                    Text('Complaint Darj Ho Gayi',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
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
                      child: Text('ID: $complaintId',
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
                        'Complaint ID: $complaintId — Status: Processing'),
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
                child: ElevatedButton(
                  onPressed: onDone,
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
