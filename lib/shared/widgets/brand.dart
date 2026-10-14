import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The app's mark: two interlocking hairline rings — a couple — drawn in the
/// champagne→rosé accent gradient. Replaces the emoji used as a logo.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.45,
      height: size,
      child: CustomPaint(painter: _RingsPainter()),
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.42;
    final offset = r * 0.58;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.height * 0.035).clamp(1.2, 3.0)
      ..isAntiAlias = true
      ..shader = AppColors.accentGradient.createShader(Offset.zero & size);
    canvas.drawCircle(center - Offset(offset, 0), r, paint);
    canvas.drawCircle(center + Offset(offset, 0), r, paint);
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}

/// Mark + wordmark lockup used on the entry screens (login, age gate, PIN).
class BrandLockup extends StatelessWidget {
  final double markSize;
  final bool showTagline;

  const BrandLockup({super.key, this.markSize = 52, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(height: 20),
        const Text(
          'Kamasutra',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontSize: 38,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            height: 1.0,
            color: AppColors.ivory,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 10),
          Text(
            '& COUPLE GAMES',
            textAlign: TextAlign.center,
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.champagne,
              letterSpacing: 4,
            ),
          ),
        ],
      ],
    );
  }
}

/// Warm, low-key backdrop for full-bleed screens: the ink canvas lit by two
/// soft glows (wine top-left, champagne bottom-right). Depth without neon.
class VelvetBackground extends StatelessWidget {
  final Widget child;

  const VelvetBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.ink),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.9, -1.0),
                  radius: 1.1,
                  colors: [Color(0x408E2C48), Color(0x008E2C48)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(1.0, 1.1),
                  radius: 1.0,
                  colors: [Color(0x1FE9C9A6), Color(0x00E9C9A6)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
