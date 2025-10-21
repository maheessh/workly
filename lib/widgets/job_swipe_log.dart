import 'package:flutter/material.dart';

class JobSwipeLogo extends StatelessWidget {
  final double size;
  const JobSwipeLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.work, color: Theme.of(context).primaryColor, size: size),
        const SizedBox(width: 8),
        Text(
          'JobSwipe',
          style: TextStyle(
            fontSize: size * 0.8,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}