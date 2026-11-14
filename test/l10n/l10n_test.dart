import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('端末の言語からアプリの言語を決める', () {
    const supported = AppLocalizations.supportedLocales;

    test('日本語の端末は日本語', () {
      expect(
        resolveAppLocale(const [Locale('ja')], supported),
        const Locale('ja'),
      );
      expect(
        resolveAppLocale(const [Locale('ja', 'JP')], supported),
        const Locale('ja'),
      );
    });

    test('日本語以外の言語の端末は英語', () {
      expect(
        resolveAppLocale(const [Locale('fr')], supported),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(const [Locale('zh', 'TW')], supported),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(const [Locale('en', 'GB')], supported),
        const Locale('en'),
      );
      expect(resolveAppLocale(null, supported), const Locale('en'));
      expect(resolveAppLocale(const [], supported), const Locale('en'));
    });

    test('優先順で最初に対応している言語を使う（iOS がアプリ名を選ぶのと同じ）', () {
      expect(
        resolveAppLocale(const [Locale('fr'), Locale('ja')], supported),
        const Locale('ja'),
      );
      expect(
        resolveAppLocale(const [Locale('en'), Locale('ja')], supported),
        const Locale('en'),
      );
    });
  });

  group('組み込みの文言（戻るボタンの説明・文字選択メニュー）も同じ言語になる', () {
    Future<BuildContext> pumpWith(WidgetTester tester, Locale device) async {
      tester.platformDispatcher.localesTestValue = [device];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: resolveAppLocale,
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('日本語', (tester) async {
      final context = await pumpWith(tester, const Locale('ja', 'JP'));
      expect(Localizations.localeOf(context), const Locale('ja'));
      expect(context.l10n.appTitle, 'ピタッとアングル');
      expect(MaterialLocalizations.of(context).backButtonTooltip, '戻る');
      expect(MaterialLocalizations.of(context).copyButtonLabel, 'コピー');
      expect(CupertinoLocalizations.of(context).copyButtonLabel, 'コピー');
    });

    testWidgets('フランス語の端末は英語', (tester) async {
      final context = await pumpWith(tester, const Locale('fr', 'FR'));
      expect(Localizations.localeOf(context), const Locale('en'));
      expect(context.l10n.appTitle, 'Angle Sense');
      expect(MaterialLocalizations.of(context).backButtonTooltip, 'Back');
    });
  });

  group('数で形が変わる文言', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ja = lookupAppLocalizations(const Locale('ja'));

    test('英語は 1 のときだけ単数', () {
      expect(en.playerCount(1), '1 player');
      expect(en.playerCount(2), '2 players');
      expect(en.homeSolo(1), 'Solo (1 round)');
      expect(en.homeSolo(5), 'Solo (5 rounds)');
      expect(en.darkIn(1), 'Going dark in 1 second');
      expect(en.darkIn(3), 'Going dark in 3 seconds');
      expect(en.secondsLeft(1), '1 second left');
      expect(en.secondsLeft(5), '5 seconds left');
      expect(en.homeBest(1), 'Best: 1 pt');
      expect(en.homeBest(420), 'Best: 420 pts');
      expect(en.bestScore(300), 'Best: 300 pts');
      expect(en.resultScore(210, 500), '210 / 500 pts');
      expect(en.revealScore('4.0', 70), 'Off by 4.0°  +70 pts');
      expect(en.revealScore('0.0', 1), 'Off by 0.0°  +1 pt');
    });

    test('日本語は数によらず同じ形（元の文言のまま）', () {
      expect(ja.playerCount(1), '1 人');
      expect(ja.playerCount(2), '2 人');
      expect(ja.homeSolo(5), 'ひとりで（5問）');
      expect(ja.darkIn(1), 'あと 1 秒で暗くなる');
      expect(ja.secondsLeft(5), '残り 5 秒');
      expect(ja.homeBest(420), '自己ベスト: 420 点');
      expect(ja.bestScore(300), '自己ベスト 300 点');
      expect(ja.resultScore(210, 500), '210 / 500 点');
      expect(ja.revealScore('4.0', 70), '誤差 4.0°  +70点');
    });
  });
}
