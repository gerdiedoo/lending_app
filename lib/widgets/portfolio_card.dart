import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortfolioCard extends StatefulWidget {
  const PortfolioCard({super.key});

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  late Future<double> _portfolioFuture;

  @override
  void initState() {
    super.initState();
    _portfolioFuture = _getPortfolioTotal();
  }

  Future<double> _getPortfolioTotal() async {
    final response = await Supabase.instance.client
        .from('loans')
        .select('principal_amount');

    double total = 0;
    for (var row in response) {
      total += (row['principal_amount'] as num).toDouble();
    }
    return total;
  }

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
          FutureBuilder<double>(
            future: _portfolioFuture,
            builder: (context, snapshot) {
              final text = snapshot.hasData
                  ? '₱${snapshot.data!.toStringAsFixed(2)}'
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