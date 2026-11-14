import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// すべてのテストで、端末の言語を日本語にする（テストの既定は en-US）。
///
/// アプリの文言は日本語が元で、既存のテストは日本語の表示を確かめている。
/// 英語の表示を試すテストは、テストの中で `localesTestValue` を英語に変える。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = const [
      Locale('ja'),
    ];
  });
  await testMain();
}
