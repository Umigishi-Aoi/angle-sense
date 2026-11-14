import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/l10n/l10n.dart';
import 'package:hinge_angle_game/screens/game_screen.dart';
import 'package:hinge_angle_game/services/angle_provider.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:hinge_angle_game/view_models/game_view_model.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// 「go」ボタンだけの画面からゲーム画面を push して開く（戻る操作を試せるように）。
Future<void> pumpGame(
  WidgetTester tester,
  AngleProvider provider, {
  Future<void> Function()? requestReview,
}) async {
  final settings = AppSettings();
  await tester.pumpWidget(
    AppServices(
      settings: settings,
      feedback: RecordingFeedback(settings),
      bestScores: inMemoryBestScores(),
      requestReview: requestReview,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,

        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(
                      angleProvider: provider,
                    ),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

/// 5 問を最後まで進めて結果画面を出す。
Future<void> playFive(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle(); // 答え合わせアニメ
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
  }
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
  await tester.pump(reviewRequestDelay);
}
