import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/l10n/l10n.dart';
import 'package:hinge_angle_game/screens/battle_screen.dart';
import 'package:hinge_angle_game/screens/home_screen.dart';
import 'package:hinge_angle_game/screens/result_screen.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';

void main() {
  group('普通の iPhone の横向き（874x402・左右にノッチ分の余白）', () {
    void phoneLandscape(WidgetTester tester) {
      tester.view.physicalSize = const Size(874, 402);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        left: 62,
        right: 62,
        bottom: 21,
      );
      addTearDown(tester.view.reset);
      useInMemoryPrefs();
    }

    testWidgets('ホーム→ひとりで5問→結果画面が崩れない', (tester) async {
      phoneLandscape(tester);
      final settings = AppSettings();
      final provider = FakeAngleProvider()..latestAngle = 40;
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: RecordingFeedback(settings),
          bestScores: inMemoryBestScores(),
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,

            home: HomeScreen(
              angleProvider: provider,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ひとりで（5問）'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton).last);
        await tester.pump();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('result_chart')), findsOneWidget);
    });

    testWidgets('バトル: 長い名前を入れても崩れない（文字数で切る）', (tester) async {
      phoneLandscape(tester);
      final settings = AppSettings();
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: RecordingFeedback(settings),
          bestScores: inMemoryBestScores(),
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,

            home: BattleScreen(
              angleProvider: FakeAngleProvider()..latestAngle = 40,
              playerCount: 2,
            ),
          ),
        ),
      );
      for (var i = 0; i < 2; i++) {
        await tester.enterText(
          find.byKey(const ValueKey('battle_name')),
          'ＷＷＷＷＷＷＷＷＷＷＷＷ',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('スタート'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('結果発表'), findsOneWidget);
      final limited = 'Ｗ' * BattleScreen.maxNameLength;
      expect(find.text(limited), findsWidgets);
      expect(find.text('ＷＷＷＷＷＷＷＷＷＷＷＷ'), findsNothing);
      for (final e in find.text(limited).evaluate()) {
        expect(e.size!.height, lessThan(40)); // 1 行に収まる
      }
    });

    testWidgets('バトル設定→10人→結果発表が崩れない', (tester) async {
      phoneLandscape(tester);
      final settings = AppSettings();
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: RecordingFeedback(settings),
          bestScores: inMemoryBestScores(),
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,

            home: BattleSetupScreen(
              angleProvider: FakeAngleProvider()..latestAngle = 40,
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.text('＋'));
        await tester.pump();
      }
      expect(find.bySemanticsLabel('10 人'), findsOneWidget);
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 10; i++) {
        await tester.tap(find.text('スタート'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      expect(find.text('結果発表'), findsOneWidget);
      expect(find.byKey(const ValueKey('dev_P10')), findsOneWidget);
      // 名前が1行に収まっている（縦に折り返していない）
      final names = find.textContaining('プレイヤー');
      expect(names, findsWidgets);
      for (final e in names.evaluate()) {
        expect(e.size!.height, lessThan(40));
      }
    });
  });
}
