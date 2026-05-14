import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/price_quote.dart';
import '../constants/app_constants.dart';

class PriceQuoteCard extends StatelessWidget {
  final PriceQuote quote;

  const PriceQuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryGreen.withValues(alpha: 0.05),
            AppConstants.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.primaryGreen.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppConstants.primaryGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                'Price Breakdown',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppConstants.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Row(label: 'Base Fee', amount: quote.baseFee, icon: Icons.handshake_outlined),
          _Row(
            label: 'Distance Adjustment',
            amount: quote.distanceAdjustment,
            icon: Icons.directions_car_outlined,
          ),
          _Row(
            label: 'Urgency Surcharge',
            amount: quote.urgencySurcharge,
            icon: Icons.flash_on_outlined,
          ),
          _Row(
            label: 'Loyalty Discount',
            amount: -quote.loyaltyDiscount,
            icon: Icons.loyalty_outlined,
            isDiscount: true,
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PKR ${quote.total.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (quote.breakdownExplanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              quote.breakdownExplanation,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final bool isDiscount;

  const _Row({
    required this.label,
    required this.amount,
    required this.icon,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    if (amount == 0) return const SizedBox.shrink();
    final color = isDiscount ? Colors.green[700]! : Colors.grey[800]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
          Text(
            isDiscount
                ? '- PKR ${amount.abs().toStringAsFixed(0)}'
                : '+ PKR ${amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
