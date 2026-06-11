import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FinancialStatsRow extends StatelessWidget {
  const FinancialStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Collected Today', '₱38,200', '+12%', true)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Pending', '₱14,500', '-3%', false)),
      ],
    );
  }

  Widget _buildStatCard(String title, String amount, String percentage, bool isPositive) {
    final Color trendColor = isPositive ? AppColors.success : AppColors.danger;

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
              Icon(isPositive ? Icons.trending_up : Icons.schedule, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: trendColor, size: 12),
              Text(percentage, style: TextStyle(color: trendColor, fontSize: 12)),
              const Text(' vs last month', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}