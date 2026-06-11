import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return null;

    final response = await Supabase.instance.client
        .from('profiles')
        .select('full_name, avatar_url')
        .eq('id', uid)
        .maybeSingle();

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final fullName = snapshot.data?['full_name'] as String? ?? 'Lending Manager';
        final avatarUrl = snapshot.data?['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?img=6';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Greeting + name from profiles table
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
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Right side: Notifications + Profile Menu
            Row(
              children: [
                // Notification button
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

                // Profile avatar with popup menu
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await Supabase.instance.client.auth.signOut();
                    }
                  },
                  // Avatar uses real URL from profiles; falls back to placeholder
                  // while loading or if the profile fetch fails
                  icon: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatarUrl),
                    // Show a surface-coloured circle while the image loads
                    backgroundColor: AppColors.surface,
                  ),
                  offset: const Offset(0, 50),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            Supabase.instance.client.auth.currentUser?.email ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
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
      },
    );
  }
}