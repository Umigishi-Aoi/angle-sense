import 'package:flutter/foundation.dart';

/// 実機確認用の記録（TestFlight 版ではログを見る手段が乏しいため、アプリ内に溜めて画面で見る）。
///
/// 記録するもの: ヒンジの生の値（ラジアン・状態）、アプリの状態（AppLifecycleState）、画面サイズの変化。
/// 設定 →「診断（実機確認用）」で表示・コピーできる。
class DiagnosticsLog extends ChangeNotifier {
  DiagnosticsLog._();

  static final instance = DiagnosticsLog._();

  /// 古いものから消す上限。
  static const maxEntries = 1000;

  final List<DiagnosticsEntry> _entries = [];
  final List<DateTime> _hingeTimes = [];

  /// 最新のヒンジの生データ（Swift から届いたそのまま）。
  Map<String, Object?>? lastHinge;

  List<DiagnosticsEntry> get entries => List.unmodifiable(_entries);

  void add(String kind, String message) {
    _entries.add(DiagnosticsEntry(DateTime.now(), kind, message));
    if (_entries.length > maxEntries)
      _entries.removeRange(0, _entries.length - maxEntries);
    notifyListeners();
  }

  void hinge(Map<String, Object?> args) {
    lastHinge = args;
    final now = DateTime.now();
    _hingeTimes.add(now);
    _hingeTimes.removeWhere(
      (t) => now.difference(t) > const Duration(seconds: 1),
    );
    final rad = args['angleRad'];
    final deg = args['angleDeg'];
    add(
      'hinge',
      'status=${args['status']} available=${args['available']} '
          'rad=${rad is num ? rad.toStringAsFixed(4) : rad} '
          'deg=${deg is num ? deg.toStringAsFixed(1) : deg}'
          '${args.containsKey('orientationLocked') ? ' lock=${args['orientationLocked']}' : ''}',
    );
  }

  /// 直近 1 秒に届いたヒンジ更新の回数（更新頻度の目安）。
  int get hingeUpdatesPerSecond {
    final now = DateTime.now();
    return _hingeTimes
        .where((t) => now.difference(t) <= const Duration(seconds: 1))
        .length;
  }

  void clear() {
    _entries.clear();
    _hingeTimes.clear();
    notifyListeners();
  }

  /// コピー用のテキスト（古い順）。
  String export() => _entries.map((e) => e.toString()).join('\n');
}

@immutable
class DiagnosticsEntry {
  const DiagnosticsEntry(this.time, this.kind, this.message);

  final DateTime time;
  final String kind;
  final String message;

  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }

  @override
  String toString() => '$timeLabel [$kind] $message';
}
