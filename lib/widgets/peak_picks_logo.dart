import 'dart:io';
import 'package:flutter/material.dart';

/// Tries to load the PNG logo from assets.
/// Falls back to a gradient mountain icon + gradient text if the asset
/// is missing (so the app never crashes during development).
class PeakPicksLogo extends StatelessWidget {
  final double height;
  final bool showText;
  const PeakPicksLogo({super.key, this.height = 40, this.showText = true});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF56C8F5), Color(0xFFC97CFE)],
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Try asset image first, fall back to painted icon
        _LogoIcon(size: height),
        if (showText) ...[
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => _gradient.createShader(bounds),
            child: Text(
              'PeakPicks',
              style: TextStyle(
                fontSize: height * 0.6,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small version for nav bars, loading screens, etc.
class PeakPicksIcon extends StatelessWidget {
  final double size;
  const PeakPicksIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return _LogoIcon(size: size);
  }
}

/// Renders the mountain peak icon.
/// Attempts to load assets/images/logo.png first; if that fails,
/// paints a gradient mountain using CustomPaint.
class _LogoIcon extends StatelessWidget {
  final double size;
  const _LogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    // Try the asset image
    return Image.asset(
      'assets/images/logo.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _PaintedPeak(size: size),
    );
  }
}

/// Gradient mountain peak drawn with CustomPaint — used as fallback.
class _PaintedPeak extends StatelessWidget {
  final double size;
  const _PaintedPeak({required this.size});

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
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back mountain (purple-pink)
    final backPath = Path()
      ..moveTo(w * 0.15, h * 0.85)
      ..lineTo(w * 0.55, h * 0.12)
      ..lineTo(w * 0.92, h * 0.85)
      ..close();
    final backPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC97CFE), Color(0xFFAB47BC)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(backPath, backPaint);

    // Front mountain (teal-blue)
    final frontPath = Path()
      ..moveTo(w * 0.05, h * 0.85)
      ..lineTo(w * 0.42, h * 0.18)
      ..lineTo(w * 0.78, h * 0.85)
      ..close();
    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF00E5A0), Color(0xFF56C8F5)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(frontPath, frontPaint);

    // Sparkle at peak
    final sparklePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.42, h * 0.16), w * 0.025, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
