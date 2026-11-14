import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';
import '../l10n/l10n.dart';
import '../ui/retro_theme.dart';
import 'angle_reveal.dart';

/// バトルの「感覚のズレ」図。
///
/// お題は人ごとにちがうので、角度そのものではなく「お題からのズレ」（実際 − お題）を
/// 1本の物差しに並べる。真ん中がピタッ、右が折りすぎ、左が足りない。
/// ±[range]° を超えたズレは端に寄せ、矢印で「はみ出し」を示す。
class const DeviationChart({
  super.key,

  /// (表示名, 結果) を上から順に並べる。
  required final List<(String, RoundResult)> rows,

  /// 読み上げ用の名前（[rows] と同じ順）。表示名が略語（英語の R1 など）のときに渡す。
  /// null なら表示名をそのまま読む。
  final List<String>? spokenNames,
  final double range = 30,
}) extends StatelessWidget {
  /// 符号つきのズレ。+ = 折りすぎ、− = 足りない。計測なしは null。
  static double? signedError(RoundResult r) =>
      r.actual == null ? null : r.actual! - r.target;

  /// 1 行の読み上げ。点の位置と色（判定）は見えないので、言葉にする。
  /// 例: 「P1、+4.0° 折りすぎ、GREAT」「P2、計測なし、MISS」
  static String semanticsLabel(
    AppLocalizations l10n,
    String name,
    RoundResult r,
  ) {
    final err = signedError(r);
    final judgement = r.judgement.label;
    if (err == null) return l10n.chartRowNoReading(name, judgement);
    final signed = AngleZoom.signedLabel(r.target, r.actual!);
    final side = signed.startsWith('±')
        ? l10n.sideSpotOn
        : (err > 0 ? l10n.sideOver : l10n.sideUnder);
    return l10n.chartRowLabel(name, signed, side, judgement);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final retro = context.retroColors;
    final l10n = context.l10n;
    // 文字を大きくする設定では、行の高さも同じ割合で広げる（名前が上下で切れないように）。
    final rowHeight = MediaQuery.textScalerOf(
      context,
    ).scale(_rowHeight).clamp(_rowHeight, double.infinity);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 見出しと目盛りは図の読み方なので読み上げない（各行の説明に向きを含める）。
        ExcludeSemantics(
          child: Row(
            children: [
              const SizedBox(width: _labelWidth),
              Expanded(
                // 文字を大きくする設定で 1 行に入らないときは折り返す
                // （1 行に入るときは両端と真ん中に並ぶので、Spacer 2 つと同じ見た目）。
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(l10n.chartUnder, style: TextStyle(color: retro.dim)),
                    Text(
                      l10n.chartSpotOn,
                      style: TextStyle(color: scheme.primary),
                    ),
                    Text(l10n.chartOver, style: TextStyle(color: retro.dim)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (final (i, (name, result)) in rows.indexed)
          Semantics(
            container: true,
            label: semanticsLabel(l10n, spokenNames?[i] ?? name, result),
            excludeSemantics: true,
            child: _row(l10n, name, result, rowHeight, scheme, retro),
          ),
        const SizedBox(height: 4),
        ExcludeSemantics(
          child: Row(
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
        ),
      ],
    );
  }

  static const _labelWidth = 84.0; // 名前 6 文字が 1 行に入る幅
  static const _rowHeight = 30.0;
  static const _dot = 14.0;

  Widget _row(
    AppLocalizations l10n,
    String name,
    RoundResult result,
    double rowHeight,
    ColorScheme scheme,
    RetroColors retro,
  ) {
    final err = signedError(result);
    return SizedBox(
      height: rowHeight,
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
                    top: rowHeight / 2 - 1,
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
                        l10n.noReading,
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
                      top: (rowHeight - _dot) / 2,
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
