import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class MonthlyCollectionsChart extends StatelessWidget {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase.from('monthly_collections').select('*'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!;
        
        return Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Collections', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: data.map((e) => BarChartGroupData(
                      x: e['month_number'],
                      barRods: [BarChartRodData(toY: (e['total_collected'] as num).toDouble(), color: AppColors.primary)],
                    )).toList(),
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