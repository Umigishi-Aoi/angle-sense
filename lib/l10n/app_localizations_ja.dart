// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ピタッとアングル';

  @override
  String get quit => 'やめる';

  @override
  String get keepPlaying => '続ける';

  @override
  String get playAgain => 'もう一度';

  @override
  String get noReading => '計測なし';

  @override
  String resultLineNoReading(int target) {
    return '$target°→計測なし';
  }

  @override
  String get homeTagline => '目標の角度を覚えて、暗闇の中で合わせよう';

  @override
  String get homeAngleScale => '平らが 0°・直角が 90°';

  @override
  String homeInput(String source) {
    return '入力: $source';
  }

  @override
  String get inputHinge => 'ヒンジ（iPhone Duo）';

  @override
  String get inputTilt => '端末の傾き（加速度センサー）';

  @override
  String get homeAngleUnknown => '角度: --';

  @override
  String get homeCurrentAngle => '今の角度';

  @override
  String get homeBestNone => '自己ベスト: --';

  @override
  String homeBest(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '自己ベスト: $score 点',
    );
    return '$_temp0';
  }

  @override
  String homeSolo(int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: 'ひとりで（$rounds問）',
    );
    return '$_temp0';
  }

  @override
  String homeBattle(int min, int max) {
    return 'バトル（$min〜$max人）';
  }

  @override
  String get homeHowTo => 'あそびかた・持ち方';

  @override
  String get homeWaitingSensor => '角度を取得しています…（センサーのない端末では遊べません）';

  @override
  String get settingsTooltip => '設定';

  @override
  String get howToTitle => 'あそびかた';

  @override
  String get howToHinge =>
      '1. 内側の画面を見ながら、本を読むように両手で持つ\n   （机に置いてノートパソコンのように開いてもOK）\n\n2. 平らに開いた状態が 0°。折るほど大きくなり、直角が 90°\n\n3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく\n\n・お題は 10〜80°。直角より閉じると外側の画面に切り替わるので、そこまでは閉じない\n・0° に近い角度はバネで開ききるので、指で支えて止める';

  @override
  String get howToTilt =>
      '1. 本体を横向きにして、両手で持つ\n\n2. 画面を上にして平らに置いた状態が 0°。起こすほど大きくなり、まっすぐ立てると 90°\n\n3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく\n\n・お題は 10〜80°\n・折りたたみ iPhone では、本体を折る角度で遊べます';

  @override
  String get ok => 'OK';

  @override
  String get settingsSound => '効果音';

  @override
  String get settingsSoundNote => 'マナーモード中は鳴りません';

  @override
  String get settingsTick => '暗転中のカウント音';

  @override
  String get settingsTickNote => '1秒ごとの小さな音。リズムで時間が分かります';

  @override
  String get settingsHaptics => '振動';

  @override
  String get settingsHapticsNote => 'iPhoneの「触覚」設定によってはマナーモード中に鳴りません';

  @override
  String get settingsDiagnostics => '診断（実機確認用）';

  @override
  String get settingsLicenses => 'ライセンス';

  @override
  String get gameQuitTitle => 'ゲームをやめますか？';

  @override
  String get gameQuitBattleBody => 'やめると、この人の番はここで終わりです（計測前なら「計測なし」）。';

  @override
  String get gameQuitSoloBody => 'ここまでの結果は保存されません。';

  @override
  String gameRound(int current, int total) {
    return '第 $current / $total 問';
  }

  @override
  String get pausedTitle => '一時停止中';

  @override
  String get pausedRestartNote => '再開すると、この問題をお題からやり直します';

  @override
  String get resume => '再開';

  @override
  String targetFigureLabel(int angle) {
    return 'お題 $angle° の見本の図';
  }

  @override
  String darkIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'あと $seconds 秒で暗くなる',
    );
    return '$_temp0';
  }

  @override
  String blindTargetLabel(int angle) {
    return 'お題 $angle°';
  }

  @override
  String secondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '残り $seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String legendTarget(int angle) {
    return '目標 $angle°';
  }

  @override
  String legendYou(int angle) {
    return 'あなた $angle°';
  }

  @override
  String get legendYouNoReading => 'あなた 計測なし';

  @override
  String revealScore(String error, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '誤差 $error°  +$points点',
    );
    return '$_temp0';
  }

  @override
  String get revealNoReading => '角度を取得できませんでした  +0点';

  @override
  String get next => '次へ';

  @override
  String get toResults => '結果へ';

  @override
  String get nextRound => '次の問題';

  @override
  String revealFigureLabel(int target, String you) {
    return '答え合わせの図。目標 $target°、あなた $you';
  }

  @override
  String get zoomHeading => '拡大';

  @override
  String zoomLabel(String signed) {
    return '拡大図、ズレ $signed';
  }

  @override
  String get resultTitle => '結果';

  @override
  String get rankHeading => 'ランク';

  @override
  String resultScore(int score, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$score / $max 点',
    );
    return '$_temp0';
  }

  @override
  String get newBest => '自己ベスト更新！';

  @override
  String bestScore(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '自己ベスト $score 点',
    );
    return '$_temp0';
  }

  @override
  String get home => 'ホーム';

  @override
  String get yourSenseGap => 'あなたの感覚のズレ';

  @override
  String roundShort(int n) {
    return '$n問';
  }

  @override
  String roundSpoken(int n) {
    return '$n問';
  }

  @override
  String get battleTitle => 'バトル';

  @override
  String get battleSetupLead => '1人1回ずつ、順番に角度を合わせます';

  @override
  String get battleSetupRule => 'お題は1人ずつちがいます。誤差の小さい人が勝ち';

  @override
  String playerUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '人',
    );
    return '$_temp0';
  }

  @override
  String playerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人',
    );
    return '$_temp0';
  }

  @override
  String get removePlayer => '1人減らす';

  @override
  String get addPlayer => '1人増やす';

  @override
  String get battleStart => 'はじめる';

  @override
  String get battleQuitTitle => 'バトルをやめますか？';

  @override
  String get battleQuitBody => 'ここまでの結果は消えます。';

  @override
  String playerName(int n) {
    return 'プレイヤー$n';
  }

  @override
  String playerShort(int n) {
    return 'P$n';
  }

  @override
  String turnProgress(int current, int total) {
    return '$current / $total 人目';
  }

  @override
  String turnOf(String name) {
    return '$name の番';
  }

  @override
  String get nameHint => '名前（入れなくてもOK）';

  @override
  String get handOverHint => '本体を受け取ったら、スタートを押してね';

  @override
  String get turnStart => 'スタート';

  @override
  String get battleResultsHeading => '結果発表';

  @override
  String place(int rank) {
    return '$rank位';
  }

  @override
  String get everyoneSenseGap => 'みんなの感覚のズレ';

  @override
  String get toHome => 'ホームへ';

  @override
  String battleResultLine(int target, int actual, String error) {
    return '$target°→$actual°  誤差$error°';
  }

  @override
  String get chartUnder => '← 足りない';

  @override
  String get chartSpotOn => 'ピタッ';

  @override
  String get chartOver => '折りすぎ →';

  @override
  String get sideSpotOn => 'ピタッ';

  @override
  String get sideOver => '折りすぎ';

  @override
  String get sideUnder => '足りない';

  @override
  String chartRowLabel(
    String name,
    String signed,
    String side,
    String judgement,
  ) {
    return '$name、$signed $side、$judgement';
  }

  @override
  String chartRowNoReading(String name, String judgement) {
    return '$name、計測なし、$judgement';
  }

  @override
  String get openPrompt => 'ひらいてね';

  @override
  String get openPromptBody => 'このゲームは内側の画面で遊びます。\n直角より大きく開くと内側の画面に戻ります。';
}
