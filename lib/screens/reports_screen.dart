import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan_model.dart';
import '../constants/colors.dart';
import '../widgets/loan_shared_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('loans').stream(primaryKey: ['id']),
          builder: (context, loanSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('payments').stream(primaryKey: ['id']),
              builder: (context, paymentSnapshot) {
                if (loanSnapshot.connectionState == ConnectionState.waiting ||
                    paymentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final loans = (loanSnapshot.data ?? []).map((j) => Loan.fromJson(j)).toList();
                final payments = paymentSnapshot.data ?? [];
                final loansById = {for (final l in loans) l.id: l};

                // ── Derived metrics ──────────────────────────────────
                // Total interest earned: actual interest collected so far.
                //  - interest_only payments are 100% interest.
                //  - full settlements include interest on top of principal;
                //    looked up via loan_id to get that loan's exact rate.
                double totalInterest = 0.0;
                for (final p in payments) {
                  final kind = p['kind'] ?? 'manual';
                  final amount = (p['amount_paid'] as num).toDouble();
                  if (kind == 'interest_only') {
                    totalInterest += amount;
                  } else if (kind == 'full') {
                    final loan = loansById[p['loan_id']];
                    if (loan != null && loan.interestRate > 0) {
                      totalInterest += amount * loan.interestRate / (100 + loan.interestRate);
                    }
                  }
                }

                final totalCount = loans.length;
                final activeCount = loans.where((l) => l.status == 'Active').length;
                final paidCount = loans.where((l) => l.status == 'Paid').length;
                final overdueCount = loans.where((l) => l.status == 'Overdue').length;
                final pendingCount = loans.where((l) => l.status == 'Pending').length;

                final collectedAmount = loans
                    .where((l) => l.status == 'Paid')
                    .fold<double>(0.0, (sum, l) => sum + l.principalAmount);
                final totalPrincipal = loans.fold<double>(0.0, (sum, l) => sum + l.principalAmount);
                final collectionRate = totalPrincipal == 0 ? 0.0 : (collectedAmount / totalPrincipal) * 100;

                // Projected revenue: interest income expected from loans still
                // outstanding — principal returning isn't revenue, the interest
                // collected on it is.
                final projectedRevenue = loans
                    .where((l) => l.status != 'Paid')
                    .fold<double>(0.0, (sum, l) => sum + l.interestOnlyAmount);

                // Monthly collections for the current year (Jan-Jun shown,
                // matching the mockup's 6-month window).
                final now = DateTime.now();
                final Map<int, double> monthlyCollections = {};
                for (final l in loans) {
                  if (l.status != 'Paid') continue;
                  if (l.loanDate.year != now.year) continue;
                  monthlyCollections[l.loanDate.month] =
                      (monthlyCollections[l.loanDate.month] ?? 0) + l.principalAmount;
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Total interest earned ──────────────────────
                  _StatCard(
                    label: 'TOTAL INTEREST EARNED',
                    value: '₱${formatAmount(totalInterest)}',
                    valueColor: AppColors.primaryGradientEnd,
                    badge: const _TrendBadge(text: '+8%'),
                    footer: 'vs last month',
                  ),

                  const SizedBox(height: 12),

                  // ── Collection rate ─────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
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
                            Text(
                              'COLLECTION RATE',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                collectionRate >= 80 ? 'On Track' : 'Needs Attention',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${collectionRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (collectionRate / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Projected revenue ────────────────────────────
                  _StatCard(
                    label: 'PROJECTED REVENUE',
                    value: '₱${formatAmount(projectedRevenue)}',
                    valueColor: Colors.white,
                    icon: Icons.show_chart,
                    footer: 'Next 30 days',
                  ),

                  const SizedBox(height: 20),

                  // ── Collection trends ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
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
                            const Text(
                              'Collection Trends',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _CollectionTrendsChart(monthlyCollections: monthlyCollections),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Portfolio status ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Portfolio Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Segmented bar
                        if (totalCount > 0)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 10,
                              child: Row(
                                children: [
                                  if (activeCount > 0)
                                    Expanded(
                                      flex: activeCount,
                                      child: Container(color: AppColors.primary),
                                    ),
                                  if (overdueCount > 0)
                                    Expanded(
                                      flex: overdueCount,
                                      child: Container(color: AppColors.danger.withOpacity(0.6)),
                                    ),
                                  if (paidCount > 0)
                                    Expanded(
                                      flex: paidCount,
                                      child: Container(color: AppColors.success),
                                    ),
                                  if (pendingCount > 0)
                                    Expanded(
                                      flex: pendingCount,
                                      child: Container(color: const Color(0xFFFFB300)),
                                    ),
                                ],
                              ),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(height: 10, color: AppColors.background),
                          ),

                        const SizedBox(height: 16),

                        _PortfolioStatusRow(
                          color: AppColors.primary,
                          label: 'Active',
                          count: activeCount,
                          total: totalCount,
                        ),
                        const SizedBox(height: 10),
                        _PortfolioStatusRow(
                          color: AppColors.success,
                          label: 'Paid',
                          count: paidCount,
                          total: totalCount,
                        ),
                        const SizedBox(height: 10),
                        _PortfolioStatusRow(
                          color: AppColors.danger,
                          label: 'Overdue',
                          count: overdueCount,
                          total: totalCount,
                          highlight: true,
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(height: 10),
                          _PortfolioStatusRow(
                            color: const Color(0xFFFFB300),
                            label: 'Pending',
                            count: pendingCount,
                            total: totalCount,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Export advanced analytics ────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export Advanced Analytics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate comprehensive PDF reports including risk assessment and borrower behavioral metrics.',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report generation coming soon'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Generate Report',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String footer;
  final Widget? badge;
  final IconData? icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.footer,
    this.badge,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (badge != null) badge!,
              if (icon != null) Icon(icon, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Trend badge ──────────────────────────────────────────────────────────────

class _TrendBadge extends StatelessWidget {
  final String text;

  const _TrendBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, size: 13, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Portfolio status row ─────────────────────────────────────────────────────

class _PortfolioStatusRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  final bool highlight;

  const _PortfolioStatusRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count / total * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: highlight ? Border.all(color: color.withOpacity(0.4)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlight ? color : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: highlight ? color : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: highlight ? color.withOpacity(0.8) : Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Collection trends line chart ─────────────────────────────────────────────

class _CollectionTrendsChart extends StatelessWidget {
  final Map<int, double> monthlyCollections;

  const _CollectionTrendsChart({required this.monthlyCollections});

  static const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(6, (i) {
      final month = i + 1;
      return FlSpot(i.toDouble(), monthlyCollections[month] ?? 0.0);
    });

    final maxValue = monthlyCollections.values.isEmpty
        ? 100000.0
        : (monthlyCollections.values.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(25000.0, double.infinity);

    // Round maxY up to the nearest 25k for clean gridlines
    final maxY = (((maxValue / 25000).ceil()) * 25000).toDouble();
    final interval = maxY / 4;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final k = (value / 1000).round();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${k}k',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _months.length) return const SizedBox();
                final isCurrentMonth = (idx + 1) == DateTime.now().month;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _months[idx],
                    style: TextStyle(
                      color: isCurrentMonth ? AppColors.primary : Colors.grey[500],
                      fontSize: 12,
                      fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.25),
                  AppColors.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}