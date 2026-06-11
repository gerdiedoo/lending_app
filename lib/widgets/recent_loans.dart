import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../screens/all_loans_screen.dart';
import 'loan_shared_widgets.dart';

class RecentLoans extends StatelessWidget {
  final _supabase = Supabase.instance.client;

  RecentLoans({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('loans')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        return Column(
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Loans',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllLoansScreen(),
                    ),
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── List container ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildBody(context, snapshot),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No recent loans', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final loans = snapshot.data!.map((j) => Loan.fromJson(j)).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loans.length,
      separatorBuilder: (_, __) => Divider(
        color: Colors.white.withOpacity(0.06),
        height: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (_, index) {
        final loan = loans[index];
        return LoanRow(
          loan: loan,
          onTap: () => showLoanDetail(context, loan),
        );
      },
    );
  }
}