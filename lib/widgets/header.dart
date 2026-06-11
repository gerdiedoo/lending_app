import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart'; // Ensure this matches your project structure

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Greeting text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lending Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        // Right side: Notifications and Profile Menu
        Row(
          children: [
            // Notification Badge
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {
                  // Add notification logic here
                },
              ),
            ),
            const SizedBox(width: 16),
            
            // Interactive Profile Avatar with Supabase Logout
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  // Clear Supabase Session - automatically pushes user back to LoginScreen
                  await Supabase.instance.client.auth.signOut();
                }
              },
              icon: const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=6'),
              ),
              offset: const Offset(0, 50),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('My Profile', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}