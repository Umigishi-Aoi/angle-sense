// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Angle Sense';

  @override
  String get quit => 'Quit';

  @override
  String get keepPlaying => 'Keep playing';

  @override
  String get playAgain => 'Play again';

  @override
  String get noReading => 'No reading';

  @override
  String resultLineNoReading(int target) {
    return '$target°→no reading';
  }

  @override
  String get homeTagline => 'Memorize the angle, then match it in the dark';

  @override
  String get homeAngleScale => 'Flat is 0° · right angle is 90°';

  @override
  String homeInput(String source) {
    return 'Input: $source';
  }

  @override
  String get inputHinge => 'Hinge (iPhone Duo)';

  @override
  String get inputTilt => 'Device tilt (accelerometer)';

  @override
  String get homeAngleUnknown => 'Angle: --';

  @override
  String get homeCurrentAngle => 'Current angle';

  @override
  String get homeBestNone => 'Best: --';

  @override
  String homeBest(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: 'Best: $score pts',
      one: 'Best: 1 pt',
    );
    return '$_temp0';
  }

  @override
  String homeSolo(int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: 'Solo ($rounds rounds)',
      one: 'Solo (1 round)',
    );
    return '$_temp0';
  }

  @override
  String homeBattle(int min, int max) {
    return 'Battle ($min–$max players)';
  }

  @override
  String get homeHowTo => 'How to play';

  @override
  String get homeWaitingSensor =>
      'Reading the angle… (devices without a sensor can\'t play)';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get howToTitle => 'How to play';

  @override
  String get howToHinge =>
      '1. Hold it in both hands like a book, facing the inner screen\n   (or set it on a table and open it like a laptop)\n\n2. Fully open and flat is 0°. The more you fold, the bigger the angle; a right angle is 90°\n\n3. Memorize the target, then the screen goes dark. Match the angle within 5 seconds and hold still\n\n• Targets are 10–80°. Closing past a right angle switches to the outer screen, so don\'t go that far\n• Near 0° the hinge springs fully open, so hold it in place with a finger';

  @override
  String get howToTilt =>
      '1. Hold the device sideways in both hands\n\n2. Lying flat, screen up, is 0°. Tilt it up to increase the angle; standing straight up is 90°\n\n3. Memorize the target, then the screen goes dark. Match the angle within 5 seconds and hold still\n\n• Targets are 10–80°\n• On a foldable iPhone, you play by folding it';

  @override
  String get ok => 'OK';

  @override
  String get settingsSound => 'Sound effects';

  @override
  String get settingsSoundNote => 'Muted in Silent mode';

  @override
  String get settingsTick => 'Ticks in the dark';

  @override
  String get settingsTickNote =>
      'A soft tick every second to help you keep time';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticsNote =>
      'Depending on your iPhone\'s Haptics setting, may not play in Silent mode';

  @override
  String get settingsDiagnostics => 'Diagnostics (debug)';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get gameQuitTitle => 'Quit the game?';

  @override
  String get gameQuitBattleBody =>
      'This player\'s turn ends here (\"No reading\" if not measured yet).';

  @override
  String get gameQuitSoloBody => 'Your progress won\'t be saved.';

  @override
  String gameRound(int current, int total) {
    return 'Round $current of $total';
  }

  @override
  String get pausedTitle => 'Paused';

  @override
  String get pausedRestartNote =>
      'Resuming restarts this round from the target';

  @override
  String get resume => 'Resume';

  @override
  String targetFigureLabel(int angle) {
    return 'Sample of the $angle° target';
  }

  @override
  String darkIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Going dark in $seconds seconds',
      one: 'Going dark in 1 second',
    );
    return '$_temp0';
  }

  @override
  String blindTargetLabel(int angle) {
    return 'Target $angle°';
  }

  @override
  String secondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds left',
      one: '1 second left',
    );
    return '$_temp0';
  }

  @override
  String legendTarget(int angle) {
    return 'Target $angle°';
  }

  @override
  String legendYou(int angle) {
    return 'You $angle°';
  }

  @override
  String get legendYouNoReading => 'You: no reading';

  @override
  String revealScore(String error, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Off by $error°  +$points pts',
      one: 'Off by $error°  +1 pt',
    );
    return '$_temp0';
  }

  @override
  String get revealNoReading => 'Couldn\'t read the angle  +0 pts';

  @override
  String get next => 'Next';

  @override
  String get toResults => 'See results';

  @override
  String get nextRound => 'Next round';

  @override
  String revealFigureLabel(int target, String you) {
    return 'Answer diagram. Target $target°, you $you';
  }

  @override
  String get zoomHeading => 'Zoom';

  @override
  String zoomLabel(String signed) {
    return 'Zoomed view, off by $signed';
  }

  @override
  String get resultTitle => 'Results';

  @override
  String get rankHeading => 'Rank';

  @override
  String resultScore(int score, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$score / $max pts',
      one: '$score / 1 pt',
    );
    return '$_temp0';
  }

  @override
  String get newBest => 'New personal best!';

  @override
  String bestScore(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: 'Best: $score pts',
      one: 'Best: 1 pt',
    );
    return '$_temp0';
  }

  @override
  String get home => 'Home';

  @override
  String get yourSenseGap => 'How off is your sense?';

  @override
  String roundShort(int n) {
    return 'R$n';
  }

  @override
  String roundSpoken(int n) {
    return 'Round $n';
  }

  @override
  String get battleTitle => 'Battle';

  @override
  String get battleSetupLead => 'Take turns — one try each';

  @override
  String get battleSetupRule =>
      'Everyone gets a different target. Closest wins';

  @override
  String playerUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'players',
      one: 'player',
    );
    return '$_temp0';
  }

  @override
  String playerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
    );
    return '$_temp0';
  }

  @override
  String get removePlayer => 'Remove a player';

  @override
  String get addPlayer => 'Add a player';

  @override
  String get battleStart => 'Start';

  @override
  String get battleQuitTitle => 'Quit the battle?';

  @override
  String get battleQuitBody => 'Results so far will be lost.';

  @override
  String playerName(int n) {
    return 'Player $n';
  }

  @override
  String playerShort(int n) {
    return 'P$n';
  }

  @override
  String turnProgress(int current, int total) {
    return 'Player $current of $total';
  }

  @override
  String turnOf(String name) {
    return '$name\'s turn';
  }

  @override
  String get nameHint => 'Name (optional)';

  @override
  String get handOverHint => 'Got the device? Tap Start';

  @override
  String get turnStart => 'Start';

  @override
  String get battleResultsHeading => 'Results';

  @override
  String place(int rank) {
    return '#$rank';
  }

  @override
  String get everyoneSenseGap => 'How off is everyone\'s sense?';

  @override
  String get toHome => 'Home';

  @override
  String battleResultLine(int target, int actual, String error) {
    return '$target°→$actual°  off $error°';
  }

  @override
  String get chartUnder => '← Under';

  @override
  String get chartSpotOn => 'Spot on';

  @override
  String get chartOver => 'Over →';

  @override
  String get sideSpotOn => 'spot on';

  @override
  String get sideOver => 'over';

  @override
  String get sideUnder => 'under';

  @override
  String chartRowLabel(
    String name,
    String signed,
    String side,
    String judgement,
  ) {
    return '$name, $signed $side, $judgement';
  }

  @override
  String chartRowNoReading(String name, String judgement) {
    return '$name, no reading, $judgement';
  }

  @override
  String get openPrompt => 'Open it up';

  @override
  String get openPromptBody =>
      'This game is played on the inner screen.\nOpen it wider than a right angle to go back.';
}
