import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 答え合わせ: 折りたたみを横から見た図。左半分（固定の面）を水平に置き、右半分を
/// 0°（平ら）から実際の角度まで持ち上げて、目標線と重ねる。[actual] が null（計測なし）なら目標線だけ描く。
class AngleReveal extends StatefulWidget {
  const AngleReveal({
    super.key,
    required this.target,
    required this.actual,
    this.duration = const Duration(milliseconds: 1400),
    this.onCompleted,
  });

  final double target;
  final double? actual;
  final Duration duration;
  final VoidCallback? onCompleted;

  @override
  State<AngleReveal> createState() => _AngleRevealState();
}

class _AngleRevealState extends State<AngleReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onCompleted?.call();
        })
        ..forward();

  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: _ArcPainter.cols / _ArcPainter.rows,
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) => CustomPaint(
          painter: _ArcPainter(
            target: widget.target,
            actual: widget.actual == null
                ? null
                : widget.actual! * _sweep.value,
            showDiff: _controller.isCompleted && widget.actual != null,
            finalActual: widget.actual,
            targetColor: scheme.primary,
            actualColor: scheme.tertiary,
            gridColor: scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

/// お題の見本: 答え合わせと同じ横から見た図に、お題の線だけを描く（動かない）。
/// ホームでは今の角度を [color] で描いて、線が動く見本として使う。
class AnglePreview extends StatelessWidget {
  const AnglePreview({super.key, required this.target, this.color});

  final double target;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: _ArcPainter.cols / _ArcPainter.rows,
      child: CustomPaint(
        painter: _ArcPainter(
          target: target.clamp(0, _ArcPainter.maxDrawDeg).toDouble(),
          actual: null,
          showDiff: false,
          finalActual: null,
          targetColor: color ?? scheme.primary,
          actualColor: scheme.tertiary,
          gridColor: scheme.outlineVariant,
        ),
      ),
    );
  }
}

/// 答え合わせの拡大図: 2 本の線の先端あたりを大きく描く。
/// 誤差が小さいと元の図では線が重なって、どちらが上か分からないため。
class AngleZoom extends StatelessWidget {
  const AngleZoom({super.key, required this.target, required this.actual});

  final double target;
  final double actual;

  /// 符号つきのズレ（+ = 大きい、− = 小さい）。例: +4.0°
  static String signedLabel(double target, double actual) {
    final d = actual - target;
    final s = d.abs().toStringAsFixed(1);
    if (s == '0.0') return '±0.0°';
    return '${d > 0 ? '+' : '−'}$s°';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('拡大', style: TextStyle(fontSize: 14, color: scheme.outline)),
        const SizedBox(height: 4),
        // 横向きの iPhone では高さが足りないので、絵のほうを縮めて文字を残す。
        Flexible(
          child: AspectRatio(
            aspectRatio: _ZoomPainter.cols / _ZoomPainter.rows,
            child: CustomPaint(
              painter: _ZoomPainter(
                target: target,
                actual: actual.clamp(0, _ArcPainter.maxDrawDeg).toDouble(),
                targetColor: scheme.primary,
                actualColor: scheme.tertiary,
                gridColor: scheme.outlineVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          signedLabel(target, actual),
          key: const ValueKey('signed_error'),
          style: TextStyle(fontSize: 24, color: scheme.tertiary),
        ),
      ],
    );
  }
}

/// 半径 100 マスの円の、2 本の線の先端付近（30×20 マス）だけを切り出して描く。
class _ZoomPainter extends CustomPainter {
  _ZoomPainter({
    required this.target,
    required this.actual,
    required this.targetColor,
    required this.actualColor,
    required this.gridColor,
  });

  final double target;
  final double actual;
  final Color targetColor;
  final Color actualColor;
  final Color gridColor;

  static const cols = 30;
  static const rows = 20;
  static const radius = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = math
        .max(1, math.min(size.width / cols, size.height / rows).floor())
        .toDouble();
    final origin = Offset(
      (size.width - cols * cell) / 2,
      (size.height - rows * cell) / 2,
    );
    // 2 本の線の真ん中の向きで、円周より少し内側を窓の中心にする。
    final mid = (target + actual) / 2 * math.pi / 180;
    final center = Offset(math.cos(mid), -math.sin(mid)) * (radius - 5);
    Offset world(num x, num y) =>
        center + Offset(x + 0.5 - cols / 2, y + 0.5 - rows / 2);
    double degOf(Offset p) => math.atan2(-p.dy, p.dx) * 180 / math.pi;

    final lo = math.min(target, actual);
    final hi = math.max(target, actual);
    final cells = <(int, int), Color>{};
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final p = world(x, y);
        final dist = p.distance;
        final deg = degOf(p);
        if (dist < radius && deg >= lo && deg <= hi) {
          cells[(x, y)] = actualColor.withValues(alpha: 0.35);
        }
        if ((dist - radius).abs() < 0.55) cells[(x, y)] = gridColor;
      }
    }
    // 1° ごとの目盛り（5° ごとは長く）
    for (var d = (lo - 15).floor(); d <= (hi + 15).ceil(); d++) {
      _ray(
        cells,
        world,
        d.toDouble(),
        radius - (d % 5 == 0 ? 3 : 1.5),
        radius,
        gridColor,
      );
    }
    _ray(cells, world, target, radius - 30, radius - 0.5, targetColor);
    _ray(cells, world, actual, radius - 30, radius - 0.5, actualColor);

    final paint = Paint()..isAntiAlias = false;
    cells.forEach((k, color) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx + k.$1 * cell,
          origin.dy + k.$2 * cell,
          cell,
          cell,
        ),
        paint,
      );
    });
  }

  void _ray(
    Map<(int, int), Color> cells,
    Offset Function(num, num) world,
    double deg,
    double r0,
    double r1,
    Color color,
  ) {
    final rad = deg * math.pi / 180;
    final dir = Offset(math.cos(rad), -math.sin(rad));
    final c0 = world(0, 0) - const Offset(0.5, 0.5); // 窓の左上（ワールド座標）
    for (var t = r0; t <= r1; t += 0.25) {
      final p = dir * t - c0;
      final x = p.dx.floor();
      final y = p.dy.floor();
      if (x >= 0 && x < cols && y >= 0 && y < rows) cells[(x, y)] = color;
    }
  }

  @override
  bool shouldRepaint(covariant _ZoomPainter old) =>
      old.target != target || old.actual != actual;
}

/// ドット絵風に描く: 56×32 マスの格子に塗りつぶした四角を並べる（アンチエイリアスなし）。
/// 0°=右に水平（平ら）→ 90°=真上（直角）。
class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.target,
    required this.actual,
    required this.showDiff,
    required this.finalActual,
    required this.targetColor,
    required this.actualColor,
    required this.gridColor,
  });

  final double target;
  final double? actual;
  final bool showDiff;
  final double? finalActual;
  final Color targetColor;
  final Color actualColor;
  final Color gridColor;

  static const cols = 56;
  static const rows = 32;
  static const radius = 30.0; // マス単位
  static const pivotX = 20.0; // 軸の位置（左に固定の面を描くぶん寄せる）
  static const maxDrawDeg = 100.0; // 直角を少し越えた値も見えるように

  @override
  void paint(Canvas canvas, Size size) {
    // 1 マスを整数の論理 px にして、にじまないようにする。
    final cell = math
        .max(1, math.min(size.width / cols, size.height / rows).floor())
        .toDouble();
    final origin = Offset(
      (size.width - cols * cell) / 2,
      (size.height - rows * cell) / 2,
    );
    final pivot = Offset(pivotX, rows.toDouble()); // 下端（マス単位）

    final cells = <(int, int), Color>{};

    // 外周の 1/4 円（0〜90°）と 10° ごとの目盛り
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final c = Offset(x + 0.5, y + 0.5) - pivot;
        final dist = c.distance;
        if (c.dx >= -0.5 && (dist - radius).abs() < 0.55)
          cells[(x, y)] = gridColor;
        // 誤差の範囲（扇形）
        if (showDiff && finalActual != null && dist < radius * 0.6) {
          final deg = math.atan2(-c.dy, c.dx) * 180 / math.pi;
          final shown = finalActual!
              .clamp(0, maxDrawDeg)
              .toDouble(); // 線と同じ所で止める
          final lo = math.min(target, shown);
          final hi = math.max(target, shown);
          if (deg >= lo && deg <= hi)
            cells[(x, y)] = actualColor.withValues(alpha: 0.35);
        }
      }
    }
    for (var d = 0; d <= 90; d += 10) {
      _ray(
        cells,
        pivot,
        d.toDouble(),
        radius - (d % 30 == 0 ? 3.5 : 2),
        radius,
        gridColor,
      );
    }
    // 固定の面（左半分。平らに置いたもう片方）
    _ray(cells, pivot, 180, 0, pivotX - 0.5, gridColor);

    _ray(cells, pivot, target, 0, radius - 0.5, targetColor);
    if (actual != null) {
      _ray(
        cells,
        pivot,
        actual!.clamp(0, maxDrawDeg).toDouble(),
        0,
        radius - 0.5,
        actualColor,
      );
    }
    // 回転の軸
    cells[(pivotX.toInt() - 1, rows - 1)] = gridColor;
    cells[(pivotX.toInt(), rows - 1)] = gridColor;

    final paint = Paint()..isAntiAlias = false;
    cells.forEach((k, color) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx + k.$1 * cell,
          origin.dy + k.$2 * cell,
          cell,
          cell,
        ),
        paint,
      );
    });
  }

  /// 0°=右（平ら）→ 90°=上（直角）→ 180°=左。r0〜r1 の範囲のマスを塗る。
  void _ray(
    Map<(int, int), Color> cells,
    Offset pivot,
    double deg,
    double r0,
    double r1,
    Color color,
  ) {
    final rad = deg * math.pi / 180;
    final dir = Offset(math.cos(rad), -math.sin(rad));
    for (var t = r0; t <= r1; t += 0.25) {
      final p = pivot + dir * t;
      final x = p.dx.floor();
      final y = math.min(rows - 1, p.dy.floor());
      if (x >= 0 && x < cols && y >= 0) cells[(x, y)] = color;
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.actual != actual || old.target != target || old.showDiff != showDiff;
}
