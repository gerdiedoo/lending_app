import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';
import '../models/loan_model.dart';

class FinancialStatsRow extends StatelessWidget {
  const FinancialStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('loans').stream(primaryKey: ['id']),
      builder: (context, loanSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('payments').stream(primaryKey: ['id']),
          builder: (context, paymentSnapshot) {
            final loans = (loanSnapshot.data ?? []).map((j) => Loan.fromJson(j)).toList();
            final payments = paymentSnapshot.data ?? [];

            final now = DateTime.now();

            // Collected today: every real payment recorded today, of any
            // kind (manual, full settlement, or interest-only).
            final collectedToday = payments
                .where((p) {
                  final d = DateTime.parse(p['payment_date']);
                  return d.year == now.year && d.month == now.month && d.day == now.day;
                })
                .fold<double>(0.0, (sum, p) => sum + (p['amount_paid'] as num).toDouble());

            // Pending: total amount currently owed (principal + this cycle's
            // interest) across all loans not yet Paid.
            final pending = loans
                .where((l) => l.status != 'Paid')
                .fold<double>(0.0, (sum, l) => sum + l.fullSettlementAmount);

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Collected Today',
                    '₱${_formatAmount(collectedToday)}',
                    Icons.trending_up,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '₱${_formatAmount(pending)}',
                    Icons.schedule,
                    Colors.grey,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  Widget _buildStatCard(String title, String amount, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}