import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/angle_provider.dart';
import '../services/diagnostics_log.dart';
import '../ui/retro_theme.dart';

/// 実機確認用の画面。全開で 180° になるか・開閉でアプリの状態がどう変わるかなどを見る。
class const DiagnosticsScreen({
  super.key,
  required final AngleProvider angleProvider,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final log = DiagnosticsLog.instance;
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('診断')),
      // 外側画面の右上にはカメラ・時刻の表示があるので、左右の安全領域を空ける。
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: log,
          builder: (context, _) {
            final h = log.lastHinge;
            final angle = angleProvider.latestAngle?.toStringAsFixed(1) ?? '--';
            final w = size.width.toStringAsFixed(0);
            final hgt = size.height.toStringAsFixed(0);
            final entries = log.entries.reversed.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('入力: ${angleProvider.label}'),
                        const Text('ゲームに使う角度（平ら=0° / 直角=90°）'),
                        Text(
                          '$angle°',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Retro.yellow,
                          ),
                        ),
                        if (h != null) ...[
                          Text('status: ${h['status']}'),
                          Text('available: ${h['available']}'),
                          Text('生の値: ${h['angleRad'] ?? '--'} rad'),
                        ],
                        Text('更新頻度: ${log.hingeUpdatesPerSecond} 回/秒'),
                        Text(
                          '画面: $w×$hgt '
                          '(×${dpr.toStringAsFixed(1)})',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '確認: ①閉じる→0° ②全開→180° ③開閉で状態の記録を見る',
                          style: TextStyle(color: Retro.dim),
                        ),
                        const SizedBox(height: 12),
                        // 外側画面の右上はカメラと重なるので、ボタンは上部バーでなくここに置く。
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => _copy(context, log),
                              child: const Text('記録をコピー'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: log.clear,
                              child: const Text('クリア'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      child: Text(
                        entries[i].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: entries[i].kind == 'hinge'
                              ? Retro.dim
                              : Retro.cyan,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, DiagnosticsLog log) async {
    await Clipboard.setData(ClipboardData(text: log.export()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${log.entries.length} 行をコピーしました')),
      );
    }
  }
}
