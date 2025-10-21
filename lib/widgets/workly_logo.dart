import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';

class WorklyLogo extends StatelessWidget {
  final double size;
  const WorklyLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.insights, color: AppTheme.primaryColor, size: size), // A "smart" icon
        const SizedBox(width: 10),
        Text(
          'Workly',
          style: TextStyle(
            fontSize: size * 0.9,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}