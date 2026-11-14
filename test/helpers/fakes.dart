import 'dart:async';

import 'package:device_angle/device_angle.dart';
import 'package:flutter/foundation.dart';
import 'package:hinge_angle_game/repositories/best_score_repository.dart';
import 'package:hinge_angle_game/services/angle_provider.dart';
import 'package:hinge_angle_game/services/best_score_store.dart';
import 'package:hinge_angle_game/services/feedback.dart';
import 'package:hinge_angle_game/services/tilt_angle_provider.dart';
import 'package:hinge_angle_game/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 鳴らした音と振動を記録するだけの GameFeedback。
class RecordingFeedback(super.settings) extends GameFeedback {
  this : super.silent();
  final events = <String>[];
  @override
  void play(Sfx sfx) => events.add(sfx.name);
  @override
  void haptic(HapticPattern pattern) => events.add('haptic:${pattern.name}');
}

class FakeAngleProvider() implements AngleProvider {
  @override
  double? latestAngle;
  @override
  Stream<double> get angleStream => const Stream.empty();
  @override
  String get id => 'fake';
  @override
  String get label => 'fake';
  @override
  final ValueNotifier<bool> onOuterDisplay = ValueNotifier(false);
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

/// テストから角度を流せる入力源（センサーの更新を真似る）。
class StreamAngleProvider() implements AngleProvider {
  final _controller = StreamController<double>.broadcast();
  @override
  double? latestAngle;
  @override
  Stream<double> get angleStream => _controller.stream;
  @override
  String get id => 'fake';
  @override
  String get label => 'fake';
  @override
  final ValueNotifier<bool> onOuterDisplay = ValueNotifier(false);
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}

  /// 新しい角度を届ける。
  void emit(double angle) {
    latestAngle = angle;
    _controller.add(angle);
  }

  Future<void> close() => _controller.close();
}

/// 端末保存を空のメモリ実装に差し替える（前のテストの保存内容を持ち越さない）。
void useInMemoryPrefs() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}

/// 端末保存（テストではメモリ実装）を使う本物の自己ベスト保存先。
BestScoreRepository inMemoryBestScores() =>
    BestScoreRepository(BestScoreStore(prefs: SharedPreferencesAsync()));

/// 決まった結果を返し、呼ばれた引数を記録する自己ベスト保存先。
class FakeBestScoreRepository({
  final Result<int?> loadResult = const Result.ok(null),
  final Result<BestScoreUpdate>? submitResult,
}) implements BestScoreRepository {
  final submitted = <int>[];

  @override
  Future<Result<int?>> load({
    required String providerId,
    required int rounds,
  }) async => loadResult;

  @override
  Future<Result<BestScoreUpdate>> submit({
    required String providerId,
    required int rounds,
    required int score,
  }) async {
    submitted.add(score);
    return submitResult ??
        Result.ok((previousBest: null, best: score, isNewBest: true));
  }
}

/// 加速度センサーの偽物。[next] に入れた値を read で返す（単位 g・Core Motion の向き）。
class FakeTiltSensor() {
  ({double x, double y, double z})? next;
  int startCount = 0;
  int stopCount = 0;
  Duration? interval;

  /// TiltAngleProvider の startSensor に渡す。
  TiltSensorHandle? start(Duration interval) {
    startCount++;
    this.interval = interval;
    return (read: () => next, stop: () => stopCount++);
  }
}

/// ヒンジ監視の偽物。start で受け取った onUpdate からテストが更新を流す。
class FakeHingeObserver({final bool available = true}) {
  void Function(HingeUpdate?)? onUpdate;
  int startCount = 0;
  int stopCount = 0;

  /// HingeAngleProvider の startObserver に渡す。
  VoidCallback? start(void Function(HingeUpdate?) onUpdate) {
    startCount++;
    if (!available) return null;
    this.onUpdate = onUpdate;
    return () => stopCount++;
  }
}

/// 開始・停止の回数を数え、指定すれば失敗する入力源。
class CountingAngleProvider({
  @override final String id = 'fake',
  final Exception? startError,
}) implements AngleProvider {
  int startCount = 0;
  int stopCount = 0;
  @override
  double? latestAngle;
  @override
  Stream<double> get angleStream => const Stream.empty();
  @override
  String get label => 'fake';
  @override
  final ValueNotifier<bool> onOuterDisplay = ValueNotifier(false);
  @override
  Future<void> start() async {
    startCount++;
    if (startError case final e?) throw e;
  }

  @override
  Future<void> stop() async => stopCount++;
}
