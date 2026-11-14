import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/ui/retro_theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('テーマに RetroColors を登録し、配色は元の値のまま', () {
    final theme = Retro.theme();
    final scheme = theme.colorScheme;
    expect(theme.extension<RetroColors>(), RetroColors.retro);
    expect(scheme.primary, Retro.yellow);
    expect(scheme.secondary, Retro.cyan);
    // tertiary は指定をやめたが、secondary と同じ色のまま。
    expect(scheme.tertiary, Retro.cyan);
    expect(scheme.surface, Retro.bg);
    expect(scheme.onSurface, Retro.text);
    expect(scheme.outline, Retro.line);
    expect(scheme.outlineVariant, Retro.line);
    expect(scheme.error, Retro.red);
  });

  test('判定の色は PERFECT=黄・GREAT=水色・GOOD=緑・MISS=赤', () {
    const c = RetroColors.retro;
    expect(c.judgement(Judgement.perfect), Retro.yellow);
    expect(c.judgement(Judgement.great), Retro.cyan);
    expect(c.judgement(Judgement.good), Retro.green);
    expect(c.judgement(Judgement.miss), Retro.red);
    expect(c.blindBackground, Colors.black);
    expect(c.blindText, Colors.white70);
    expect(c.blindIcon, Colors.white54);
    expect(c.dim, Retro.dim);
  });

  test('copyWith は指定した色だけ変える', () {
    const c = RetroColors.retro;
    final changed = c.copyWith(miss: const Color(0xFF000001));
    expect(changed.miss, const Color(0xFF000001));
    expect(changed.copyWith(miss: c.miss), c);
    expect(c.copyWith(), c);
  });

  test('lerp は両端で元の色・途中は色ごとに混ぜる', () {
    const a = RetroColors.retro;
    final b = a.copyWith(
      dim: Colors.black,
      perfect: Colors.black,
      blindText: Colors.black,
    );
    expect(a.lerp(b, 0), a);
    expect(a.lerp(b, 1), b);
    expect(a.lerp(null, 0.5), a);
    final mid = a.lerp(b, 0.5);
    expect(mid.dim, Color.lerp(Retro.dim, Colors.black, 0.5));
    expect(mid.perfect, Color.lerp(Retro.yellow, Colors.black, 0.5));
    expect(mid.great, a.great); // 同じ色どうしは変わらない
  });

  testWidgets('テーマに無いときは既定の配色を返す', (tester) async {
    late RetroColors colors;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            colors = context.retroColors;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(colors, RetroColors.retro);
  });

  testWidgets('動きを控える設定は disableAnimations と reduceMotion の両方を見る', (
    tester,
  ) async {
    Future<bool> read(MediaQueryData Function(MediaQueryData) edit) async {
      late bool reduce;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              MediaQuery(data: edit(MediaQuery.of(context)), child: child!),
          home: Builder(
            builder: (context) {
              reduce = context.reduceMotion;
              return const SizedBox();
            },
          ),
        ),
      );
      return reduce;
    }

    expect(await read((d) => d), isFalse);
    expect(await read((d) => d.copyWith(disableAnimations: true)), isTrue);
    expect(await read((d) => d.copyWith(reduceMotion: true)), isTrue);
  });
}
