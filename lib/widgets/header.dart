import 'package:flutter/material.dart';
import '../constants/colors.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Good morning,', style: TextStyle(color: Colors.grey, fontSize: 14)),
            Text('Admin Juan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: const Icon(Icons.notifications_none, color: Colors.white),
                ),
                const Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: AppColors.danger,
                    child: Text('3', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          ],
        ),
      ],
    );
  }
}