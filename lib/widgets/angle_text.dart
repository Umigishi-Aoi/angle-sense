import 'package:material_ui/material_ui.dart';

/// 大きく角度を表示する。
class const AngleText(
  final num degrees, {
  super.key,
  final double fontSize = 120,
  final Color? color,

  /// この文字列の幅を先に確保し、数字はその中で左に寄せる。
  /// 桁数が変わっても幅が変わらないので、横に並べた絵がずれない。
  /// null なら数字の幅だけを取る。
  final String? reserveWidthFor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      // ドットフォントは Regular のみ。太字にすると擬似太字でにじむので指定しない。
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final text = Text('${degrees.round()}°', style: style);
    final reserve = reserveWidthFor;
    if (reserve == null) return text;
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        // 幅を取るためだけの見えない文字（読み上げにも出さない）。
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Text(reserve, style: style),
        ),
        text,
      ],
    );
  }
}
