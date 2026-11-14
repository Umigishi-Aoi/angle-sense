import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// アプリの文言と、Material / Cupertino / Widgets の組み込みの文言（文字選択メニュー・
/// ライセンス画面・戻るボタンの説明など）の delegates。
///
/// Flutter 3.50 では flutter_localizations の Material / Cupertino の
/// delegate は非推奨。material_ui の [GlobalMaterialLocalizations.delegates] は
/// Cupertino と Widgets の分も含む。
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// 端末の言語の優先順に、対応している言語（日本語・英語）を探す。どれもなければ英語。
///
/// iOS がホーム画面のアプリ名（InfoPlist.strings）を選ぶのと同じ考え方
/// （優先順で最初に対応している言語）にして、アプリ名と中身の言語をそろえる。
Locale resolveAppLocale(
  List<Locale>? preferred,
  Iterable<Locale> supported,
) {
  for (final locale in preferred ?? const <Locale>[]) {
    for (final s in supported) {
      if (s.languageCode == locale.languageCode) return s;
    }
  }
  return const Locale('en');
}

extension AppLocalizationsContext on BuildContext {
  /// 今の言語の文言。
  AppLocalizations get l10n => AppLocalizations.of(this);
}
