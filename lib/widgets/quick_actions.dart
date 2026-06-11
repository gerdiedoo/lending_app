import 'package:flutter/material.dart';
import 'package:lending_app/screens/create_loan_screen.dart';
import 'package:lending_app/screens/empty_screen_template.dart';
import '../constants/colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIcon(Icons.add, 'New Loan', AppColors.primary, screen: const CreateLoanScreen()),
        _buildActionIcon(
          Icons.group_add_outlined,
          'Borrowers',
          AppColors.surface,
        ),
        _buildActionIcon(Icons.money, 'Collect', AppColors.success),
        _buildActionIcon(
          Icons.description_outlined,
          'Reports',
          AppColors.surface,
        ),
      ],
    );
  }

  // add the screen in the parameters of the function to make it reusable for other screens
  Widget _buildActionIcon(
    IconData icon,
    String label,
    Color bgColor, {
    Widget? screen,
  }) {
    return Column(
      children: [
        //wrap the CircleAvatar in a button to make it clickable
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => screen ?? const EmptyScreenTemplate(title: 'Under Construction'),
                ),
              );
              // Handle button press
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: CircleBorder(),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: bgColor,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
