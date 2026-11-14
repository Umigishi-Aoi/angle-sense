/// iPhone Duo のヒンジ角度と端末の傾きを、Dart から直接読む
/// （FFIgen で UIKit / Core Motion を呼ぶ。プラットフォームチャネルを使わない）。
library;

export 'src/hinge.dart';
export 'src/tilt.dart';
