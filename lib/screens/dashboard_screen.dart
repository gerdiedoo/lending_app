import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/header.dart';
import '../widgets/portfolio_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/stats_cards.dart';
import '../widgets/collection_rate_card.dart';
import '../widgets/recent_loans.dart';
import '../widgets/overdue_alert.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              DashboardHeader(),
              SizedBox(height: 24),
              PortfolioCard(),
              SizedBox(height: 24),
              Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 16),
              QuickActions(),
              SizedBox(height: 24),
              FinancialStatsRow(),
              SizedBox(height: 16),
              CollectionRateCard(),
              SizedBox(height: 24),
              RecentLoansList(),
              SizedBox(height: 24),
              OverdueAlert(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Borrowers'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}