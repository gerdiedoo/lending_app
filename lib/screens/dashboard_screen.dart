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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Incrementing this key forces FutureBuilder widgets to fully
  // rebuild and re-fetch their data from Supabase.
  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
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
                PortfolioCard(key: ValueKey('portfolio_$_refreshKey')),
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
                MonthlyCollectionsChart(key: ValueKey('chart_$_refreshKey')),
                const SizedBox(height: 16),
                MonthlyLoansChart(key: ValueKey('loans_chart_$_refreshKey')),
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