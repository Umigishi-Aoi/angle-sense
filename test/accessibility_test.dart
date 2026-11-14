import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/screens/battle_screen.dart';
import 'package:hinge_angle_game/screens/game_screen.dart';
import 'package:hinge_angle_game/screens/home_screen.dart';
import 'package:hinge_angle_game/screens/result_screen.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:hinge_angle_game/ui/retro_theme.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';

/// 画面の大きさ（論理 px）と、端末のノッチなどの余白。
typedef _Screen = (String, Size, FakeViewPadding);

const _screens = <_Screen>[
  (
    '普通の iPhone の横向き 874x402',
    Size(874, 402),
    FakeViewPadding(left: 62, right: 62, bottom: 21),
  ),
  ('Duo の内側 951x669', Size(951, 669), FakeViewPadding.zero),
];

void _setScreen(WidgetTester tester, _Screen s) {
  tester.view.physicalSize = s.$2;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = s.$3;
  addTearDown(tester.view.reset);
}

/// 本番と同じテーマで、文字の大きさの設定を [scale] 倍にしたアプリ。
Widget _app(Widget home, {double scale = 1}) {
  final settings = AppSettings();
  return AppServices(
    settings: settings,
    feedback: RecordingFeedback(settings),
    bestScores: inMemoryBestScores(),
    child: MaterialApp(
      theme: Retro.theme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

FakeAngleProvider _provider() => FakeAngleProvider()..latestAngle = 40;

const _results = [
  RoundResult(target: 45, actual: 41),
  RoundResult(target: 30, actual: 30.5),
  RoundResult(target: 60, actual: null),
  RoundResult(target: 20, actual: 28),
  RoundResult(target: 80, actual: 50),
];

Future<void> _pumpHome(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    _app(HomeScreen(angleProvider: _provider()), scale: scale),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpGame(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    _app(GameScreen(angleProvider: _provider()), scale: scale),
  );
  await tester.pump();
}

Future<void> _pumpResult(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    _app(
      ResultScreen(
        results: _results,
        totalScore: 210,
        rank: Rank.b,
        angleProvider: _provider(),
        bestScore: 300,
      ),
      scale: scale,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBattleSetup(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    _app(BattleSetupScreen(angleProvider: _provider()), scale: scale),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBattle(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    _app(
      BattleScreen(angleProvider: _provider(), playerCount: 2),
      scale: scale,
    ),
  );
  await tester.pumpAndSettle();
}

/// バトルの順番の画面から 2 人分を遊んで、結果発表まで進める。
/// [check] は各段階で呼ぶ（はみ出しの確認など）。
Future<void> _playBattle(
  WidgetTester tester,
  void Function(String step) check,
) async {
  for (var i = 0; i < 2; i++) {
    await tester.ensureVisible(find.text('スタート'));
    await tester.tap(find.text('スタート'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    check('${i + 1}人目の答え合わせ');
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
  }
  expect(find.text('結果発表'), findsOneWidget);
}

/// 遊んでいる途中の画面を片づける（タイマーを残さない）。
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

void main() {
  // 文字の幅を本番に近づけるため、同梱のドットフォントを読み込む（テスト既定の四角い字は幅が広い）。
  setUpAll(() async {
    final loader = FontLoader(Retro.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/DotGothic16-Regular.ttf'));
    await loader.load();
  });
  setUp(useInMemoryPrefs);

  for (final screen in _screens) {
    group('文字 2 倍でもはみ出さない・${screen.$1}', () {
      void noOverflow(WidgetTester tester, String step) =>
          expect(tester.takeException(), isNull, reason: step);

      testWidgets('ホーム', (tester) async {
        _setScreen(tester, screen);
        await _pumpHome(tester, 2);
        noOverflow(tester, 'ホーム');
      });

      testWidgets('ゲーム（お題→暗転→答え合わせ）', (tester) async {
        _setScreen(tester, screen);
        await _pumpGame(tester, 2);
        noOverflow(tester, 'お題');
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 300));
        noOverflow(tester, '暗転');
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        noOverflow(tester, '答え合わせ');
        await _dispose(tester);
      });

      testWidgets('結果', (tester) async {
        _setScreen(tester, screen);
        await _pumpResult(tester, 2);
        noOverflow(tester, '結果');
      });

      testWidgets('バトル設定', (tester) async {
        _setScreen(tester, screen);
        await _pumpBattleSetup(tester, 2);
        noOverflow(tester, 'バトル設定');
      });

      testWidgets('バトルの順番→結果発表', (tester) async {
        _setScreen(tester, screen);
        await _pumpBattle(tester, 2);
        noOverflow(tester, '順番');
        await _playBattle(tester, (step) => noOverflow(tester, step));
        noOverflow(tester, '結果発表');
      });
    });
  }

  group('アクセシビリティの指針（タップ領域・ラベル・文字のコントラスト）', () {
    Future<void> meetsAll(WidgetTester tester) async {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }

    for (final screen in _screens) {
      group(screen.$1, () {
        testWidgets('ホーム', (tester) async {
          _setScreen(tester, screen);
          final handle = tester.ensureSemantics();
          await _pumpHome(tester, 1);
          await meetsAll(tester);
          handle.dispose();
        });

        testWidgets('ゲーム（お題）', (tester) async {
          _setScreen(tester, screen);
          final handle = tester.ensureSemantics();
          await _pumpGame(tester, 1);
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byKey(const ValueKey('target_preview')), findsOneWidget);
          await meetsAll(tester);
          await _dispose(tester);
          handle.dispose();
        });

        testWidgets('結果', (tester) async {
          _setScreen(tester, screen);
          final handle = tester.ensureSemantics();
          await _pumpResult(tester, 1);
          await meetsAll(tester);
          handle.dispose();
        });

        testWidgets('バトル設定', (tester) async {
          _setScreen(tester, screen);
          final handle = tester.ensureSemantics();
          await _pumpBattleSetup(tester, 1);
          await meetsAll(tester);
          handle.dispose();
        });

        testWidgets('バトルの結果発表', (tester) async {
          _setScreen(tester, screen);
          final handle = tester.ensureSemantics();
          await _pumpBattle(tester, 1);
          await _playBattle(tester, (_) {});
          await meetsAll(tester);
          handle.dispose();
        });
      });
    }
  });
}
