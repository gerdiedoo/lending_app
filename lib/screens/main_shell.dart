import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'borrowers_screen.dart';
import '../screens/empty_screen_template.dart';
import '../widgets/bottom_nav_bar.dart';

/// The root shell of the authenticated app.
///
/// Owns the [BottomNavigationBar] state and keeps every tab alive in an
/// [IndexedStack] so scroll position, loaded data, etc. are preserved
/// when the user switches tabs.
///
/// --- Adding a new tab ---
/// 1. Add a new screen widget to [_screens] below.
/// 2. Add the matching [BottomNavigationBarItem] in [AppBottomNavBar].
/// That's it — no other file needs to change.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  /// One entry per tab. Order must match [AppBottomNavBar.items].
  final List<Widget> _screens = [
    const DashboardScreen(),
    const BorrowersScreen(),
    const EmptyScreenTemplate(title: 'Payments'),
    const EmptyScreenTemplate(title: 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tab widgets mounted (so their state is
      // preserved), but only renders the one at [_selectedIndex].
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}