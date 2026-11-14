import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../ui/retro_theme.dart';

/// 答え合わせ: 折りたたみを横から見た図。左半分（固定の面）を水平に置き、右半分を
/// 0°（平ら）から実際の角度まで持ち上げて、目標線と重ねる。[actual] が null（計測なし）なら目標線だけ描く。
class const AngleReveal({
  super.key,
  required final double target,
  required final double? actual,
  final Duration duration = const Duration(milliseconds: 1400),
  final VoidCallback? onCompleted,
}) extends StatefulWidget {
  @override
  State<AngleReveal> createState() => _AngleRevealState();
}

class _AngleRevealState()
    extends State<AngleReveal>
    with SingleTickerProviderStateMixin {
  /// 動きを控える設定のときの長さ。0 にすると build 中に完了通知が同期で走るので、
  /// 1 フレーム後に終わる程度の長さにする（一時停止中は TickerMode で止まるのも同じ）。
  static const _reducedDuration = Duration(milliseconds: 1);

  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: widget.duration,
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onCompleted?.call();
      });

  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  /// 動きを控えるときは、振り上げずに最初から最後の形で描く。
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = context.reduceMotion;
    if (_controller.isDismissed && !_controller.isAnimating) {
      _controller
        ..duration = _reduceMotion ? _reducedDuration : widget.duration
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actual = widget.actual;
    // 読み上げでは絵の代わりに、2 本の線の角度を伝える（動きの途中の角度は読まない）。
    return Semantics(
      container: true,
      image: true,
      label: context.l10n.revealFigureLabel(
        widget.target.round(),
        actual == null ? context.l10n.noReading : '${actual.round()}°',
      ),
      child: _figure(scheme),
    );
  }

  Widget _figure(ColorScheme scheme) {
    return AspectRatio(
      aspectRatio: _ArcPainter.cols / _ArcPainter.rows,
      // 振り上げの間は毎フレーム描き直すので、周り（凡例・判定の文字）を巻き込まないよう分ける。
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            final done = _reduceMotion || _controller.isCompleted;
            return CustomPaint(
              painter: _ArcPainter(
                target: widget.target,
                actual: widget.actual == null
                    ? null
                    : widget.actual! * (_reduceMotion ? 1.0 : _sweep.value),
                showDiff: done && widget.actual != null,
                finalActual: widget.actual,
                targetColor: scheme.primary,
                actualColor: scheme.secondary,
                gridColor: scheme.outlineVariant,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// お題の見本: 答え合わせと同じ横から見た図に、お題の線だけを描く（動かない）。
/// ホームでは今の角度を [color] で描いて、線が動く見本として使う。
class const AnglePreview({
  super.key,
  required final double target,
  final Color? color,

  /// 読み上げる説明。null なら絵は読み上げない（横の数字で伝わる場合など）。
  final String? semanticsLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final figure = AspectRatio(
      aspectRatio: _ArcPainter.cols / _ArcPainter.rows,
      child: CustomPaint(
        painter: _ArcPainter(
          target: target.clamp(0, _ArcPainter.maxDrawDeg).toDouble(),
          actual: null,
          showDiff: false,
          finalActual: null,
          targetColor: color ?? scheme.primary,
          actualColor: scheme.secondary,
          gridColor: scheme.outlineVariant,
        ),
      ),
    );
    final label = semanticsLabel;
    if (label == null) return figure;
    return Semantics(container: true, image: true, label: label, child: figure);
  }
}

/// 答え合わせの拡大図: 2 本の線の先端あたりを大きく描く。
/// 誤差が小さいと元の図では線が重なって、どちらが上か分からないため。
class const AngleZoom({
  super.key,
  required final double target,
  required final double actual,
}) extends StatelessWidget {
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
    // 読み上げは「拡大図、ズレ +4.0°」の 1 つにまとめる（見出しと数字を別々に読ませない）。
    return Semantics(
      container: true,
      label: context.l10n.zoomLabel(signedLabel(target, actual)),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final heading = Text(
            context.l10n.zoomHeading,
            // 枠線の色（outline）では背景とのコントラストが 2.36:1 と低いので、
            // 補足文字の色（dim、5.64:1）にする。
            style: TextStyle(fontSize: 14, color: context.retroColors.dim),
          );
          final value = Text(
            signedLabel(target, actual),
            key: const ValueKey('signed_error'),
            style: TextStyle(fontSize: 24, color: scheme.secondary),
          );
          final picture = CustomPaint(
            painter: _ZoomPainter(
              target: target,
              actual: actual.clamp(0, _ArcPainter.maxDrawDeg).toDouble(),
              targetColor: scheme.primary,
              actualColor: scheme.secondary,
              gridColor: scheme.outlineVariant,
            ),
          );
          final textHeight =
              _textHeight(context, heading) + _textHeight(context, value) + 8;
          if (c.maxHeight < textHeight && c.maxWidth.isFinite) {
            // 文字を大きくする設定などで文字だけでも高さに入らないときは、
            // 絵を幅いっぱいの大きさで作ってから全体を縮める（はみ出さないように）。
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  heading,
                  const SizedBox(height: 4),
                  SizedBox(
                    width: c.maxWidth,
                    height: c.maxWidth * _ZoomPainter.rows / _ZoomPainter.cols,
                    child: picture,
                  ),
                  const SizedBox(height: 4),
                  value,
                ],
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              heading,
              const SizedBox(height: 4),
              // 横向きの iPhone では高さが足りないので、絵のほうを縮めて文字を残す。
              Flexible(
                child: AspectRatio(
                  aspectRatio: _ZoomPainter.cols / _ZoomPainter.rows,
                  child: picture,
                ),
              ),
              const SizedBox(height: 4),
              value,
            ],
          );
        },
      ),
    );
  }

  /// [text] を今の文字の大きさの設定で 1 行に描いたときの高さ。
  static double _textHeight(BuildContext context, Text text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text.data,
        style: DefaultTextStyle.of(context).style.merge(text.style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}

/// 半径 100 マスの円の、2 本の線の先端付近（30×20 マス）だけを切り出して描く。
class _ZoomPainter({
  required final double target,
  required final double actual,
  required final Color targetColor,
  required final Color actualColor,
  required final Color gridColor,
}) extends CustomPainter {
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
      old.target != target ||
      old.actual != actual ||
      old.targetColor != targetColor ||
      old.actualColor != actualColor ||
      old.gridColor != gridColor;
}

/// ドット絵風に描く: 56×32 マスの格子に塗りつぶした四角を並べる（アンチエイリアスなし）。
/// 0°=右に水平（平ら）→ 90°=真上（直角）。
class _ArcPainter({
  required final double target,
  required final double? actual,
  required final bool showDiff,
  required final double? finalActual,
  required final Color targetColor,
  required final Color actualColor,
  required final Color gridColor,
}) extends CustomPainter {
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
        if (c.dx >= -0.5 && (dist - radius).abs() < 0.55) {
          cells[(x, y)] = gridColor;
        }
        // 誤差の範囲（扇形）
        if (showDiff && finalActual != null && dist < radius * 0.6) {
          final deg = math.atan2(-c.dy, c.dx) * 180 / math.pi;
          final shown = finalActual!
              .clamp(0, maxDrawDeg)
              .toDouble(); // 線と同じ所で止める
          final lo = math.min(target, shown);
          final hi = math.max(target, shown);
          if (deg >= lo && deg <= hi) {
            cells[(x, y)] = actualColor.withValues(alpha: 0.35);
          }
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
      old.actual != actual ||
      old.target != target ||
      old.showDiff != showDiff ||
      old.finalActual != finalActual ||
      old.targetColor != targetColor ||
      old.actualColor != actualColor ||
      old.gridColor != gridColor;
}
