import 'package:flutter/foundation.dart';

import 'angle_provider.dart';
import 'demo_angle_provider.dart';
import 'hinge_angle_provider.dart';
import 'tilt_angle_provider.dart';

/// Duo（ヒンジが取れる端末）ならヒンジ、それ以外は傾きを返す。開始済みの状態で返す。
///
/// 引数はテスト用（入力源の作り方を偽物に差し替える）。アプリからは何も渡さない。
Future<AngleProvider> resolveAngleProvider({
  bool demo = DemoAngleProvider.enabled,
  AngleProvider Function() createDemo = DemoAngleProvider.new,
  HingeAngleProvider Function() createHinge = HingeAngleProvider.new,
  AngleProvider Function() createTilt = TiltAngleProvider.new,
}) async {
  if (demo) {
    final provider = createDemo();
    await provider.start();
    return provider;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    final hinge = createHinge();
    try {
      await hinge.start();
      if (await hinge.waitForAvailability()) return hinge;
      await hinge.stop();
    } on Exception catch (e) {
      // 想定外のエラー（PlatformException 等）で起動が止まらないよう傾きに切り替える。
      debugPrint('hinge unavailable: $e');
    }
  }
  final tilt = createTilt();
  await tilt.start();
  return tilt;
}

/// 入力源を決める。失敗しても読み込み画面のまま止まらないよう、傾きに切り替えてホームを出す
/// （傾きも始められなければ角度が来ないだけで、ホームに「取得しています…」と出る）。
Future<AngleProvider> resolveAngleProviderOrTilt({
  Future<AngleProvider> Function() resolve = resolveAngleProvider,
  AngleProvider Function() createTilt = TiltAngleProvider.new,
}) async {
  try {
    return await resolve();
  } on Object catch (e) {
    debugPrint('angle provider resolve failed: $e');
  }
  final tilt = createTilt();
  await guardSensorCall('tilt start', tilt.start);
  return tilt;
}

/// センサーの開始・停止の失敗でアプリを落とさない（記録だけする）。
Future<void> guardSensorCall(String label, Future<void> Function() f) async {
  try {
    await f();
  } on Object catch (e) {
    debugPrint('angle provider $label failed: $e');
  }
}
