/// App Store のレビュー依頼（StoreKit 2 の `AppStore.requestReview(in:)`）。
///
/// この API は Swift でしか書けないので、Swift 側に置き、Pigeon で呼ぶ。
library;

import 'src/messages.g.dart';

/// レビュー依頼を出す。
class StoreReview({StoreReviewHostApi? api}) {
  final StoreReviewHostApi _api = api ?? StoreReviewHostApi();

  /// iOS にレビュー依頼を頼む。表示されるかは iOS 次第で、結果は返らない。
  /// ボタンの操作に結び付けて呼ばないこと（Apple のガイドライン）。
  Future<void> request() => _api.requestReview();
}
