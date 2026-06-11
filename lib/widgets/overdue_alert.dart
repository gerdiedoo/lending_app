import 'package:flutter/material.dart';
import '../constants/colors.dart';

class OverdueAlert extends StatelessWidget {
  const OverdueAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('12 Overdue Loans', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Total outstanding: ₱183,500 • Immediate follow-up needed', 
                     style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}