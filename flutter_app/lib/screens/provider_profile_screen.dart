import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/agent_response.dart';
import '../models/provider_model.dart';

class ProviderProfileScreen extends StatefulWidget {
  final dynamic provider;
  final bool isRecommended;

  const ProviderProfileScreen({
    super.key,
    required this.provider,
    this.isRecommended = false,
  });

  @override
  State<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  int? _selectedSlot;

  // ── Field getters ──────────────────────────────────────────────────────────

  String get _name {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).name;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).name;
    }
    return '';
  }

  String get _initials {
    if (_name.isEmpty) return '?';
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name[0].toUpperCase();
  }

  String get _service {
    if (widget.provider is TopProvider) {
      final tp = widget.provider as TopProvider;
      return tp.specialization.isNotEmpty ? tp.specialization : tp.name;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).service;
    }
    return '';
  }

  String get _specialization {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).specialization;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).specialization;
    }
    return '';
  }

  double get _rating {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).rating;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).rating;
    }
    return 0.0;
  }

  int get _pricePerHour {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).pricePerHour;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).pricePerHour.toInt();
    }
    return 0;
  }

  int get _onTimeScore {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).onTimeScore;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).onTimeScore.toInt();
    }
    return 0;
  }

  String get _area {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).area;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).area;
    }
    return '';
  }

  String get _phone {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).phone;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).phone;
    }
    return '';
  }

  bool get _available {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).available;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).available;
    }
    return false;
  }

  String get _providerId {
    if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).providerId;
    }
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).id;
    }
    return '';
  }

  // ── Derived values ─────────────────────────────────────────────────────────

  int get _nameHash {
    int h = 0;
    for (final c in _name.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }

  Color get _avatarColor {
    const colors = [
      Color(0xFF1B5E20),
      Color(0xFF0277BD),
      Color(0xFF6A1B9A),
      Color(0xFFE65100),
      Color(0xFF00695C),
      Color(0xFFC62828),
    ];
    return colors[_nameHash % colors.length];
  }

  int get _jobsDone => 50 + (_nameHash % 150);

  int get _experience {
    int h = 0;
    for (final c in _providerId.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return 2 + (h % 9);
  }

  String get _toolsForService {
    final s = _specialization.toLowerCase();
    if (s.contains('ac') || s.contains('air')) {
      return 'Inverter tools, Gas charging kit, Multi-meter';
    } else if (s.contains('plumb')) {
      return 'Pipe wrench, Plunger, Thread sealant tape';
    } else if (s.contains('elect')) {
      return 'Multi-meter, Wire stripper, Soldering iron';
    } else if (s.contains('paint')) {
      return 'Spray gun, Roller brushes, Paint mixer';
    } else if (s.contains('clean')) {
      return 'Industrial vacuum, Steam cleaner, Chemicals';
    } else {
      return 'Professional toolkit, Safety equipment';
    }
  }

  // ── Static review data ─────────────────────────────────────────────────────

  static const _reviewerNames = [
    'Ahmed K.',
    'Sara M.',
    'Bilal R.',
    'Fatima N.',
    'Usman A.',
  ];

  static const _reviewTexts = [
    'Bohot acha kaam kiya! Time par aya aur masla foran theek kar diya. Highly recommended!',
    'Bahut professional hai, kaam clean raha. Zaroor dobara bulaon ga inhe.',
    'Zyada waqt nahi liya, efficient kaam kiya. Mashallah, bahut behtareen service.',
    'Reasonable price aur quality kaam. Poori family ne appreciate kiya.',
    'Umeed se zyada acha result mila. Shukriya, 5 stars definitely deserves.',
  ];

  List<Map<String, dynamic>> get _reviews {
    int h = _nameHash;
    return List.generate(3, (i) {
      h = ((h * 1664525 + 1013904223) & 0x7FFFFFFF);
      final nameIdx = h % _reviewerNames.length;
      h = ((h * 1664525 + 1013904223) & 0x7FFFFFFF);
      final textIdx = (h + i) % _reviewTexts.length;
      h = ((h * 1664525 + 1013904223) & 0x7FFFFFFF);
      final days = 1 + (h % 30);
      final stars = _rating >= 4.0 ? (4 + (h % 2)) : (3 + (h % 2));
      return {
        'name': _reviewerNames[nameIdx],
        'text': _reviewTexts[textIdx],
        'days': days,
        'stars': stars,
      };
    });
  }

  static const _timeSlots = [
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '2:00 PM',
    '4:00 PM',
  ];

  List<bool> get _slotAvailability {
    int h = _nameHash;
    return List.generate(6, (i) {
      h = ((h * 1664525 + 1013904223) & 0x7FFFFFFF);
      return h % 3 != 0;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppConstants.primaryGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile link copied!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroBackground(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const Divider(height: 1),
                  _buildAboutSection(),
                  const Divider(height: 1),
                  _buildReviewsSection(),
                  const Divider(height: 1),
                  _buildAvailabilitySection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── Hero header ────────────────────────────────────────────────────────────

  Widget _buildHeroBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 44),
            Hero(
              tag: 'provider-avatar-$_name',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Chip(_service, Colors.white.withValues(alpha: 0.22)),
                if (widget.isRecommended) ...[
                  const SizedBox(width: 8),
                  _Chip(
                    '★ Best Match',
                    AppConstants.gold,
                    textColor: Colors.black87,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < _rating.floor()
                        ? Icons.star_rounded
                        : (i < _rating
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded),
                    size: 18,
                    color: AppConstants.gold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_area.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFFB9F6CA)),
                  const SizedBox(width: 3),
                  Text(
                    _area,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFB9F6CA),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(
            label: 'On-Time',
            value: '$_onTimeScore%',
            icon: Icons.timer_outlined,
            color: Colors.teal,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Rating',
            value: '${_rating.toStringAsFixed(1)}/5',
            icon: Icons.star_rounded,
            color: Colors.amber[700]!,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Jobs Done',
            value: '$_jobsDone+',
            icon: Icons.check_circle_outline_rounded,
            color: AppConstants.primaryGreen,
          ),
        ],
      ),
    );
  }

  // ── About ──────────────────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_specialization.isNotEmpty)
            _InfoRow(
                Icons.build_circle_outlined, 'Specialization', _specialization),
          _InfoRow(Icons.work_history_outlined, 'Experience',
              '$_experience years in service'),
          _InfoRow(Icons.language_outlined, 'Languages', 'Urdu, English'),
          _InfoRow(Icons.construction_outlined, 'Tools & Equipment',
              _toolsForService),
          if (_pricePerHour > 0)
            _InfoRow(Icons.payments_outlined, 'Rate',
                'PKR $_pricePerHour per hour'),
          _InfoRow(
            _available
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            'Availability',
            _available ? 'Available Now' : 'Currently Busy',
            valueColor:
                _available ? AppConstants.primaryGreen : Colors.red,
          ),
        ],
      ),
    );
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    return _buildSection(
      'Customer Reviews',
      Column(
        children: _reviews.map((r) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryGreen
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          r['name'].toString()[0],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryGreen,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(r['name'].toString(),
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded,
                                        size: 10,
                                        color: Colors.green[700]),
                                    const SizedBox(width: 2),
                                    Text('Verified',
                                        style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color: Colors.green[700])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ...List.generate(
                                  r['stars'] as int,
                                  (_) => const Icon(Icons.star_rounded,
                                      size: 12, color: Colors.amber)),
                              ...List.generate(
                                  5 - (r['stars'] as int),
                                  (_) => const Icon(
                                      Icons.star_outline_rounded,
                                      size: 12,
                                      color: Colors.amber)),
                              const SizedBox(width: 6),
                              Text('${r['days']} days ago',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r['text'].toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.5),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Availability ───────────────────────────────────────────────────────────

  Widget _buildAvailabilitySection() {
    final availability = _slotAvailability;
    return _buildSection(
      'Available Time Slots',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tomorrow',
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_timeSlots.length, (i) {
              final isAvail = availability[i];
              final isSelected = _selectedSlot == i;
              return GestureDetector(
                onTap: isAvail
                    ? () {
                        setState(() => _selectedSlot = i);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Slot selected: ${_timeSlots[i]}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppConstants.primaryGreen,
                          ),
                        );
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryGreen
                        : isAvail
                            ? const Color(0xFFE8F5E9)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryGreen
                          : isAvail
                              ? AppConstants.primaryGreen
                                  .withValues(alpha: 0.4)
                              : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    _timeSlots[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isAvail
                              ? AppConstants.primaryGreen
                              : Colors.grey[400],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text('Book Now',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_phone.isNotEmpty
                      ? 'Calling $_phone...'
                      : 'Phone number not available'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.call_rounded,
                size: 18, color: AppConstants.primaryGreen),
            label: Text('Call',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryGreen)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: AppConstants.primaryGreen, width: 1.5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ────────────────────────────────────────────────────────

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color? textColor;
  const _Chip(this.label, this.bgColor, {this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: valueColor ?? Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 1),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: valueColor ?? Colors.black87,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
