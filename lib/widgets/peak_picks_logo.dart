import 'package:flutter/material.dart';

/// PeakPicks brand logo — icon + gradient wordmark, always centered.
class PeakPicksLogo extends StatelessWidget {
  final double height;
  final bool showText;
  const PeakPicksLogo({super.key, this.height = 40, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PeakIcon(size: height * 1.4),
        if (showText) ...[
          const SizedBox(height: 8),
          _GradientText(
            'PeakPicks',
            style: TextStyle(
              fontSize: height * 0.65,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Smaller icon-only version for nav bars / loading screens.
class PeakPicksIcon extends StatelessWidget {
  final double size;
  const PeakPicksIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) => _PeakIcon(size: size);
}

// ── Gradient wordmark ────────────────────────────────────────────────────────

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _GradientText(this.text, {required this.style});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF56C8F5), Color(0xFFB388FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => _gradient.createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

// ── Custom peak icon ─────────────────────────────────────────────────────────

class _PeakIcon extends StatelessWidget {
  final double size;
  const _PeakIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PeakPainter()),
    );
  }
}

class _PeakPainter extends CustomPainter {
  static const _gradient1 = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF56C8F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const _gradient2 = LinearGradient(
    colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // ── Background circle ────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = const Color(0xFF1C2128)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // ── Back peak (purple) ───────────────────────────────────────────────────
    final backPath = Path()
      ..moveTo(w * 0.20, h * 0.78)
      ..lineTo(w * 0.58, h * 0.18)
      ..lineTo(w * 0.88, h * 0.78)
      ..close();
    canvas.drawPath(
      backPath,
      Paint()..shader = _gradient2.createShader(rect),
    );

    // ── Front peak (teal) ────────────────────────────────────────────────────
    final frontPath = Path()
      ..moveTo(w * 0.10, h * 0.78)
      ..lineTo(w * 0.42, h * 0.22)
      ..lineTo(w * 0.74, h * 0.78)
      ..close();
    canvas.drawPath(
      frontPath,
      Paint()..shader = _gradient1.createShader(rect),
    );

    // ── Snow cap on front peak ───────────────────────────────────────────────
    final snowPath = Path()
      ..moveTo(w * 0.42, h * 0.22)
      ..lineTo(w * 0.35, h * 0.40)
      ..lineTo(w * 0.50, h * 0.40)
      ..close();
    canvas.drawPath(
      snowPath,
      Paint()..color = Colors.white.withValues(alpha: 0.90),
    );

    // ── Star / sparkle at tip ────────────────────────────────────────────────
    final sparklePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.42, h * 0.20), w * 0.028, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
