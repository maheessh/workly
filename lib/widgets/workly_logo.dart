// lib/widgets/workly_logo.dart
import 'package:flutter/material.dart';

/// Full-brand Workly wordmark widget.
/// - Use WorklyLogo(size: ...) where you want the logo.
/// - The widget draws a gradient rounded rectangle icon + "WORKLY" wordmark.
/// - Animated entrance (slight scale + fade).
class WorklyLogo extends StatefulWidget {
  final double size; // height of the icon part
  final double? textSize;

  const WorklyLogo({super.key, this.size = 40, this.textSize});

  @override
  State<WorklyLogo> createState() => _WorklyLogoState();
}

class _WorklyLogoState extends State<WorklyLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _anim = CurvedAnimation(parent: _ctl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctl.forward();
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.size;
    final double textSize = widget.textSize ?? (height * 0.55);

    return FadeTransition(
      opacity: _anim,
      child: ScaleTransition(
        scale: _anim,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // gradient rounded rectangle + "W" glyph
            Container(
              height: height,
              width: height,
              padding: EdgeInsets.all(height * 0.15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  // G3: maroon -> orange-ish red
                  colors: [Color(0xFFB3363D), Color(0xFFEB5A36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(height * 0.22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 6))],
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  'W',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Wordmark
            Text(
              'WORKLY',
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
