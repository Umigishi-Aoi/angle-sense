import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'angle_provider.dart';
import 'diagnostics_log.dart';

/// iPhone Duo のヒンジ角度（Swift 側 HingeAnglePlugin / UIHingeInteraction）。
class HingeAngleProvider({MethodChannel? channel}) implements AngleProvider {
  this {
    _channel.setMethodCallHandler(_onCall);
  }

  static const channelName = 'com.example.hinge_angle_game/hinge';

  final MethodChannel _channel = channel ?? const MethodChannel(channelName);
  final _controller = StreamController<double>.broadcast();
  final _availability = StreamController<bool>.broadcast();

  double? _latest;
  bool? _available;
  String _status = 'unknown';

  @override
  String get id => 'hinge';

  @override
  String get label => 'ヒンジ（iPhone Duo）';

  @override
  double? get latestAngle => _latest;

  @override
  Stream<double> get angleStream => _controller.stream;

  /// 最後に届いたヒンジ状態（closed / partiallyOpen / fullyOpen / unknown / unavailable）。
  String get status => _status;

  /// closed = アプリが外側の画面に移っている（実機確認 2026-11-06: closed と外側画面 466x678 が一致）。
  @override
  final ValueNotifier<bool> onOuterDisplay = ValueNotifier(false);

  /// 最初の更新でヒンジが取れたか。届くまで null。
  bool? get available => _available;

  Future<dynamic> _onCall(MethodCall call) async {
    if (call.method != 'onHinge') return null;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    DiagnosticsLog.instance.hinge(args);
    final available = args['available'] as bool? ?? false;
    _status = args['status'] as String? ?? 'unknown';
    onOuterDisplay.value = _status == 'closed';
    _available = available;
    _availability.add(available);
    final angle = (args['angleDeg'] as num?)?.toDouble();
    if (available && angle != null) {
      // Swift からは 0=閉じた / 180=全開 で届く。ゲームでは平ら=0° にするので反転する。
      _latest = clampAngle(180 - angle);
      _controller.add(_latest!);
    } else {
      // ヒンジが取れなくなったら古い角度で判定しないよう無効にする。
      _latest = null;
    }
    return null;
  }

  @override
  Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('start');
    } on MissingPluginException {
      // Swift 側が無いプラットフォーム（Android 等）。
      _available = false;
      _availability.add(false);
    }
  }

  /// start() 後、最初のヒンジ状態が届くまで待つ。
  /// UIHingeInteraction は「付けた時点の状態」で必ずハンドラを呼ぶ（ヘッダー記載）ため、
  /// timeout は Swift 側で interaction を付けられなかった場合の保険。
  Future<bool> waitForAvailability({
    Duration timeout = const Duration(seconds: 1),
  }) async {
    if (_available != null) return _available!;
    try {
      return await _availability.stream.first.timeout(timeout);
    } on TimeoutException {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // 何もしない
    }
  }
}
