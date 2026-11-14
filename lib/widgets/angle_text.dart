import 'package:material_ui/material_ui.dart';

/// 大きく角度を表示する。
class const AngleText(
  final num degrees, {
  super.key,
  final double fontSize = 120,
  final Color? color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '${degrees.round()}°',
      style: TextStyle(
        fontSize: fontSize,
        // ドットフォントは Regular のみ。太字にすると擬似太字でにじむので指定しない。
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
