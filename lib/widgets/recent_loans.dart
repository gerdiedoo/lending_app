import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';

class RecentLoans extends StatelessWidget {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('loans')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(5), // Keeping it to the most recent 5
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No recent loans", style: TextStyle(color: Colors.grey)));
        }

        final loans = snapshot.data!.map((json) => Loan.fromJson(json)).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: loans.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final loan = loans[index];
            
            // This is your original UI card design structure
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loan.borrowerName, 
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(loan.status, 
                             style: TextStyle(color: loan.status == 'Active' ? Colors.green : Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('₱${loan.principalAmount.toStringAsFixed(2)}', 
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}