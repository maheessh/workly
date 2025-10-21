import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const WorklyApp());
}

class WorklyApp extends StatelessWidget {
  const WorklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workly',
      theme: AppTheme.lightTheme, // Use the new, clean theme
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}