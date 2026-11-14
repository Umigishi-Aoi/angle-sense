import 'package:material_ui/material_ui.dart';

import '../game/scoring.dart';
import '../l10n/l10n.dart';
import '../services/angle_provider.dart';
import '../services/feedback.dart';
import '../ui/retro_theme.dart';
import '../widgets/deviation_chart.dart';
import '../widgets/inner_display_guard.dart';
import 'game_screen.dart';

/// バトルの人数（2〜10人）を決める画面。
class const BattleSetupScreen({
  super.key,
  required final AngleProvider angleProvider,
}) extends StatefulWidget {
  static const minPlayers = 2;
  static const maxPlayers = 10;

  @override
  State<BattleSetupScreen> createState() => _BattleSetupScreenState();
}

class _BattleSetupScreenState() extends State<BattleSetupScreen> {
  int _players = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countStyle = theme.textTheme.displaySmall?.copyWith(
      color: theme.colorScheme.primary,
    );
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.battleTitle)),
      body: InnerDisplayGuard(
        angleProvider: widget.angleProvider,
        child: SafeArea(
          child: Center(
            // 文字を大きくする設定で収まらないときだけスクロールする。
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.battleSetupLead,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(l10n.battleSetupRule),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: _players > BattleSetupScreen.minPlayers
                            ? () => setState(() => _players--)
                            : null,
                        // 記号だけでは読み上げで意味が伝わらないので、ボタンの説明を付ける。
                        child: Semantics(
                          label: l10n.removePlayer,
                          excludeSemantics: true,
                          child: const Text('－'),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        // 日本語は「2 人」を 1 行で。英語は「2 players」を 1 行にすると
                        // ボタンの間で窮屈になるので、数字を大きく・単位を小さく下に添える。
                        // 読み上げはどちらも「2 人」「2 players」の 1 つにまとめる。
                        child: Semantics(
                          label: l10n.playerCount(_players),
                          excludeSemantics: true,
                          // 文字を大きくする設定で幅に入らないときは、折り返さずに縮める。
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _stackPlayerUnit(context)
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$_players', style: countStyle),
                                      Text(
                                        l10n.playerUnit(_players),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    l10n.playerCount(_players),
                                    style: countStyle,
                                  ),
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _players < BattleSetupScreen.maxPlayers
                            ? () => setState(() => _players++)
                            : null,
                        child: Semantics(
                          label: l10n.addPlayer,
                          excludeSemantics: true,
                          child: const Text('＋'),
                        ),
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
                    child: Text(l10n.battleStart),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1人の結果。
class const BattleEntry({
  required final String name,
  required final RoundResult result,

  /// ズレ図の行の名前（名前を入れた人はその名前、入れていない人は P1 など）。
  required final String chartLabel,
}) {
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
class const BattleScreen({
  super.key,
  required final AngleProvider angleProvider,
  required final int playerCount,
}) extends StatefulWidget {
  /// 名前の入力は任意。最大文字数（結果の表・ズレ図・見出しで 1 行に収めるため）。
  static const maxNameLength = 6;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState() extends State<BattleScreen> {
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
  String _name(int i) => context.l10n.playerName(i + 1);

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
    final chartLabel = typed.isEmpty
        ? context.l10n.playerShort(index + 1)
        : typed;
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
        title: Text(context.l10n.battleQuitTitle),
        content: Text(context.l10n.battleQuitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.keepPlaying),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.quit),
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
          title: Text(context.l10n.battleTitle),
          leading: IconButton(
            tooltip: context.l10n.quit,
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
    final l10n = context.l10n;
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
                  color: context.retroColors.judgement(last.result.judgement),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              l10n.turnProgress(_current + 1, widget.playerCount),
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              l10n.turnOf(_name(_current)),
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
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
                  hintText: l10n.nameHint,
                  counterText: '',
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.handOverHint),
            const SizedBox(height: 24),
            FilledButton(onPressed: _startTurn, child: Text(l10n.turnStart)),
          ],
        ),
      ),
    );
  }

  Widget _ranking(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final ranked = rankEntries(_entries);
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.battleResultsHeading,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
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
                                l10n.place(rank),
                                style: TextStyle(
                                  fontSize: 22,
                                  color: rank == 1
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
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
                                    _resultLine(l10n, e.result),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.retroColors.judgement(
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
                      Text(
                        l10n.everyoneSenseGap,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.secondary,
                        ),
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
                child: Text(l10n.playAgain),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.toHome),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 「45°→41°  誤差4.0°」。計測できなかったときは「45°→計測なし」。
String _resultLine(AppLocalizations l10n, RoundResult r) {
  final target = r.target.round();
  if (!r.measured) return l10n.resultLineNoReading(target);
  final error = r.error!.toStringAsFixed(1);
  return l10n.battleResultLine(target, r.actual!.round(), error);
}

/// 人数の単位を数字の下に分けて出すか（日本語は「2 人」の 1 行のまま）。
bool _stackPlayerUnit(BuildContext context) =>
    Localizations.localeOf(context).languageCode != 'ja';
