import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/agent_response.dart';

class IntentChipsRow extends StatelessWidget {
  final ExtractedIntent intent;

  const IntentChipsRow({super.key, required this.intent});

  @override
  Widget build(BuildContext context) {
    final chips = <_ChipData>[];

    if (intent.serviceType?.isNotEmpty ?? false) {
      chips.add(_ChipData(
        icon: Icons.build_circle_outlined,
        label: intent.serviceType!,
        color: const Color(0xFF1B5E20),
      ));
    }
    if (intent.location?.isNotEmpty ?? false) {
      chips.add(_ChipData(
        icon: Icons.location_on_outlined,
        label: intent.location!,
        color: const Color(0xFF0277BD),
      ));
    }
    if (intent.preferredTime?.isNotEmpty ?? false) {
      chips.add(_ChipData(
        icon: Icons.schedule_outlined,
        label: intent.preferredTime!,
        color: const Color(0xFF6A1B9A),
      ));
    }
    if (intent.urgency?.isNotEmpty ?? false) {
      final isUrgent = intent.urgency!.toLowerCase().contains('urgent');
      chips.add(_ChipData(
        icon: isUrgent ? Icons.flash_on : Icons.hourglass_empty,
        label: intent.urgency!,
        color: isUrgent ? const Color(0xFFD32F2F) : const Color(0xFFE65100),
      ));
    }
    if (intent.budgetSensitivity?.isNotEmpty ?? false) {
      chips.add(_ChipData(
        icon: Icons.attach_money,
        label: 'Budget: ${intent.budgetSensitivity}',
        color: const Color(0xFF2E7D32),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extracted Intent',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips
              .map((c) => _IntentChip(data: c))
              .toList(),
        ),
      ],
    );
  }
}

class _ChipData {
  final IconData icon;
  final String label;
  final Color color;
  const _ChipData({required this.icon, required this.label, required this.color});
}

class _IntentChip extends StatelessWidget {
  final _ChipData data;
  const _IntentChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 13, color: data.color),
          const SizedBox(width: 4),
          Text(
            data.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: data.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
