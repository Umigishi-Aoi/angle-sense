import 'dart:async';

import 'package:flutter/foundation.dart';

/// 角度の入力源。ゲームロジックはこの抽象だけを見る。
///
/// 角度は常に 0〜180°。0°=平ら、90°=直角（お題は 10〜80°）。
/// - ヒンジ: 0°=全開（平ら） / 90°=直角 / 180°=閉じた（ヒンジの生の角度を 180° から引いた値）
/// - 傾き:   0°=画面を上にして平置き / 90°=立てた / 180°=画面を下にして平置き
abstract class AngleProvider {
  /// 保存キーなどに使う入力源の識別子（例: hinge / tilt）。
  String get id;

  /// 画面表示用の入力源名。
  String get label;

  /// 最新の角度（まだ値が来ていなければ null）。
  double? get latestAngle;

  /// 角度の更新ストリーム（broadcast）。
  Stream<double> get angleStream;

  /// アプリが iPhone Duo の外側の画面に移っているか（ヒンジ以外は常に false）。
  /// ゲームは内側の画面だけで遊ぶので、true の間は「開いて内側を見てね」と案内する。
  ValueListenable<bool> get onOuterDisplay;

  Future<void> start();

  Future<void> stop();
}

double clampAngle(double deg) => deg.clamp(0.0, 180.0).toDouble();
