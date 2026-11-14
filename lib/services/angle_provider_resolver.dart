import 'package:flutter/foundation.dart';

import 'angle_provider.dart';
import 'demo_angle_provider.dart';
import 'ffi_hinge_angle_provider.dart';
import 'tilt_angle_provider.dart';

/// Duo（ヒンジが取れる端末）ならヒンジ、それ以外は傾きを返す。開始済みの状態で返す。
Future<AngleProvider> resolveAngleProvider() async {
  if (DemoAngleProvider.enabled) {
    final demo = DemoAngleProvider();
    await demo.start();
    return demo;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    final hinge = FfiHingeAngleProvider();
    try {
      await hinge.start();
      if (await hinge.waitForAvailability()) return hinge;
      await hinge.stop();
    } on Exception catch (e) {
      // 想定外のエラー（PlatformException 等）で起動が止まらないよう傾きに切り替える。
      debugPrint('hinge unavailable: $e');
    }
  }
  final tilt = TiltAngleProvider();
  await tilt.start();
  return tilt;
}
