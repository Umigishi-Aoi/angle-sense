import 'package:flutter/widgets.dart';

/// ホームに戻ったこと（上の画面が閉じたこと）を知るため。MaterialApp の navigatorObservers に登録する。
final routeObserver = RouteObserver<ModalRoute<void>>();
