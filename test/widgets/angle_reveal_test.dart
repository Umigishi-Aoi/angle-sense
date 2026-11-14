import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/widgets/angle_reveal.dart';
import 'package:material_ui/material_ui.dart';

/// [of] の中の CustomPaint の painter（今のフレームのもの）。
CustomPainter painterIn(WidgetTester tester, Finder of) => tester
    .widget<CustomPaint>(
      find.descendant(of: of, matching: find.byType(CustomPaint)),
    )
    .painter!;

/// 動きを控える設定（iOS の「視差効果を減らす」）にした MaterialApp。
Widget reducedMotionApp(Widget home) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(reduceMotion: true),
    child: child!,
  ),
  home: home,
);

void main() {
  test('ズレの表示は符号つき（+ = 大きい、− = 小さい）', () {
    expect(AngleZoom.signedLabel(30, 34), '+4.0°');
    expect(AngleZoom.signedLabel(30, 26), '−4.0°');
    expect(AngleZoom.signedLabel(30, 30.02), '±0.0°');
  });

  testWidgets('拡大図は高さが足りなくても文字を残して縮む', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 150,
            height: 90,
            child: AngleZoom(target: 30, actual: 34),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('+4.0°'), findsOneWidget);
  });

  group('shouldRepaint', () {
    testWidgets('見本の絵は色が変わったら描き直す', (tester) async {
      Future<CustomPainter> pump(Color color) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnglePreview(target: 40, color: color),
          ),
        );
        return painterIn(tester, find.byType(AnglePreview));
      }

      final a = await pump(const Color(0xFF000001));
      final same = await pump(const Color(0xFF000001));
      final b = await pump(const Color(0xFF000002));
      expect(same.shouldRepaint(a), isFalse);
      expect(b.shouldRepaint(a), isTrue);
    });

    testWidgets('答え合わせの絵は最終の角度（finalActual）が変われば描き直す', (tester) async {
      // 最初のフレームは振り上げ前（actual × 0 = 0）なので、違うのは finalActual だけ。
      Future<CustomPainter> pump(double actual) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AngleReveal(
              key: ValueKey(actual),
              target: 30,
              actual: actual,
            ),
          ),
        );
        return painterIn(tester, find.byType(AngleReveal));
      }

      final a = await pump(20);
      final b = await pump(40);
      expect(b.shouldRepaint(a), isTrue);
      await tester.pumpWidget(const SizedBox()); // タイマーを残さない
    });

    testWidgets('答え合わせの絵はテーマの色が変われば描き直す', (tester) async {
      Future<CustomPainter> pump(Color primary) async {
        await tester.pumpWidget(
          MaterialApp(
            themeAnimationDuration: Duration.zero, // 色をすぐ切り替える
            theme: ThemeData(
              colorScheme: ColorScheme.dark(primary: primary),
            ),
            home: const AngleReveal(target: 30, actual: null),
          ),
        );
        return painterIn(tester, find.byType(AngleReveal));
      }

      final a = await pump(const Color(0xFF000001));
      final b = await pump(const Color(0xFF000002));
      expect(b.shouldRepaint(a), isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('拡大図は色が変われば描き直す', (tester) async {
      Future<CustomPainter> pump(Color secondary) async {
        await tester.pumpWidget(
          MaterialApp(
            themeAnimationDuration: Duration.zero, // 色をすぐ切り替える
            theme: ThemeData(
              colorScheme: ColorScheme.dark(secondary: secondary),
            ),
            home: const AngleZoom(target: 30, actual: 34),
          ),
        );
        return painterIn(tester, find.byType(AngleZoom));
      }

      final a = await pump(const Color(0xFF000001));
      final same = await pump(const Color(0xFF000001));
      final b = await pump(const Color(0xFF000002));
      expect(same.shouldRepaint(a), isFalse);
      expect(b.shouldRepaint(a), isTrue);
    });
  });

  testWidgets('動きを控える設定では、最初のフレームから最後の形で描き、そのあと完了を知らせる', (
    tester,
  ) async {
    var completed = 0;
    Future<void> pumpReveal(Widget Function(Widget) app) => tester.pumpWidget(
      app(
        AngleReveal(
          target: 30,
          actual: 40,
          onCompleted: () => completed++,
        ),
      ),
    );

    // 最後まで動かしたときの絵
    await pumpReveal((home) => MaterialApp(home: home));
    await tester.pumpAndSettle();
    expect(completed, 1);
    final animatedEnd = painterIn(tester, find.byType(AngleReveal));
    await tester.pumpWidget(const SizedBox());

    await pumpReveal(reducedMotionApp);
    final firstFrame = painterIn(tester, find.byType(AngleReveal));
    // 違うところが無ければ描き直し不要＝同じ絵。
    expect(firstFrame.shouldRepaint(animatedEnd), isFalse);
    expect(completed, 1); // build 中には呼ばない
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(completed, 2);
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('読み上げ', () {
    testWidgets('答え合わせの図は目標とあなたの角度を読み上げる', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: AngleReveal(target: 45, actual: 41.4)),
      );
      expect(
        find.bySemanticsLabel('答え合わせの図。目標 45°、あなた 41°'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        const MaterialApp(home: AngleReveal(target: 45, actual: null)),
      );
      expect(
        find.bySemanticsLabel('答え合わせの図。目標 45°、あなた 計測なし'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox()); // タイマーを残さない
      handle.dispose();
    });

    testWidgets('見本の絵は説明があるときだけ読み上げる', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: AnglePreview(target: 40, semanticsLabel: 'お題 40° の見本の図'),
        ),
      );
      expect(find.bySemanticsLabel('お題 40° の見本の図'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('拡大図は見出しと数字をまとめて 1 つで読み上げる', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: AngleZoom(target: 30, actual: 34)),
      );
      expect(find.bySemanticsLabel('拡大図、ズレ +4.0°'), findsOneWidget);
      expect(find.bySemanticsLabel('拡大'), findsNothing);
      handle.dispose();
    });
  });

  testWidgets('拡大図は文字 2 倍で高さが文字より低くても、はみ出さずに縮む', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Center(
          child: SizedBox(
            width: 150,
            height: 30,
            child: AngleZoom(target: 30, actual: 34),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('+4.0°'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AngleZoom)).height,
      lessThanOrEqualTo(30),
    );
  });
}
