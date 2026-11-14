// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// アプリ名（タイトル・ライセンス画面）
  ///
  /// In ja, this message translates to:
  /// **'ピタッとアングル'**
  String get appTitle;

  /// 「やめる」ボタン・ツールチップ
  ///
  /// In ja, this message translates to:
  /// **'やめる'**
  String get quit;

  /// 中断確認で続けるボタン
  ///
  /// In ja, this message translates to:
  /// **'続ける'**
  String get keepPlaying;

  /// もう一度遊ぶボタン
  ///
  /// In ja, this message translates to:
  /// **'もう一度'**
  String get playAgain;

  /// 角度が取れなかったときの表示
  ///
  /// In ja, this message translates to:
  /// **'計測なし'**
  String get noReading;

  /// 結果の行（計測なし）。target=お題の角度
  ///
  /// In ja, this message translates to:
  /// **'{target}°→計測なし'**
  String resultLineNoReading(int target);

  /// ホームの説明（1行目）
  ///
  /// In ja, this message translates to:
  /// **'目標の角度を覚えて、暗闇の中で合わせよう'**
  String get homeTagline;

  /// ホームの角度の基準
  ///
  /// In ja, this message translates to:
  /// **'平らが 0°・直角が 90°'**
  String get homeAngleScale;

  /// 入力源の表示。source=入力源の名前
  ///
  /// In ja, this message translates to:
  /// **'入力: {source}'**
  String homeInput(String source);

  /// 入力源の名前（ヒンジ）
  ///
  /// In ja, this message translates to:
  /// **'ヒンジ（iPhone Duo）'**
  String get inputHinge;

  /// 入力源の名前（傾き）
  ///
  /// In ja, this message translates to:
  /// **'端末の傾き（加速度センサー）'**
  String get inputTilt;

  /// 角度がまだ取れていないとき
  ///
  /// In ja, this message translates to:
  /// **'角度: --'**
  String get homeAngleUnknown;

  /// 今の角度の読み上げラベル
  ///
  /// In ja, this message translates to:
  /// **'今の角度'**
  String get homeCurrentAngle;

  /// 自己ベストなし
  ///
  /// In ja, this message translates to:
  /// **'自己ベスト: --'**
  String get homeBestNone;

  /// 自己ベスト。score=点数
  ///
  /// In ja, this message translates to:
  /// **'{score, plural, other{自己ベスト: {score} 点}}'**
  String homeBest(int score);

  /// ひとりで遊ぶボタン。rounds=問題数
  ///
  /// In ja, this message translates to:
  /// **'{rounds, plural, other{ひとりで（{rounds}問）}}'**
  String homeSolo(int rounds);

  /// バトルボタン。min/max=人数
  ///
  /// In ja, this message translates to:
  /// **'バトル（{min}〜{max}人）'**
  String homeBattle(int min, int max);

  /// あそびかたボタン
  ///
  /// In ja, this message translates to:
  /// **'あそびかた・持ち方'**
  String get homeHowTo;

  /// 角度の取得待ち
  ///
  /// In ja, this message translates to:
  /// **'角度を取得しています…（センサーのない端末では遊べません）'**
  String get homeWaitingSensor;

  /// 設定ボタンのツールチップ
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTooltip;

  /// あそびかたダイアログの見出し
  ///
  /// In ja, this message translates to:
  /// **'あそびかた'**
  String get howToTitle;

  /// あそびかた（折りたたみ iPhone）
  ///
  /// In ja, this message translates to:
  /// **'1. 内側の画面を見ながら、本を読むように両手で持つ\n   （机に置いてノートパソコンのように開いてもOK）\n\n2. 平らに開いた状態が 0°。折るほど大きくなり、直角が 90°\n\n3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく\n\n・お題は 10〜80°。直角より閉じると外側の画面に切り替わるので、そこまでは閉じない\n・0° に近い角度はバネで開ききるので、指で支えて止める'**
  String get howToHinge;

  /// あそびかた（普通の iPhone / iPad）
  ///
  /// In ja, this message translates to:
  /// **'1. 本体を横向きにして、両手で持つ\n\n2. 画面を上にして平らに置いた状態が 0°。起こすほど大きくなり、まっすぐ立てると 90°\n\n3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく\n\n・お題は 10〜80°\n・折りたたみ iPhone では、本体を折る角度で遊べます'**
  String get howToTilt;

  /// ダイアログを閉じるボタン
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// 設定: 効果音
  ///
  /// In ja, this message translates to:
  /// **'効果音'**
  String get settingsSound;

  /// 設定: 効果音の補足
  ///
  /// In ja, this message translates to:
  /// **'マナーモード中は鳴りません'**
  String get settingsSoundNote;

  /// 設定: 暗転中のカウント音
  ///
  /// In ja, this message translates to:
  /// **'暗転中のカウント音'**
  String get settingsTick;

  /// 設定: カウント音の補足
  ///
  /// In ja, this message translates to:
  /// **'1秒ごとの小さな音。リズムで時間が分かります'**
  String get settingsTickNote;

  /// 設定: 振動
  ///
  /// In ja, this message translates to:
  /// **'振動'**
  String get settingsHaptics;

  /// 設定: 振動の補足
  ///
  /// In ja, this message translates to:
  /// **'iPhoneの「触覚」設定によってはマナーモード中に鳴りません'**
  String get settingsHapticsNote;

  /// 設定: 診断画面（開発版のみ表示）
  ///
  /// In ja, this message translates to:
  /// **'診断（実機確認用）'**
  String get settingsDiagnostics;

  /// 設定: ライセンス
  ///
  /// In ja, this message translates to:
  /// **'ライセンス'**
  String get settingsLicenses;

  /// ゲーム中断の確認
  ///
  /// In ja, this message translates to:
  /// **'ゲームをやめますか？'**
  String get gameQuitTitle;

  /// バトル中の中断の説明
  ///
  /// In ja, this message translates to:
  /// **'やめると、この人の番はここで終わりです（計測前なら「計測なし」）。'**
  String get gameQuitBattleBody;

  /// ひとりで遊ぶときの中断の説明
  ///
  /// In ja, this message translates to:
  /// **'ここまでの結果は保存されません。'**
  String get gameQuitSoloBody;

  /// 何問目か。current=今の問題 / total=問題数
  ///
  /// In ja, this message translates to:
  /// **'第 {current} / {total} 問'**
  String gameRound(int current, int total);

  /// 一時停止の見出し
  ///
  /// In ja, this message translates to:
  /// **'一時停止中'**
  String get pausedTitle;

  /// 一時停止の補足
  ///
  /// In ja, this message translates to:
  /// **'再開すると、この問題をお題からやり直します'**
  String get pausedRestartNote;

  /// 再開ボタン
  ///
  /// In ja, this message translates to:
  /// **'再開'**
  String get resume;

  /// お題の見本の図の読み上げ。angle=お題の角度
  ///
  /// In ja, this message translates to:
  /// **'お題 {angle}° の見本の図'**
  String targetFigureLabel(int angle);

  /// お題表示中の残り秒数
  ///
  /// In ja, this message translates to:
  /// **'{seconds, plural, other{あと {seconds} 秒で暗くなる}}'**
  String darkIn(int seconds);

  /// 暗転中のお題の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'お題 {angle}°'**
  String blindTargetLabel(int angle);

  /// 残り秒数の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'{seconds, plural, other{残り {seconds} 秒}}'**
  String secondsLeft(int seconds);

  /// 答え合わせの凡例（目標）
  ///
  /// In ja, this message translates to:
  /// **'目標 {angle}°'**
  String legendTarget(int angle);

  /// 答え合わせの凡例（あなた）
  ///
  /// In ja, this message translates to:
  /// **'あなた {angle}°'**
  String legendYou(int angle);

  /// 答え合わせの凡例（あなた・計測なし）
  ///
  /// In ja, this message translates to:
  /// **'あなた 計測なし'**
  String get legendYouNoReading;

  /// 誤差と得点。error=誤差（小数1桁の文字列）
  ///
  /// In ja, this message translates to:
  /// **'{points, plural, other{誤差 {error}°  +{points}点}}'**
  String revealScore(String error, int points);

  /// 角度が取れなかったとき
  ///
  /// In ja, this message translates to:
  /// **'角度を取得できませんでした  +0点'**
  String get revealNoReading;

  /// バトルの最後の問題の次へ
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get next;

  /// ひとりで遊ぶ最後の問題の次へ
  ///
  /// In ja, this message translates to:
  /// **'結果へ'**
  String get toResults;

  /// 次の問題へ
  ///
  /// In ja, this message translates to:
  /// **'次の問題'**
  String get nextRound;

  /// 答え合わせの図の読み上げ。you=あなたの角度（「41°」か「計測なし」）
  ///
  /// In ja, this message translates to:
  /// **'答え合わせの図。目標 {target}°、あなた {you}'**
  String revealFigureLabel(int target, String you);

  /// 拡大図の見出し
  ///
  /// In ja, this message translates to:
  /// **'拡大'**
  String get zoomHeading;

  /// 拡大図の読み上げ。signed=符号つきのズレ（+4.0° など）
  ///
  /// In ja, this message translates to:
  /// **'拡大図、ズレ {signed}'**
  String zoomLabel(String signed);

  /// 結果画面の見出し
  ///
  /// In ja, this message translates to:
  /// **'結果'**
  String get resultTitle;

  /// ランクの見出し
  ///
  /// In ja, this message translates to:
  /// **'ランク'**
  String get rankHeading;

  /// 合計点 / 満点
  ///
  /// In ja, this message translates to:
  /// **'{max, plural, other{{score} / {max} 点}}'**
  String resultScore(int score, int max);

  /// 自己ベスト更新
  ///
  /// In ja, this message translates to:
  /// **'自己ベスト更新！'**
  String get newBest;

  /// 自己ベスト（更新しなかったとき）
  ///
  /// In ja, this message translates to:
  /// **'{score, plural, other{自己ベスト {score} 点}}'**
  String bestScore(int score);

  /// ホームへ戻るボタン（結果）
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get home;

  /// ズレ図の見出し（ひとり）
  ///
  /// In ja, this message translates to:
  /// **'あなたの感覚のズレ'**
  String get yourSenseGap;

  /// ズレ図・結果の行の問題番号
  ///
  /// In ja, this message translates to:
  /// **'{n}問'**
  String roundShort(int n);

  /// 問題番号の読み上げ（VoiceOver）。英語は表示が R1 と短いので、読み上げは Round 1 にする
  ///
  /// In ja, this message translates to:
  /// **'{n}問'**
  String roundSpoken(int n);

  /// バトルの見出し
  ///
  /// In ja, this message translates to:
  /// **'バトル'**
  String get battleTitle;

  /// バトル設定の説明（1行目）
  ///
  /// In ja, this message translates to:
  /// **'1人1回ずつ、順番に角度を合わせます'**
  String get battleSetupLead;

  /// バトル設定の説明（2行目）
  ///
  /// In ja, this message translates to:
  /// **'お題は1人ずつちがいます。誤差の小さい人が勝ち'**
  String get battleSetupRule;

  /// 人数の単位（英語のように数字の下に分けて出す言語用。日本語は playerCount の 1 行表示を使う）
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{人}}'**
  String playerUnit(int count);

  /// 人数
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{{count} 人}}'**
  String playerCount(int count);

  /// 人数を減らすボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'1人減らす'**
  String get removePlayer;

  /// 人数を増やすボタンの読み上げ
  ///
  /// In ja, this message translates to:
  /// **'1人増やす'**
  String get addPlayer;

  /// バトル開始ボタン
  ///
  /// In ja, this message translates to:
  /// **'はじめる'**
  String get battleStart;

  /// バトル中断の確認
  ///
  /// In ja, this message translates to:
  /// **'バトルをやめますか？'**
  String get battleQuitTitle;

  /// バトル中断の説明
  ///
  /// In ja, this message translates to:
  /// **'ここまでの結果は消えます。'**
  String get battleQuitBody;

  /// 名前を入れなかった人の名前
  ///
  /// In ja, this message translates to:
  /// **'プレイヤー{n}'**
  String playerName(int n);

  /// ズレ図の短い名前
  ///
  /// In ja, this message translates to:
  /// **'P{n}'**
  String playerShort(int n);

  /// 何人目か
  ///
  /// In ja, this message translates to:
  /// **'{current} / {total} 人目'**
  String turnProgress(int current, int total);

  /// 誰の番か
  ///
  /// In ja, this message translates to:
  /// **'{name} の番'**
  String turnOf(String name);

  /// 名前の入力欄のヒント
  ///
  /// In ja, this message translates to:
  /// **'名前（入れなくてもOK）'**
  String get nameHint;

  /// 本体を渡したあとの案内
  ///
  /// In ja, this message translates to:
  /// **'本体を受け取ったら、スタートを押してね'**
  String get handOverHint;

  /// 自分の番を始めるボタン
  ///
  /// In ja, this message translates to:
  /// **'スタート'**
  String get turnStart;

  /// 結果発表の見出し
  ///
  /// In ja, this message translates to:
  /// **'結果発表'**
  String get battleResultsHeading;

  /// 順位
  ///
  /// In ja, this message translates to:
  /// **'{rank}位'**
  String place(int rank);

  /// ズレ図の見出し（バトル）
  ///
  /// In ja, this message translates to:
  /// **'みんなの感覚のズレ'**
  String get everyoneSenseGap;

  /// ホームへ戻るボタン（バトル）
  ///
  /// In ja, this message translates to:
  /// **'ホームへ'**
  String get toHome;

  /// 結果の行。error=誤差（小数1桁の文字列）
  ///
  /// In ja, this message translates to:
  /// **'{target}°→{actual}°  誤差{error}°'**
  String battleResultLine(int target, int actual, String error);

  /// ズレ図の左端（足りない）
  ///
  /// In ja, this message translates to:
  /// **'← 足りない'**
  String get chartUnder;

  /// ズレ図の真ん中（ピタッ）
  ///
  /// In ja, this message translates to:
  /// **'ピタッ'**
  String get chartSpotOn;

  /// ズレ図の右端（折りすぎ）
  ///
  /// In ja, this message translates to:
  /// **'折りすぎ →'**
  String get chartOver;

  /// ズレの向きの読み上げ（ぴったり）
  ///
  /// In ja, this message translates to:
  /// **'ピタッ'**
  String get sideSpotOn;

  /// ズレの向きの読み上げ（大きすぎ）
  ///
  /// In ja, this message translates to:
  /// **'折りすぎ'**
  String get sideOver;

  /// ズレの向きの読み上げ（小さすぎ）
  ///
  /// In ja, this message translates to:
  /// **'足りない'**
  String get sideUnder;

  /// ズレ図の 1 行の読み上げ。judgement=PERFECT など
  ///
  /// In ja, this message translates to:
  /// **'{name}、{signed} {side}、{judgement}'**
  String chartRowLabel(
    String name,
    String signed,
    String side,
    String judgement,
  );

  /// ズレ図の 1 行の読み上げ（計測なし）
  ///
  /// In ja, this message translates to:
  /// **'{name}、計測なし、{judgement}'**
  String chartRowNoReading(String name, String judgement);

  /// 外側の画面に移ったときの見出し
  ///
  /// In ja, this message translates to:
  /// **'ひらいてね'**
  String get openPrompt;

  /// 外側の画面に移ったときの説明
  ///
  /// In ja, this message translates to:
  /// **'このゲームは内側の画面で遊びます。\n直角より大きく開くと内側の画面に戻ります。'**
  String get openPromptBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
