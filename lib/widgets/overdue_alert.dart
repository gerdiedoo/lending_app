import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';
import '../models/loan_model.dart';

class OverdueAlert extends StatelessWidget {
  const OverdueAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('loans').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final loans = (snapshot.data ?? []).map((j) => Loan.fromJson(j)).toList();
        final overdueLoans = loans.where((l) => l.status == 'Overdue').toList();

        // Nothing overdue — don't show a red warning box for no reason.
        if (overdueLoans.isEmpty) return const SizedBox.shrink();

        final totalOutstanding =
            overdueLoans.fold<double>(0.0, (sum, l) => sum + l.principalAmount);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            border: Border.all(color: AppColors.danger.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overdueLoans.length} Overdue ${overdueLoans.length == 1 ? 'Loan' : 'Loans'}',
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total outstanding: ₱${_formatAmount(totalOutstanding)} • Immediate follow-up needed',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}