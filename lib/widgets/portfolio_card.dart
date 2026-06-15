import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/loan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortfolioCard extends StatelessWidget {
  PortfolioCard({super.key});

  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Portfolio',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('loans').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }

              final loans = snapshot.data!.map((j) => Loan.fromJson(j)).toList();

              final total = loans.fold<double>(0.0, (sum, l) => sum + l.principalAmount);
              final activeCount = loans.where((l) => l.status == 'Active').length;
              final overdueCount = loans.where((l) => l.status == 'Overdue').length;
              final borrowerCount = loans.map((l) => l.borrowerName).toSet().length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${_formatAmount(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Active Loans', '$activeCount'),
                      _buildStat('Borrowers', '$borrowerCount'),
                      _buildStat('Overdue', '$overdueCount'),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
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

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}