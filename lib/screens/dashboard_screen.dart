import 'package:flutter/material.dart';
import 'package:lending_app/widgets/monthly_collections_chart.dart';
import '../constants/colors.dart';
import '../widgets/header.dart';
import '../widgets/portfolio_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/stats_cards.dart';
import '../widgets/collection_rate_card.dart';
import '../widgets/recent_loans.dart';
import '../widgets/overdue_alert.dart';
import '../widgets/monthly_loans_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _onRefresh() async {
    // The widgets below are backed by realtime StreamBuilders, so they
    // update automatically. This delay just gives the RefreshIndicator's
    // spinner a moment to show/hide for a satisfying pull-to-refresh feel.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                const SizedBox(height: 24),
                PortfolioCard(),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const QuickActions(),
                const SizedBox(height: 24),
                const FinancialStatsRow(),
                const SizedBox(height: 16),
                const CollectionRateCard(),
                const SizedBox(height: 16),
                MonthlyCollectionsChart(),
                const SizedBox(height: 16),
                MonthlyLoansChart(),
                const SizedBox(height: 24),
                RecentLoans(),
                const SizedBox(height: 24),
                const OverdueAlert(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}