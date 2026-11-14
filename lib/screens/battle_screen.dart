import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';
import '../services/angle_provider.dart';
import '../services/feedback.dart';
import '../ui/retro_theme.dart';
import '../widgets/deviation_chart.dart';
import '../widgets/inner_display_guard.dart';
import 'game_screen.dart';

/// バトルの人数（2〜10人）を決める画面。
class BattleSetupScreen extends StatefulWidget {
  const BattleSetupScreen({super.key, required this.angleProvider});

  final AngleProvider angleProvider;

  static const minPlayers = 2;
  static const maxPlayers = 10;

  @override
  State<BattleSetupScreen> createState() => _BattleSetupScreenState();
}

class _BattleSetupScreenState extends State<BattleSetupScreen> {
  int _players = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('バトル')),
      body: InnerDisplayGuard(
        angleProvider: widget.angleProvider,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '1人1回ずつ、順番に角度を合わせます',
                  style: TextStyle(fontSize: 18),
                ),
                const Text('お題は1人ずつちがいます。誤差の小さい人が勝ち'),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: _players > BattleSetupScreen.minPlayers
                          ? () => setState(() => _players--)
                          : null,
                      child: const Text('－'),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        '$_players 人',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Retro.yellow,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _players < BattleSetupScreen.maxPlayers
                          ? () => setState(() => _players++)
                          : null,
                      child: const Text('＋'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => BattleScreen(
                        angleProvider: widget.angleProvider,
                        playerCount: _players,
                      ),
                    ),
                  ),
                  child: const Text('はじめる'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 1人の結果。
class BattleEntry {
  const BattleEntry({
    required this.name,
    required this.result,
    required this.chartLabel,
  });

  final String name;
  final RoundResult result;

  /// ズレ図の行の名前（名前を入れた人はその名前、入れていない人は P1 など）。
  final String chartLabel;

  /// 順位づけ用の誤差。計測なしは最下位。
  double get sortError => result.error ?? double.infinity;
}

/// 誤差の小さい順に並べ、同じ誤差は同じ順位にする（1, 1, 3, …）。
List<(int, BattleEntry)> rankEntries(List<BattleEntry> entries) {
  final sorted = [...entries]
    ..sort((a, b) => a.sortError.compareTo(b.sortError));
  final out = <(int, BattleEntry)>[];
  for (var i = 0; i < sorted.length; i++) {
    final rank = i > 0 && sorted[i].sortError == sorted[i - 1].sortError
        ? out[i - 1].$1
        : i + 1;
    out.add((rank, sorted[i]));
  }
  return out;
}

/// 順番に1回ずつ計測し、最後に順位を出す。
class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.angleProvider,
    required this.playerCount,
  });

  final AngleProvider angleProvider;
  final int playerCount;

  /// 名前の入力は任意。最大文字数（結果の表・ズレ図・見出しで 1 行に収めるため）。
  static const maxNameLength = 6;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final _entries = <BattleEntry>[];
  final _nameController = TextEditingController();
  bool _playing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _current => _entries.length; // 0 始まり
  bool get _done => _entries.length >= widget.playerCount;
  String _name(int i) => 'プレイヤー${i + 1}';

  Future<void> _startTurn() async {
    if (_playing) return; // 連打で2つ積まれるのを防ぐ
    _playing = true;
    final index = _current;
    // 日本語入力の変換中は文字数制限が効かないことがあるので、ここでも切る。
    final typed = _nameController.text
        .trim()
        .characters
        .take(BattleScreen.maxNameLength)
        .toString();
    final name = typed.isEmpty ? _name(index) : typed;
    final chartLabel = typed.isEmpty ? 'P${index + 1}' : typed;
    FocusScope.of(context).unfocus();
    _nameController.clear();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          angleProvider: widget.angleProvider,
          rounds: 1,
          title: name,
          onFinished: (results) {
            Navigator.of(context).pop();
            setState(
              () => _entries.add(
                BattleEntry(
                  name: name,
                  result: results.single,
                  chartLabel: chartLabel,
                ),
              ),
            );
            if (_done) context.feedback.play(Sfx.rank);
          },
        ),
      ),
    );
    _playing = false;
  }

  Future<void> _confirmQuit() async {
    if (_done) {
      Navigator.of(context).pop();
      return;
    }
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バトルをやめますか？'),
        content: const Text('ここまでの結果は消えます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('続ける'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('やめる'),
          ),
        ],
      ),
    );
    if (quit == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('バトル'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmQuit,
          ),
        ),
        body: InnerDisplayGuard(
          angleProvider: widget.angleProvider,
          child: SafeArea(child: _done ? _ranking(context) : _turn(context)),
        ),
      ),
    );
  }

  Widget _turn(BuildContext context) {
    final theme = Theme.of(context);
    final last = _entries.isEmpty ? null : _entries.last;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (last != null) ...[
              Text(
                '${last.name}: ${last.result.judgement.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  color: Retro.judgement(last.result.judgement),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              '${_current + 1} / ${widget.playerCount} 人目',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '${_name(_current)} の番',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Retro.yellow,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 280,
              child: TextField(
                key: const ValueKey('battle_name'),
                controller: _nameController,
                maxLength: BattleScreen.maxNameLength,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '名前（入れなくてもOK）',
                  counterText: '',
                  isDense: true,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Retro.line),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('本体を受け取ったら、スタートを押してね'),
            const SizedBox(height: 24),
            FilledButton(onPressed: _startTurn, child: const Text('スタート')),
          ],
        ),
      ),
    );
  }

  Widget _ranking(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = rankEntries(_entries);
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          '結果発表',
          style: theme.textTheme.headlineMedium?.copyWith(color: Retro.yellow),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final (rank, e) in ranked)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(
                                '$rank位',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: rank == 1 ? Retro.yellow : Retro.text,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    e.result.measured
                                        ? '${e.result.target.round()}°→${e.result.actual!.round()}°  '
                                              '誤差${e.result.error!.toStringAsFixed(1)}°'
                                        : '${e.result.target.round()}°→計測なし',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Retro.judgement(
                                        e.result.judgement,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 24, left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'みんなの感覚のズレ',
                        style: TextStyle(fontSize: 18, color: Retro.cyan),
                      ),
                      const SizedBox(height: 4),
                      DeviationChart(
                        rows: [
                          for (final e in _entries) (e.chartLabel, e.result),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => BattleScreen(
                      angleProvider: widget.angleProvider,
                      playerCount: widget.playerCount,
                    ),
                  ),
                ),
                child: const Text('もう一度'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ホームへ'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
