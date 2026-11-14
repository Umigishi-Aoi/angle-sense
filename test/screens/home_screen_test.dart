import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/app/route_observer.dart';
import 'package:hinge_angle_game/screens/home_screen.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:hinge_angle_game/ui/retro_theme.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

void main() {
  // 自己ベストの保存先は、テストごとに空のメモリ実装へ差し替える。
  setUp(useInMemoryPrefs);

  testWidgets('ホームとバトル設定が内側の画面（951x669）に収まる', (tester) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = AppSettings();
    final provider = FakeAngleProvider()..latestAngle = 45;
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: HomeScreen(
            angleProvider: provider,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('バトル（2〜10人）'));
    await tester.pumpAndSettle();
    expect(find.text('2 人'), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.text('＋'));
      await tester.pump();
    }
    await tester.pump();
    expect(find.text('10 人'), findsOneWidget); // 上限
    expect(tester.takeException(), isNull);
  });

  testWidgets('バトル設定からホームに戻っても、ホームのボタンが効く', (tester) async {
    // didPopNext の setState が Future を返すとアサーションで Navigator がロックされた（2026-11-09）。
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          navigatorObservers: [routeObserver],
          home: HomeScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('バトル（2〜10人）'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('バトル（2〜10人）'));
    await tester.pumpAndSettle();
    expect(find.text('2 人'), findsOneWidget);
  });

  testWidgets('ホームに今の角度の絵を出す', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          home: HomeScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home_preview')), findsOneWidget);
  });

  testWidgets('ひとり・バトルへ入るときは横スライドでなくフェードで切り替える', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      AppServices(
        settings: settings,
        feedback: RecordingFeedback(settings),
        bestScores: inMemoryBestScores(),
        child: MaterialApp(
          theme: Retro.theme(),
          home: HomeScreen(
            angleProvider: FakeAngleProvider()..latestAngle = 45,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['バトル（2〜10人）', 'ひとりで（5問）']) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100)); // 切り替えの途中
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      if (label.startsWith('バトル')) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }
    // ゲームを閉じる（タイマーを残さない）
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'やめる'));
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
