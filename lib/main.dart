import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const LendingApp());
}

class LendingApp extends StatelessWidget {
  const LendingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lending Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}