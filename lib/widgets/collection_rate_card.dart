import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CollectionRateCard extends StatelessWidget {
  const CollectionRateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.78,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: AppColors.success,
                  strokeWidth: 6,
                ),
                const Center(child: Text('78%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Collection Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('This Month', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text('↑ +4% vs last month', style: TextStyle(color: AppColors.success, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}