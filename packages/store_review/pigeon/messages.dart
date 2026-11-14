// Dart と Swift の間の API 定義。変更したら次で再生成する:
//   dart run pigeon --input pigeon/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'store_review',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: 'ios/store_review/Sources/store_review/Messages.g.swift',
  ),
)
@HostApi()
abstract class StoreReviewHostApi() {
  /// App Store のレビュー依頼を出すよう iOS に頼む。
  /// 実際に出すかどうかは iOS が決める（1 年に 3 回まで）。
  void requestReview();
}
