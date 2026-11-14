import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';
import '../services/angle_provider.dart';
import '../services/feedback.dart';
import '../ui/retro_theme.dart';
import '../widgets/angle_reveal.dart';
import '../widgets/deviation_chart.dart';
import 'game_screen.dart';

class const ResultScreen({
  super.key,
  required final List<RoundResult> results,
  required final int totalScore,
  required final Rank rank,
  required final AngleProvider angleProvider,

  /// 保存済みの最高点（今回分を反映後）。保存に失敗したときは null。
  final int? bestScore,
  final bool isNewBest = false,
}) extends StatefulWidget {
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState() extends State<ResultScreen> {
  Timer? _bestTimer;

  @override
  void dispose() {
    _bestTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final fb = context.feedback..play(Sfx.rank);
    if (widget.isNewBest) {
      _bestTimer = Timer(
        const Duration(milliseconds: 700),
        () => fb.play(Sfx.best),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.results;
    final totalScore = widget.totalScore;
    final rank = widget.rank;
    final angleProvider = widget.angleProvider;
    final bestScore = widget.bestScore;
    final isNewBest = widget.isNewBest;
    final theme = Theme.of(context);
    final retro = context.retroColors;
    final summary = <Widget>[
      Text('ランク', style: theme.textTheme.titleMedium),
      Text(
        rank.label,
        style: theme.textTheme.displayLarge?.copyWith(
          fontSize: 96,
          height: 1.1,
          color: theme.colorScheme.primary,
        ),
      ),
      Text(
        '$totalScore / ${results.length * Judgement.perfect.points} 点',
        style: theme.textTheme.headlineSmall,
      ),
      if (isNewBest)
        Text(
          '自己ベスト更新！',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        )
      else if (bestScore != null)
        Text('自己ベスト $bestScore 点', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      // 文字を大きくする設定で横に並ばないときは、2 段に折り返す。
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ホーム'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => GameScreen(angleProvider: angleProvider),
              ),
            ),
            child: const Text('もう一度'),
          ),
        ],
      ),
    ];
    // 5 問のズレを 1 本の物差しに並べ、自分の癖（いつも足りない・折りすぎ）を見せる。
    final details = ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
      children: [
        Text(
          'あなたの感覚のズレ',
          style: TextStyle(fontSize: 18, color: theme.colorScheme.secondary),
        ),
        const SizedBox(height: 4),
        DeviationChart(
          key: const ValueKey('result_chart'),
          rows: [
            for (var i = 0; i < results.length; i++) ('${i + 1}問', results[i]),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < results.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 56, child: Text('${i + 1}問')),
                Expanded(
                  child: Text(
                    _resultLine(results[i]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${results[i].judgement.label}  ${results[i].points}',
                  style: TextStyle(
                    color: retro.judgement(results[i].judgement),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('結果'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: summary,
                  ),
                ),
              ),
            ),
            Expanded(flex: 5, child: details),
          ],
        ),
      ),
    );
  }
}

/// 「45°→41°  -4.0°」。計測できなかったときは「45°→計測なし」。
String _resultLine(RoundResult r) {
  final target = '${r.target.round()}°';
  if (!r.measured) return '$target→計測なし';
  final signed = AngleZoom.signedLabel(r.target, r.actual!);
  return '$target→${r.actual!.round()}°  $signed';
}
