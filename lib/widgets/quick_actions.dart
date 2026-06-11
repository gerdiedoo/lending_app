import 'package:flutter/material.dart';
import '../constants/colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIcon(Icons.add, 'New Loan', AppColors.primary),
        _buildActionIcon(Icons.group_add_outlined, 'Borrowers', AppColors.surface),
        _buildActionIcon(Icons.money, 'Collect', AppColors.success),
        _buildActionIcon(Icons.description_outlined, 'Reports', AppColors.surface),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, Color bgColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: bgColor,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}