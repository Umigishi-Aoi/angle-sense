import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';
import '../ui/retro_theme.dart';

/// バトルの「感覚のズレ」図。
///
/// お題は人ごとにちがうので、角度そのものではなく「お題からのズレ」（実際 − お題）を
/// 1本の物差しに並べる。真ん中がピタッ、右が折りすぎ、左が足りない。
/// ±[range]° を超えたズレは端に寄せ、矢印で「はみ出し」を示す。
class const DeviationChart({
  super.key,

  /// (表示名, 結果) を上から順に並べる。
  required final List<(String, RoundResult)> rows,
  final double range = 30,
}) extends StatelessWidget {
  /// 符号つきのズレ。+ = 折りすぎ、− = 足りない。計測なしは null。
  static double? signedError(RoundResult r) =>
      r.actual == null ? null : r.actual! - r.target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final retro = context.retroColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: _labelWidth),
            Expanded(
              child: Row(
                children: [
                  Text('← 足りない', style: TextStyle(color: retro.dim)),
                  const Spacer(),
                  Text('ピタッ', style: TextStyle(color: scheme.primary)),
                  const Spacer(),
                  Text('折りすぎ →', style: TextStyle(color: retro.dim)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final (name, result) in rows) _row(name, result, scheme, retro),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: _labelWidth),
            Expanded(
              child: Row(
                children: [
                  Text(
                    '-${range.round()}°',
                    style: TextStyle(color: retro.dim, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '+${range.round()}°',
                    style: TextStyle(color: retro.dim, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const _labelWidth = 84.0; // 名前 6 文字が 1 行に入る幅
  static const _rowHeight = 30.0;
  static const _dot = 14.0;

  Widget _row(
    String name,
    RoundResult result,
    ColorScheme scheme,
    RetroColors retro,
  ) {
    final err = signedError(result);
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final children = <Widget>[
                  // 物差し
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _rowHeight / 2 - 1,
                    height: 2,
                    child: ColoredBox(color: scheme.outline),
                  ),
                  // ピタッの線
                  Positioned(
                    left: w / 2 - 1,
                    width: 2,
                    top: 2,
                    bottom: 2,
                    child: ColoredBox(color: scheme.primary),
                  ),
                ];
                if (err == null) {
                  children.add(
                    Center(
                      child: Text(
                        '計測なし',
                        style: TextStyle(color: scheme.error, fontSize: 14),
                      ),
                    ),
                  );
                } else {
                  final clamped = err.clamp(-range, range);
                  final over = err.abs() > range;
                  final x = (clamped + range) / (2 * range) * (w - _dot);
                  children.add(
                    Positioned(
                      left: x,
                      top: (_rowHeight - _dot) / 2,
                      width: _dot,
                      height: _dot,
                      child: ColoredBox(
                        key: ValueKey('dev_$name'),
                        color: retro.judgement(result.judgement),
                      ),
                    ),
                  );
                  if (over) {
                    children.add(
                      Positioned(
                        left: err > 0 ? null : 0,
                        right: err > 0 ? 0 : null,
                        top: -8,
                        // 文字の ▶ は絵文字で描かれることがあるのでアイコンにする。
                        child: Icon(
                          err > 0 ? Icons.arrow_right : Icons.arrow_left,
                          key: ValueKey('over_$name'),
                          size: 18,
                          color: scheme.error,
                        ),
                      ),
                    );
                  }
                }
                return Stack(clipBehavior: Clip.none, children: children);
              },
            ),
          ),
        ],
      ),
    );
  }
}
