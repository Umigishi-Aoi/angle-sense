import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/diagnostics_log.dart';
import 'package:hinge_angle_game/services/hinge_angle_provider.dart';

import '../helpers/fakes.dart';

void main() {
  test('ヒンジの角度を平ら=0° に変換し、取れなくなったら古い角度を消す', () {
    final provider = HingeAngleProvider();
    DiagnosticsLog.instance.clear();
    provider.onUpdate((angleRadians: math.pi / 2, status: .partiallyOpen));
    expect(provider.latestAngle, closeTo(90, 1e-9));
    // ゲームの角度は平ら=0°（ヒンジの生の角度を反転）
    provider.onUpdate((
      angleRadians: 170 * math.pi / 180,
      status: .partiallyOpen,
    ));
    expect(provider.latestAngle, closeTo(10, 1e-9));
    expect(provider.onOuterDisplay.value, isFalse);
    // closed = 外側の画面に移った
    provider.onUpdate((angleRadians: 80 * math.pi / 180, status: .closed));
    expect(provider.latestAngle, closeTo(100, 1e-9));
    expect(provider.onOuterDisplay.value, isTrue);
    provider.onUpdate(null);
    expect(provider.latestAngle, isNull);
    // 診断ログに生の値が残る
    final log = DiagnosticsLog.instance.export();
    expect(
      log,
      contains('status=partiallyOpen available=true rad=1.5708 deg=90.0'),
    );
    expect(log, contains('status=unavailable'));
  });

  group('waitForAvailability', () {
    test('最初の更新に角度があれば true', () async {
      final observer = FakeHingeObserver();
      final provider = HingeAngleProvider(startObserver: observer.start);
      await provider.start();
      observer.onUpdate!((angleRadians: math.pi, status: .fullyOpen));
      expect(await provider.waitForAvailability(), isTrue);
    });

    test('最初の更新が null（ヒンジの無い端末）なら false', () async {
      final observer = FakeHingeObserver();
      final provider = HingeAngleProvider(startObserver: observer.start);
      await provider.start();
      observer.onUpdate!(null);
      expect(await provider.waitForAvailability(), isFalse);
    });

    test('監視を始められなければ（iOS 27.1 未満など）すぐ false', () async {
      final provider = HingeAngleProvider(
        startObserver: FakeHingeObserver(available: false).start,
      );
      await provider.start();
      expect(
        await provider.waitForAvailability(timeout: const Duration(days: 1)),
        isFalse,
      );
    });

    testWidgets('更新が来ないまま timeout を過ぎたら false', (tester) async {
      final provider = HingeAngleProvider(
        startObserver: FakeHingeObserver().start,
      );
      await provider.start();
      bool? result;
      unawaitedResult(provider.waitForAvailability(), (v) => result = v);
      await tester.pump(const Duration(milliseconds: 999));
      expect(result, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(result, isFalse);
    });

    test('結果は最初の更新で決まり、あとで null が来ても変わらない', () async {
      final observer = FakeHingeObserver();
      final provider = HingeAngleProvider(startObserver: observer.start);
      await provider.start();
      observer.onUpdate!((angleRadians: 1, status: .partiallyOpen));
      observer.onUpdate!(null);
      expect(await provider.waitForAvailability(), isTrue);
    });
  });

  group('start / stop', () {
    test('2 回 start しても監視は 1 回しか始めない', () async {
      final observer = FakeHingeObserver();
      final provider = HingeAngleProvider(startObserver: observer.start);
      await provider.start();
      await provider.start();
      expect(observer.startCount, 1);
    });

    test('stop で監視を止め、もう一度 start すると始め直す', () async {
      final observer = FakeHingeObserver();
      final provider = HingeAngleProvider(startObserver: observer.start);
      await provider.start();
      await provider.stop();
      expect(observer.stopCount, 1);
      await provider.start();
      expect(observer.startCount, 2);
    });

    test('監視していないときの stop は何もしない', () async {
      final observer = FakeHingeObserver();
      final provider = HingeAngleProvider(startObserver: observer.start);
      await provider.stop();
      expect(observer.stopCount, 0);
    });

    test('角度を angleStream に流す', () async {
      final observer = FakeHingeObserver();
      final provider = HingeAngleProvider(startObserver: observer.start);
      await provider.start();
      final next = provider.angleStream.first;
      observer.onUpdate!((angleRadians: math.pi / 2, status: .partiallyOpen));
      expect(await next, closeTo(90, 1e-9));
    });
  });
}

/// Future の結果を待たずに受け取る（偽の時間を進めながら結果を確かめるため）。
void unawaitedResult<T>(Future<T> f, void Function(T) onValue) {
  f.then(onValue).ignore();
}
