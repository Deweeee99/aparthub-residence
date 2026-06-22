import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LuxuryBackground extends StatelessWidget {
  const LuxuryBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundSoft,
            AppColors.background,
            Color(0xFFF4EEE4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LuxuryPatternPainter())),
          child,
        ],
      ),
    );
  }
}

class _LuxuryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navyStroke = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.08)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final goldStroke = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.14 + (i * 0.2));
      final path = Path()
        ..moveTo(-size.width * 0.1, y)
        ..cubicTo(
          size.width * 0.2,
          y - 24,
          size.width * 0.65,
          y + 36,
          size.width * 1.05,
          y - 16,
        );
      canvas.drawPath(path, i.isEven ? navyStroke : goldStroke);
    }

    final glow = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 86, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
