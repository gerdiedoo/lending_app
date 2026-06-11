import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    // Shorthand reference to the Supabase Client instance
    final supabase = Supabase.instance.client;
    // Safely retrieve the current user's email if available
    final String userEmail = supabase.auth.currentUser?.email ?? 'Manager Portal';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: User greeting and context
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back, 👋',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail.split('@')[0], // Displays the first part of their email as a nickname
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Right side: Interactive utility bar (Notifications & Profile Menu)
          Row(
            children: [
              // Notification Badge Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      onPressed: () {
                        // Optional: Add notification panel logic here
                      },
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Interactive Profile Dropdown with Supabase Integration
              PopupMenuButton<String>(
                offset: const Offset(0, 52),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    // Triggers state change event in main.dart StreamBuilder
                    await supabase.auth.signOut();
                  }
                },
                // Uses the profile avatar image as the interactable base widget button
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // border: Border(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surface,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=6'),
                  ),
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signed in as',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          userEmail,
                          style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 18, color: Colors.white70),
                        SizedBox(width: 10),
                        Text('Profile Settings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text('Sign Out', style: TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}