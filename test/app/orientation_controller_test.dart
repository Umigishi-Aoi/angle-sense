import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/app/orientation_controller.dart';

import '../helpers/fakes.dart';

const List<DeviceOrientation> _landscape = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
const List<DeviceOrientation> _portrait = [DeviceOrientation.portraitUp];

/// 内側の画面（短辺 600 以上）を横長・縦長で持ったときのサイズ。
const _innerWide = Size(1000, 700);
const _innerTall = Size(700, 1000);

/// 外側の画面（466x678）。
const _outer = Size(466, 678);

void main() {
  late List<List<DeviceOrientation>> calls;
  late Size? size;
  late OrientationController controller;

  setUp(() {
    calls = [];
    size = _innerWide;
    controller = OrientationController(
      setPreferredOrientations: (o) async => calls.add(o),
      viewSize: () => size,
    );
  });

  tearDown(() => controller.dispose());

  /// 内側の画面で開いた状態のヒンジ。
  CountingAngleProvider hinge({bool outer = false}) =>
      CountingAngleProvider(id: 'hinge')..onOuterDisplay.value = outer;

  test('傾きの入力源は横向きに 1 回だけ固定する', () {
    controller.attach(CountingAngleProvider(id: 'tilt'));
    expect(calls, [_landscape]);
  });

  testWidgets('傾きの入力源では縦長でも切り替えない', (tester) async {
    size = _innerTall;
    final tilt = CountingAngleProvider(id: 'tilt');
    controller.attach(tilt);
    tilt.onOuterDisplay.value = true;
    await tester.pump(const Duration(seconds: 2));
    expect(calls, [_landscape]);
  });

  testWidgets('ヒンジ・内側の画面では横向きに固定し、横長なら変えない', (tester) async {
    controller.attach(hinge());
    expect(calls, [_landscape]);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, [_landscape]);
  });

  test('ヒンジ・外側の画面では固定しない（空の組を渡す）', () {
    controller.attach(hinge(outer: true));
    expect(calls, [<DeviceOrientation>[]]);
  });

  testWidgets('固定して 800ms 後も縦長なら portrait に切り替える', (tester) async {
    size = _innerTall;
    controller.attach(hinge());
    await tester.pump(const Duration(milliseconds: 799));
    expect(calls, [_landscape]);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, [_landscape, _portrait]);
  });

  testWidgets('切り替えは 1 回だけ（portrait でも縦長のままでも戻さない）', (tester) async {
    size = _innerTall;
    controller.attach(hinge());
    await tester.pump(const Duration(seconds: 5));
    expect(calls, [_landscape, _portrait]);
  });

  testWidgets('切り替えた組を覚え、外側から内側に戻ったときも使う', (tester) async {
    size = _innerTall;
    final p = hinge();
    controller.attach(p);
    await tester.pump(const Duration(milliseconds: 800));
    p.onOuterDisplay.value = true;
    p.onOuterDisplay.value = false;
    expect(calls, [_landscape, _portrait, <DeviceOrientation>[], _portrait]);
  });

  testWidgets('外側の画面のサイズ（短辺 600 未満）では切り替えない', (tester) async {
    size = _outer;
    controller.attach(hinge());
    await tester.pump(const Duration(seconds: 2));
    expect(calls, [_landscape]);
  });

  testWidgets('画面のサイズが取れなければ切り替えない', (tester) async {
    size = null;
    controller.attach(hinge());
    await tester.pump(const Duration(seconds: 2));
    expect(calls, [_landscape]);
  });

  testWidgets('固定の確認前に外側へ移ったら確認しない', (tester) async {
    size = _innerTall;
    final p = hinge();
    controller.attach(p);
    await tester.pump(const Duration(milliseconds: 400));
    p.onOuterDisplay.value = true;
    await tester.pump(const Duration(seconds: 2));
    expect(calls, [_landscape, <DeviceOrientation>[]]);
  });

  testWidgets('内側に戻るたびに固定し直し、確認の時間も測り直す', (tester) async {
    final p = hinge();
    controller.attach(p);
    await tester.pump(const Duration(milliseconds: 400));
    p.onOuterDisplay.value = true;
    p.onOuterDisplay.value = false;
    size = _innerTall;
    await tester.pump(const Duration(milliseconds: 799));
    expect(calls, [_landscape, <DeviceOrientation>[], _landscape]);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls.last, _portrait);
  });

  testWidgets('dispose 後は確認せず、画面の切り替えにも反応しない', (tester) async {
    size = _innerTall;
    final p = hinge();
    controller
      ..attach(p)
      ..dispose();
    await tester.pump(const Duration(seconds: 2));
    p.onOuterDisplay.value = true;
    expect(calls, [_landscape]);
  });
}
