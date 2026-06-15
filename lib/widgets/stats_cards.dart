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
      builder: (context, snapshot) {
        final loans = (snapshot.data ?? []).map((j) => Loan.fromJson(j)).toList();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Collected today: principal of loans marked Paid whose loan_date is today.
        final collectedToday = loans
            .where((l) =>
                l.status == 'Paid' &&
                l.loanDate.year == today.year &&
                l.loanDate.month == today.month &&
                l.loanDate.day == today.day)
            .fold<double>(0.0, (sum, l) => sum + l.principalAmount);

        // Pending: outstanding monthly installments for loans not yet Paid.
        final pending = loans
            .where((l) => l.status != 'Paid')
            .fold<double>(0.0, (sum, l) => sum + l.monthlyInstallment);

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