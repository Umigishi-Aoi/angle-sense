import 'package:flutter/material.dart';

/// 大きく角度を表示する。
class AngleText extends StatelessWidget {
  const AngleText(this.degrees, {super.key, this.fontSize = 120, this.color});

  final num degrees;
  final double fontSize;
  final Color? color;

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
