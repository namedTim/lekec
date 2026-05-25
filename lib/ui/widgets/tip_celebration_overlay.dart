import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen celebration shown after a user successfully tips.
///
/// Confetti rains from the top while a circular badge with the tier's icon
/// scales in with an elastic bounce. Taps anywhere dismiss it; it also
/// auto-dismisses after [autoDismissAfter].
class TipCelebrationOverlay extends StatefulWidget {
  const TipCelebrationOverlay({
    super.key,
    required this.title,
    required this.icon,
    this.autoDismissAfter = const Duration(seconds: 4),
  });

  final String title;
  final IconData icon;
  final Duration autoDismissAfter;

  /// Convenience helper to push as a transparent route over the current page.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => TipCelebrationOverlay(
          title: title,
          icon: icon,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<TipCelebrationOverlay> createState() => _TipCelebrationOverlayState();
}

class _TipCelebrationOverlayState extends State<TipCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _badge;
  late final AnimationController _confetti;
  late final Animation<double> _scale;
  late final Animation<double> _textFade;
  late final List<_ConfettiPiece> _pieces;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _badge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _badge, curve: Curves.elasticOut);
    _textFade = CurvedAnimation(
      parent: _badge,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _pieces = _ConfettiPiece.generate(80);

    _badge.forward();
    _confetti.forward();

    Future.delayed(widget.autoDismissAfter, () {
      if (mounted && !_dismissing) _dismiss();
    });
  }

  @override
  void dispose() {
    _badge.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dimmed backdrop.
          Container(color: Colors.black.withOpacity(0.55)),

          // Confetti layer.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (_, _) => CustomPaint(
                painter: _ConfettiPainter(
                  pieces: _pieces,
                  progress: _confetti.value,
                ),
              ),
            ),
          ),

          // Center card.
          Center(
            child: AnimatedBuilder(
              animation: _badge,
              builder: (_, child) => Transform.scale(
                scale: 0.6 + (_scale.value * 0.4),
                child: child,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.35),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary,
                            colors.primary.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 52,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Text(
                            'Hvala!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tap-to-dismiss hint at the bottom.
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: FadeTransition(
              opacity: _textFade,
              child: Text(
                'Dotaknite se za zaprtje',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.fallSpeed,
    required this.drift,
    required this.shape,
  });

  /// Horizontal start position as a fraction of the canvas width [0..1].
  final double x;

  /// Vertical start position as a fraction of the canvas height [-1..0]
  /// (negative so pieces drop in from above the screen).
  final double startY;

  /// Side length in logical pixels.
  final double size;

  final Color color;
  final double rotation; // radians at t=0
  final double rotationSpeed; // radians per unit progress
  final double fallSpeed; // multiplier on progress (1.0 ≈ full screen)
  final double drift; // horizontal sway amplitude
  final int shape; // 0 rect, 1 circle, 2 strip

  static List<_ConfettiPiece> generate(int count) {
    final rnd = math.Random();
    const palette = <Color>[
      Color(0xFFFF6B6B),
      Color(0xFFFFD93D),
      Color(0xFF6BCB77),
      Color(0xFF4D96FF),
      Color(0xFFB983FF),
      Color(0xFFFF8FAB),
    ];
    return List.generate(count, (_) {
      return _ConfettiPiece(
        x: rnd.nextDouble(),
        startY: -rnd.nextDouble() * 0.4,
        size: 6 + rnd.nextDouble() * 10,
        color: palette[rnd.nextInt(palette.length)],
        rotation: rnd.nextDouble() * math.pi * 2,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 8,
        fallSpeed: 0.9 + rnd.nextDouble() * 0.6,
        drift: (rnd.nextDouble() - 0.5) * 80,
        shape: rnd.nextInt(3),
      );
    });
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.progress});

  final List<_ConfettiPiece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final dy = (p.startY + progress * p.fallSpeed) * size.height +
          progress * 200; // a bit of extra travel so they fully exit
      final dx = p.x * size.width +
          math.sin(progress * math.pi * 2 + p.rotation) * p.drift;
      final angle = p.rotation + progress * p.rotationSpeed;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(angle);
      paint.color = p.color;

      switch (p.shape) {
        case 1:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case 2:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.6,
              height: p.size * 0.4,
            ),
            paint,
          );
          break;
        default:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size,
            ),
            paint,
          );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
