import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../game/scoring.dart';
import 'app_settings.dart';

/// 効果音の種類。ファイルは `assets/sfx/<fileName>.wav`（tool/gen_sfx.py で生成）。
enum Sfx(final String fileName) {
  countdown('countdown'),
  blindStart('blind_start'),
  tick('tick'),
  lock('lock'),
  perfect('perfect'),
  great('great'),
  good('good'),
  miss('miss'),
  rank('rank'),
  best('best');

  static Sfx forJudgement(Judgement j) => switch (j) {
    Judgement.perfect => Sfx.perfect,
    Judgement.great => Sfx.great,
    Judgement.good => Sfx.good,
    Judgement.miss => Sfx.miss,
  };
}

/// 振動のパターン。呼び出し側は「何を鳴らすか」だけを渡す。
/// 判定ごとに分けていたが実機で区別がつかず、判定は音で分かるので1種類にした（2026-11-06）。
enum HapticPattern() {
  lock,
  result,
}

/// 効果音と振動をまとめて鳴らす。設定（[AppSettings]）でそれぞれ止められる。
class GameFeedback {
  new({required this.settings, this.enableAudio = true});

  /// 音を出さない版（テスト・音声初期化に失敗したとき用）。
  new silent(this.settings) : enableAudio = false;

  final AppSettings settings;
  final bool enableAudio;
  final Map<Sfx, AudioPlayer> _players = {};
  bool _ready = false;

  /// 起動時に 1 回。iOS の音声設定を ambient にする
  /// （サイレントスイッチ／サイレントモードで消音・他のアプリの音楽を止めない）。
  /// audioplayers の既定は playback（サイレントでも鳴る・音楽を止める）なので必ず設定する。
  Future<void> init() async {
    if (!enableAudio) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
      _ready = true;
    } on Exception catch (e) {
      // 音が出ないだけでゲームは続けられるようにする。
      debugPrint('sfx init failed: $e');
      return;
    }
    // 1 ファイル読めなくても、ほかの音は鳴らせるように個別に読み込む。
    for (final s in Sfx.values) {
      final p = AudioPlayer(playerId: 'sfx_${s.fileName}');
      try {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource('sfx/${s.fileName}.wav'));
        _players[s] = p;
      } on Exception catch (e) {
        debugPrint('sfx load failed (${s.fileName}): $e');
        await p.dispose();
      }
    }
  }

  void play(Sfx sfx) {
    if (!_ready || !settings.sound) return;
    final p = _players[sfx];
    if (p == null) return;
    // 同じ音が鳴っている途中でも頭から鳴らし直す。
    unawaited(
      p.stop().then((_) => p.resume()).catchError((Object e) {
        debugPrint('sfx play failed: $e');
      }),
    );
  }

  void haptic(HapticPattern pattern) {
    if (!settings.haptics) return;
    switch (pattern) {
      case HapticPattern.lock:
        HapticFeedback.heavyImpact();
      case HapticPattern.result:
        HapticFeedback.mediumImpact();
    }
  }

  /// 判定の音と振動をまとめて鳴らす（振動は判定によらず同じ）。
  void judgement(Judgement j) {
    play(Sfx.forJudgement(j));
    haptic(HapticPattern.result);
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    _ready = false;
  }
}

/// 画面ツリー全体に設定と効果音を配る。
class const AppServices({
  super.key,
  required final AppSettings settings,
  required final GameFeedback feedback,

  /// App Store のレビュー依頼（自己ベストを更新したときに呼ぶ）。
  final Future<void> Function()? requestReview,
  required super.child,
}) extends InheritedWidget {
  /// 再描画の依存を作らずに取る（initState からも呼べる）。
  /// 設定の変化で描き直したい画面は [AppSettings] を ListenableBuilder で監視する。
  static AppServices? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppServices>();

  @override
  bool updateShouldNotify(AppServices old) =>
      settings != old.settings ||
      feedback != old.feedback ||
      requestReview != old.requestReview;
}

/// AppServices が無いとき（ウィジェットテストなど）は無音・無振動で動かす。
final _fallbackSettings = AppSettings()
  ..sound = false
  ..haptics = false;
final _fallbackFeedback = GameFeedback.silent(_fallbackSettings);

extension AppServicesContext on BuildContext {
  GameFeedback get feedback =>
      AppServices.maybeOf(this)?.feedback ?? _fallbackFeedback;
  AppSettings get settings =>
      AppServices.maybeOf(this)?.settings ?? _fallbackSettings;

  /// AppServices が無い・未設定なら何もしない。
  Future<void> Function() get requestReview =>
      AppServices.maybeOf(this)?.requestReview ?? () async {};
}
