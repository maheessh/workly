import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const GoogleIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: GoogleIconPainter(color: color),
    );
  }
}

class GoogleIconPainter extends CustomPainter {
  final Color? color;

  GoogleIconPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color ?? Colors.white;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.grey.shade300;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the main circle
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, strokePaint);

    // Draw the "G" shape
    final gPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue.shade600;

    final path = Path();
    
    // Create a simple "G" shape
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.6,
      height: size.height * 0.6,
    );
    
    path.addOval(rect);
    
    // Cut out the inner part
    final innerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.3,
      height: size.height * 0.3,
    );
    path.addOval(innerRect);
    
    // Add the horizontal line
    final lineRect = Rect.fromLTWH(
      center.dx - size.width * 0.1,
      center.dy - size.height * 0.05,
      size.width * 0.2,
      size.height * 0.1,
    );
    path.addRect(lineRect);

    canvas.drawPath(path, gPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}