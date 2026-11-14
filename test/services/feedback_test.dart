import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/game/scoring.dart';
import 'package:hinge_angle_game/services/app_settings.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

// 効果音の読み込み・再生（GameFeedback.init / 準備済みでの play）は audioplayers の
// ネイティブ実装が要るのでここでは試さない（テスト環境に音声の実装が無い）。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 端末に送られた振動の種類（HapticFeedback.vibrate の引数）。
  late List<Object?> vibrations;

  setUp(() {
    vibrations = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrations.add(call.arguments);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
  });

  group('Sfx.forJudgement', () {
    test('判定ごとに同じ名前の効果音を選ぶ', () {
      expect(Sfx.forJudgement(Judgement.perfect), Sfx.perfect);
      expect(Sfx.forJudgement(Judgement.great), Sfx.great);
      expect(Sfx.forJudgement(Judgement.good), Sfx.good);
      expect(Sfx.forJudgement(Judgement.miss), Sfx.miss);
    });
  });

  group('GameFeedback.haptic', () {
    test('確定（lock）は強い振動', () async {
      GameFeedback.silent(AppSettings()).haptic(HapticPattern.lock);
      await Future<void>.delayed(Duration.zero);
      expect(vibrations, ['HapticFeedbackType.heavyImpact']);
    });

    test('結果（result）は中くらいの振動', () async {
      GameFeedback.silent(AppSettings()).haptic(HapticPattern.result);
      await Future<void>.delayed(Duration.zero);
      expect(vibrations, ['HapticFeedbackType.mediumImpact']);
    });

    test('振動をオフにした設定では振動しない', () async {
      final settings = AppSettings()..haptics = false;
      GameFeedback.silent(settings).haptic(HapticPattern.lock);
      await Future<void>.delayed(Duration.zero);
      expect(vibrations, isEmpty);
    });

    test('判定（judgement）は判定によらず結果の振動を 1 回', () async {
      GameFeedback.silent(AppSettings()).judgement(Judgement.miss);
      await Future<void>.delayed(Duration.zero);
      expect(vibrations, ['HapticFeedbackType.mediumImpact']);
    });
  });

  group('GameFeedback（音なし）', () {
    test('init しても準備しないので、play は何もしない', () async {
      final feedback = GameFeedback.silent(AppSettings());
      await feedback.init();
      expect(() => feedback.play(Sfx.lock), returnsNormally);
      await feedback.dispose();
    });

    test('init 前の play は何もしない（音ありの設定でも）', () {
      final feedback = GameFeedback(settings: AppSettings());
      expect(() => feedback.play(Sfx.perfect), returnsNormally);
    });
  });

  group('AppServicesContext', () {
    testWidgets('AppServices が無ければ無音・無振動の代わりを使う', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      );
      expect(ctx.settings.sound, isFalse);
      expect(ctx.settings.haptics, isFalse);
      expect(ctx.feedback.enableAudio, isFalse);
      await expectLater(ctx.requestReview(), completes);
    });

    testWidgets('AppServices があればそれを使う', (tester) async {
      final settings = AppSettings();
      final feedback = RecordingFeedback(settings);
      final bestScores = FakeBestScoreRepository();
      var reviews = 0;
      late BuildContext ctx;
      await tester.pumpWidget(
        AppServices(
          settings: settings,
          feedback: feedback,
          bestScores: bestScores,
          requestReview: () async => reviews++,
          child: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ctx.settings, same(settings));
      expect(ctx.feedback, same(feedback));
      expect(ctx.bestScores, same(bestScores));
      await ctx.requestReview();
      expect(reviews, 1);
    });

    test('updateShouldNotify は中身が入れ替わったときだけ true', () {
      final settings = AppSettings();
      final feedback = GameFeedback.silent(settings);
      final bestScores = FakeBestScoreRepository();
      AppServices services({AppSettings? s}) => AppServices(
        settings: s ?? settings,
        feedback: feedback,
        bestScores: bestScores,
        child: const SizedBox(),
      );
      expect(services().updateShouldNotify(services()), isFalse);
      expect(
        services().updateShouldNotify(services(s: AppSettings())),
        isTrue,
      );
    });
  });
}
