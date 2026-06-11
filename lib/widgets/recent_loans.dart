import 'package:flutter/material.dart';
import '../constants/colors.dart';

class RecentLoansList extends StatelessWidget {
  const RecentLoansList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Recent Loans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('See All', style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildLoanTile('Maria Santos', 'Due Dec 15', '₱50,000', 'Active', AppColors.primary, 'https://i.pravatar.cc/150?img=5'),
              _buildLoanTile('Jose Reyes', 'Due Nov 30', '₱25,000', 'Overdue', AppColors.danger, 'https://i.pravatar.cc/150?img=8'),
              _buildLoanTile('Ana Cruz', 'Due Jan 10', '₱80,000', 'Paid', AppColors.success, 'https://i.pravatar.cc/150?img=9'),
              _buildLoanTile('Pedro Lim', 'Due Dec 20', '₱15,000', 'Pending', AppColors.warning, 'https://i.pravatar.cc/150?img=12'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTile(String name, String date, String amount, String status, Color statusColor, String imageUrl) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}