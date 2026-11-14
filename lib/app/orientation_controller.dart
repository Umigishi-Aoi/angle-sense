import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../services/angle_provider.dart';
import '../services/diagnostics_log.dart';

/// 今の画面の論理サイズ（画面が無ければ null）。
Size? currentViewSize() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return null;
  final v = views.first;
  return v.physicalSize / v.devicePixelRatio;
}

/// 入力源に合わせて画面の回転を固定する。
///
/// 引数はテスト用（回転の固定と画面サイズの読み取りを偽物に差し替える）。
class OrientationController({
  final Future<void> Function(List<DeviceOrientation>)
      _setPreferredOrientations =
      SystemChrome.setPreferredOrientations,
  final Size? Function() _viewSize = currentViewSize,
}) {
  /// 内側の画面で横長になる向きの組。最初は landscape を試し、縦長になったら portrait に切り替えて覚える
  /// （Duo の内側の画面でどちらが横長かを決め打ちしないため）。
  static const List<DeviceOrientation> landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> portrait = [
    DeviceOrientation.portraitUp,
  ];

  /// 固定してから縦長かどうかを確かめるまでの時間。
  static const verifyDelay = Duration(milliseconds: 800);

  AngleProvider? _hinge;
  List<DeviceOrientation> _innerSet = landscape;
  List<DeviceOrientation>? _applied;
  Timer? _verifyTimer;
  bool _disposed = false;

  /// 切り替えは1回だけ（どちらの組でも縦長になる異常時に行ったり来たりしないため）。
  bool _flipped = false;

  /// 入力源が決まったら 1 回呼ぶ。
  void attach(AngleProvider p) {
    if (p.id != 'hinge') {
      // アクセシビリティの指針では向きを固定しないが、このゲームは横向き専用の設計なので意図して固定する（ヒンジ側も同じ）。
      // 普通の iPhone / iPad（傾きで遊ぶ）: 横向きに固定する。
      // 実機: 縦向きだと結果発表などのレイアウトが崩れる。傾きの角度は画面の法線だけで決まるので向きの影響はない。
      DiagnosticsLog.instance.add('rot', 'lock landscape (tilt)');
      _setPreferredOrientations(landscape);
      return;
    }
    _hinge = p;
    p.onOuterDisplay.addListener(_applyOrientation);
    _applyOrientation();
  }

  /// 画面の回転を固定する（実機: 開いて持ち上げたり触ったりすると縦長に回ってしまう）。
  /// - 内側の画面: 横長に固定
  /// - 外側の画面（「ひらいてね」だけを出す）: 固定しない
  void _applyOrientation() {
    final p = _hinge;
    if (p == null) return;
    final want = p.onOuterDisplay.value
        ? const <DeviceOrientation>[]
        : _innerSet;
    if (identical(want, _applied)) return;
    _applied = want;
    DiagnosticsLog.instance.add(
      'rot',
      want.isEmpty
          ? 'unlocked (outer)'
          : 'lock ${want.map((o) => o.name).join(',')}',
    );
    _setPreferredOrientations(want);
    _verifyTimer?.cancel();
    if (want.isNotEmpty && !_flipped) {
      // 固定した「結果」のサイズで判定する。固定の直前に届く通知（開いた瞬間の、まだ回っていない縦長など）は使わない。
      _verifyTimer = Timer(verifyDelay, _verifyInnerLock);
    }
  }

  /// 固定したのに縦長 = この組は横長にならない。もう片方の組に切り替えて覚える。
  void _verifyInnerLock() {
    final p = _hinge;
    if (_disposed ||
        p == null ||
        p.onOuterDisplay.value ||
        !identical(_applied, _innerSet)) {
      return;
    }
    final size = _viewSize();
    if (size == null) return;
    // 短辺 600 未満は外側の画面（466x678）なので見ない。
    if (size.shortestSide < 600 || size.width >= size.height) return;
    _flipped = true;
    _innerSet = identical(_innerSet, landscape) ? portrait : landscape;
    DiagnosticsLog.instance.add(
      'rot',
      'tall after lock -> switch to ${_innerSet.map((o) => o.name).join(',')}',
    );
    _applyOrientation();
  }

  void dispose() {
    _disposed = true;
    _hinge?.onOuterDisplay.removeListener(_applyOrientation);
    _verifyTimer?.cancel();
  }
}
