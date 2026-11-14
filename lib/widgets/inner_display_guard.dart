import 'package:material_ui/material_ui.dart';

import '../services/angle_provider.dart';

/// iPhone Duo で外側の画面に移ったときに「開いて内側を見てね」と出す。
///
/// 画面の切り替えは iOS が開き具合で決め、アプリからは止められない（iOS 27.2 SDK 調査 2026-11-06）。
/// ゲームは内側の画面だけで遊ぶ設計なので、外側に来たら中身の代わりに案内を出す。
class const InnerDisplayGuard({
  super.key,
  required final AngleProvider angleProvider,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: angleProvider.onOuterDisplay,
      child: child,
      builder: (context, outer, child) => Stack(
        children: [
          child!,
          if (outer) const Positioned.fill(child: _OuterNotice()),
        ],
      ),
    );
  }
}

class const _OuterNotice() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ひらいてね',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'このゲームは内側の画面で遊びます。\n直角より大きく開くと内側の画面に戻ります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
