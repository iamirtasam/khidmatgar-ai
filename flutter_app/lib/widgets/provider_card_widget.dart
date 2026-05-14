import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/provider_model.dart';
import '../models/agent_response.dart';
import '../constants/app_constants.dart';

class ProviderCardWidget extends StatefulWidget {
  final dynamic provider;
  final bool isRecommended;
  final bool isExpanded;

  const ProviderCardWidget({
    super.key,
    required this.provider,
    this.isRecommended = false,
    this.isExpanded = false,
  });

  @override
  State<ProviderCardWidget> createState() => _ProviderCardWidgetState();
}

class _ProviderCardWidgetState extends State<ProviderCardWidget> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isExpanded || widget.isRecommended;
  }

  String get _name {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).name;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).name;
    }
    return 'Unknown';
  }

  String get _initials {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).initials;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).initials;
    }
    return '?';
  }

  String get _service {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).service;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).specialization;
    }
    return '';
  }

  String get _area {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).area;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).area;
    }
    return '';
  }

  double get _rating {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).rating;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).rating;
    }
    return 0.0;
  }

  double get _onTimeScore {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).onTimeScore;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).onTimeScore.toDouble();
    }
    return 0.0;
  }

  double get _pricePerHour {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).pricePerHour;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).pricePerHour.toDouble();
    }
    return 0.0;
  }

  double get _cancellationRate {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).cancellationRate;
    } else if (widget.provider is TopProvider) {
      final val = (widget.provider as TopProvider).cancellationRate;
      return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }

  String get _reasoning {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).reasoning;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).reasoning;
    }
    return '';
  }

  double? get _score {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).score;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).score;
    }
    return null;
  }

  bool get _available {
    if (widget.provider is ProviderModel) {
      return (widget.provider as ProviderModel).available;
    } else if (widget.provider is TopProvider) {
      return (widget.provider as TopProvider).available;
    }
    return false;
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF0277BD),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
      const Color(0xFF00695C),
      const Color(0xFFC62828),
    ];
    int hash = 0;
    for (final c in _name.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isRecommended
              ? AppConstants.gold
              : Colors.grey.withValues(alpha: 0.2),
          width: widget.isRecommended ? 2.5 : 1,
        ),
        color: Colors.white,
        boxShadow: widget.isRecommended
            ? [
                BoxShadow(
                  color: AppConstants.gold.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                ),
              ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      _Avatar(initials: _initials, color: _avatarColor),
                      if (_available)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name.isNotEmpty ? _name : 'Unknown Provider',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (widget.isRecommended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppConstants.gold,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 11, color: Colors.black87),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Best Match',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StarRow(rating: _rating),
                            const SizedBox(width: 6),
                            Text(
                              _rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.location_on,
                                size: 12, color: Colors.grey[500]),
                            Expanded(
                              child: Text(
                                _area,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'PKR ${_pricePerHour.toStringAsFixed(0)}/hr',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: 'On-Time',
                        value: '${_onTimeScore.toStringAsFixed(0)}%',
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.cancel_outlined,
                        label: 'Cancel Rate',
                        value: '${_cancellationRate.toStringAsFixed(0)}%',
                        color: _cancellationRate > 0.15
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.build_outlined,
                        label: 'Service',
                        value: _service.isNotEmpty ? _service : '-',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  if (_reasoning.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 12, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _reasoning,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_score != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'AI Score: ',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600]),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_score! / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            color: AppConstants.primaryGreen,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _score!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _Avatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.floor()
              ? Icons.star
              : (i < rating ? Icons.star_half : Icons.star_border),
          size: 12,
          color: AppConstants.goldDark,
        );
      }),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
