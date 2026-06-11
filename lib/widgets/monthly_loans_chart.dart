import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class MonthlyLoansChart extends StatefulWidget {
  const MonthlyLoansChart({super.key});

  @override
  State<MonthlyLoansChart> createState() => _MonthlyLoansChartState();
}

class _MonthlyLoansChartState extends State<MonthlyLoansChart> {
  static const List<String> _monthLabels = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];

  late Future<Map<int, double>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  /// Fetches all loans for the current year and aggregates
  /// the total principal amount issued per month.
  Future<Map<int, double>> _fetchData() async {
    final currentYear = DateTime.now().year;

    final response = await Supabase.instance.client
        .from('loans')
        .select('principal_amount, created_at')
        .gte('created_at', '$currentYear-01-01')
        .lte('created_at', '$currentYear-12-31');

    final Map<int, double> totals = {};
    for (final row in response) {
      final month = DateTime.parse(row['created_at']).month;
      final amount = (row['principal_amount'] as num).toDouble();
      totals[month] = (totals[month] ?? 0) + amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, double>>(
      future: _dataFuture,
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

        final monthTotals = snapshot.data!;
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