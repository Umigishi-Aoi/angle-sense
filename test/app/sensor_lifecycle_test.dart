import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/app/sensor_lifecycle.dart';

import '../helpers/fakes.dart';

void main() {
  group('SensorLifecycle', () {
    test('バックグラウンドに入るとセンサーを止める', () async {
      final provider = CountingAngleProvider();
      await SensorLifecycle(Future.syncValue(provider)).onPause();
      expect(provider.stopCount, 1);
    });

    test('止めたあと戻ってきたら再開する', () async {
      final provider = CountingAngleProvider();
      final lifecycle = SensorLifecycle(Future.syncValue(provider));
      await lifecycle.onPause();
      await lifecycle.onResume();
      expect(provider.startCount, 1);
    });

    test('止めていなければ戻ってきても開始しない', () async {
      final provider = CountingAngleProvider();
      await SensorLifecycle(Future.syncValue(provider)).onResume();
      expect(provider.startCount, 0);
    });

    test('1 回の停止に対して再開は 1 回だけ', () async {
      final provider = CountingAngleProvider();
      final lifecycle = SensorLifecycle(Future.syncValue(provider));
      await lifecycle.onPause();
      await lifecycle.onResume();
      await lifecycle.onResume();
      expect(provider.startCount, 1);
    });

    test('再開に失敗しても例外を出さない', () async {
      final provider = CountingAngleProvider(startError: Exception('boom'));
      final lifecycle = SensorLifecycle(Future.syncValue(provider));
      await lifecycle.onPause();
      await expectLater(lifecycle.onResume(), completes);
      expect(provider.startCount, 1);
    });
  });
}
