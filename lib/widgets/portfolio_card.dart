import 'package:flutter/material.dart';
import '../constants/colors.dart';
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
            stream: _supabase
                .from('loans')
                .stream(primaryKey: ['id'])
                .map((rows) => rows),
            builder: (context, snapshot) {
              final text = snapshot.hasData
                  ? '₱${_total(snapshot.data!).toStringAsFixed(2)}'
                  : snapshot.hasError
                      ? 'Error'
                      : 'Loading...';
              return Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Active Loans', '124'),
              _buildStat('Borrowers', '98'),
              _buildStat('Overdue', '12'),
            ],
          ),
        ],
      ),
    );
  }

  double _total(List<Map<String, dynamic>> rows) {
    double total = 0;
    for (var row in rows) {
      total += (row['principal_amount'] as num).toDouble();
    }
    return total;
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