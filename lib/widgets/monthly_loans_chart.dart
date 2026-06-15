import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class MonthlyLoansChart extends StatelessWidget {
  MonthlyLoansChart({super.key});

  final _supabase = Supabase.instance.client;

  static const List<String> _monthLabels = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];

  /// Aggregates rows for the current year into total principal per month.
  Map<int, double> _aggregate(List<Map<String, dynamic>> rows) {
    final currentYear = DateTime.now().year;
    final Map<int, double> totals = {};
    for (final row in rows) {
      final date = DateTime.parse(row['created_at']);
      if (date.year != currentYear) continue;
      final amount = (row['principal_amount'] as num).toDouble();
      totals[date.month] = (totals[date.month] ?? 0) + amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('loans')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final monthTotals = _aggregate(snapshot.data!);
        final currentMonth = DateTime.now().month;

        final barGroups = List.generate(12, (index) {
          final monthNum = index + 1;
          final value = monthTotals[monthNum] ?? 0.0;
          final isCurrentMonth = monthNum == currentMonth;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: isCurrentMonth
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.15),
                width: 10,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        });

        final maxY = monthTotals.values.isEmpty
            ? 10.0
            : monthTotals.values.reduce((a, b) => a > b ? a : b) * 1.25;

        return Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Loans',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    barGroups: barGroups,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= 12) return const SizedBox();
                            final isCurrentMonth = (idx + 1) == currentMonth;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _monthLabels[idx],
                                style: TextStyle(
                                  color: isCurrentMonth
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                  fontWeight: isCurrentMonth
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                          reservedSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}