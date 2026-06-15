import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';
import '../models/loan_model.dart';

class CollectionRateCard extends StatelessWidget {
  const CollectionRateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('loans').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final loans = (snapshot.data ?? []).map((j) => Loan.fromJson(j)).toList();

        final totalPrincipal = loans.fold<double>(0.0, (sum, l) => sum + l.principalAmount);
        final collectedPrincipal = loans
            .where((l) => l.status == 'Paid')
            .fold<double>(0.0, (sum, l) => sum + l.principalAmount);

        final rate = totalPrincipal == 0 ? 0.0 : (collectedPrincipal / totalPrincipal);
        final ratePercent = (rate * 100).round();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: rate.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      color: AppColors.success,
                      strokeWidth: 6,
                    ),
                    Center(
                      child: Text(
                        '$ratePercent%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collection Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Overall', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}