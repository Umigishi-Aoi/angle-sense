import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';
import '../ui/retro_theme.dart';

/// 判定の文字を出すときの演出。
/// - PERFECT: ドットの紙吹雪が飛び散り、文字が大きく弾んで戻る
/// - GREAT: 小さめの紙吹雪と、軽い弾み
/// - GOOD / MISS: 演出なし（文字だけ）
class JudgementBurst extends StatefulWidget {
  const JudgementBurst({
    super.key,
    required this.judgement,
    required this.child,
  });

  final Judgement judgement;
  final Widget child;

  /// 紙吹雪の粒の数（演出なしは 0）。
  static int particleCount(Judgement j) => switch (j) {
    Judgement.perfect => 28,
    Judgement.great => 12,
    _ => 0,
  };

  @override
  State<JudgementBurst> createState() => _JudgementBurstState();
}

class _JudgementBurstState extends State<JudgementBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final List<_Particle> _particles = _makeParticles();

  List<_Particle> _makeParticles() {
    final n = JudgementBurst.particleCount(widget.judgement);
    final rnd = math.Random(widget.judgement.index * 7919 + n);
    const colors = [Retro.yellow, Retro.cyan, Colors.white];
    return [
      for (var i = 0; i < n; i++)
        _Particle(
          angle: -math.pi * (0.1 + 0.8 * rnd.nextDouble()), // 上向き中心に散る
          speed: 120 + 160 * rnd.nextDouble(),
          size: (rnd.nextBool() ? 3 : 2) * Retro.px,
          color: colors[i % colors.length],
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final big = widget.judgement == Judgement.perfect;
    final pop = switch (widget.judgement) {
      Judgement.perfect => 0.6,
      Judgement.great => 0.25,
      _ => 0.0,
    };
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // 最初の 40% で大きくなって戻る
        final t = (_c.value / 0.4).clamp(0.0, 1.0);
        final scale = 1 + pop * math.sin(t * math.pi);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_particles.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BurstPainter(
                      _particles,
                      _c.value,
                      gravity: big ? 380 : 300,
                    ),
                  ),
                ),
              ),
            Transform.scale(scale: scale, child: child),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.particles, this.t, {required this.gravity});

  final List<_Particle> particles;
  final double t;
  final double gravity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final secs = t * 1.1;
    final paint = Paint()..isAntiAlias = false;
    for (final p in particles) {
      final pos =
          center +
          Offset(
            math.cos(p.angle) * p.speed * secs,
            math.sin(p.angle) * p.speed * secs + 0.5 * gravity * secs * secs,
          );
      // 後半で消える
      final alpha = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: alpha);
      // ドットに揃える（にじませない）
      final snapped = Offset(
        (pos.dx / Retro.px).roundToDouble() * Retro.px,
        (pos.dy / Retro.px).roundToDouble() * Retro.px,
      );
      canvas.drawRect(
        Rect.fromCenter(center: snapped, width: p.size, height: p.size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
