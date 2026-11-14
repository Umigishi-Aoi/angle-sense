# 英語ローカライズ レビュー表

`lib/l10n/app_ja.arb`（元の文言）と `lib/l10n/app_en.arb` の対訳。画面ごとに並べています。
`{name}` は差し込まれる値、`{x, plural, ...}` は数で形が変わる部分（英語の単数・複数）です。
診断画面（開発版だけに出る `lib/screens/diagnostics_screen.dart`）は日本語のままです。
判定（PERFECT / GREAT / GOOD / MISS）とランク（S / A / B / C）はどちらの言語でも同じ表記です。

キー数: 93


## アプリ全体

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `appTitle` | ピタッとアングル | Angle Sense | アプリ名（タイトル・ライセンス画面） |
| `quit` | やめる | Quit | 「やめる」ボタン・ツールチップ |
| `keepPlaying` | 続ける | Keep playing | 中断確認で続けるボタン |
| `playAgain` | もう一度 | Play again | もう一度遊ぶボタン |
| `noReading` | 計測なし | No reading | 角度が取れなかったときの表示 |
| `resultLineNoReading` | {target}°→計測なし | {target}°→no reading | 結果の行（計測なし）。target=お題の角度 |

## ホーム

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `homeTagline` | 目標の角度を覚えて、暗闇の中で合わせよう | Memorize the angle, then match it in the dark | ホームの説明（1行目） |
| `homeAngleScale` | 平らが 0°・直角が 90° | Flat is 0° · right angle is 90° | ホームの角度の基準 |
| `homeInput` | 入力: {source} | Input: {source} | 入力源の表示。source=入力源の名前 |
| `inputHinge` | ヒンジ（iPhone Duo） | Hinge (iPhone Duo) | 入力源の名前（ヒンジ） |
| `inputTilt` | 端末の傾き（加速度センサー） | Device tilt (accelerometer) | 入力源の名前（傾き） |
| `homeAngleUnknown` | 角度: -- | Angle: -- | 角度がまだ取れていないとき |
| `homeCurrentAngle` | 今の角度 | Current angle | 今の角度の読み上げラベル |
| `homeBestNone` | 自己ベスト: -- | Best: -- | 自己ベストなし |
| `homeBest` | {score, plural, other{自己ベスト: {score} 点}} | {score, plural, =1{Best: 1 pt} other{Best: {score} pts}} | 自己ベスト。score=点数 |
| `homeSolo` | {rounds, plural, other{ひとりで（{rounds}問）}} | {rounds, plural, =1{Solo (1 round)} other{Solo ({rounds} rounds)}} | ひとりで遊ぶボタン。rounds=問題数 |
| `homeBattle` | バトル（{min}〜{max}人） | Battle ({min}–{max} players) | バトルボタン。min/max=人数 |
| `homeHowTo` | あそびかた・持ち方 | How to play | あそびかたボタン |
| `homeWaitingSensor` | 角度を取得しています…（センサーのない端末では遊べません） | Reading the angle… (devices without a sensor can't play) | 角度の取得待ち |
| `settingsTooltip` | 設定 | Settings | 設定ボタンのツールチップ |

## あそびかた

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `howToTitle` | あそびかた | How to play | あそびかたダイアログの見出し |
| `howToHinge` | 1. 内側の画面を見ながら、本を読むように両手で持つ<br>   （机に置いてノートパソコンのように開いてもOK）<br><br>2. 平らに開いた状態が 0°。折るほど大きくなり、直角が 90°<br><br>3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく<br><br>・お題は 10〜80°。直角より閉じると外側の画面に切り替わるので、そこまでは閉じない<br>・0° に近い角度はバネで開ききるので、指で支えて止める | 1. Hold it in both hands like a book, facing the inner screen<br>   (or set it on a table and open it like a laptop)<br><br>2. Fully open and flat is 0°. The more you fold, the bigger the angle; a right angle is 90°<br><br>3. Memorize the target, then the screen goes dark. Match the angle within 5 seconds and hold still<br><br>• Targets are 10–80°. Closing past a right angle switches to the outer screen, so don't go that far<br>• Near 0° the hinge springs fully open, so hold it in place with a finger | あそびかた（折りたたみ iPhone） |
| `howToTilt` | 1. 本体を横向きにして、両手で持つ<br><br>2. 画面を上にして平らに置いた状態が 0°。起こすほど大きくなり、まっすぐ立てると 90°<br><br>3. お題の角度を覚えたら、画面が暗くなる。5秒のうちに合わせて、そのまま止めておく<br><br>・お題は 10〜80°<br>・折りたたみ iPhone では、本体を折る角度で遊べます | 1. Hold the device sideways in both hands<br><br>2. Lying flat, screen up, is 0°. Tilt it up to increase the angle; standing straight up is 90°<br><br>3. Memorize the target, then the screen goes dark. Match the angle within 5 seconds and hold still<br><br>• Targets are 10–80°<br>• On a foldable iPhone, you play by folding it | あそびかた（普通の iPhone / iPad） |
| `ok` | OK | OK | ダイアログを閉じるボタン |

## 設定

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `settingsSound` | 効果音 | Sound effects | 設定: 効果音 |
| `settingsSoundNote` | マナーモード中は鳴りません | Muted in Silent mode | 設定: 効果音の補足 |
| `settingsTick` | 暗転中のカウント音 | Ticks in the dark | 設定: 暗転中のカウント音 |
| `settingsTickNote` | 1秒ごとの小さな音。リズムで時間が分かります | A soft tick every second to help you keep time | 設定: カウント音の補足 |
| `settingsHaptics` | 振動 | Haptics | 設定: 振動 |
| `settingsHapticsNote` | iPhoneの「触覚」設定によってはマナーモード中に鳴りません | Depending on your iPhone's Haptics setting, may not play in Silent mode | 設定: 振動の補足 |
| `settingsDiagnostics` | 診断（実機確認用） | Diagnostics (debug) | 設定: 診断画面（開発版のみ表示） |
| `settingsLicenses` | ライセンス | Licenses | 設定: ライセンス |

## ゲーム

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `gameQuitTitle` | ゲームをやめますか？ | Quit the game? | ゲーム中断の確認 |
| `gameQuitBattleBody` | やめると、この人の番はここで終わりです（計測前なら「計測なし」）。 | This player's turn ends here ("No reading" if not measured yet). | バトル中の中断の説明 |
| `gameQuitSoloBody` | ここまでの結果は保存されません。 | Your progress won't be saved. | ひとりで遊ぶときの中断の説明 |
| `gameRound` | 第 {current} / {total} 問 | Round {current} of {total} | 何問目か。current=今の問題 / total=問題数 |
| `pausedTitle` | 一時停止中 | Paused | 一時停止の見出し |
| `pausedRestartNote` | 再開すると、この問題をお題からやり直します | Resuming restarts this round from the target | 一時停止の補足 |
| `resume` | 再開 | Resume | 再開ボタン |
| `targetFigureLabel` | お題 {angle}° の見本の図 | Sample of the {angle}° target | お題の見本の図の読み上げ。angle=お題の角度 |
| `darkIn` | {seconds, plural, other{あと {seconds} 秒で暗くなる}} | {seconds, plural, =1{Going dark in 1 second} other{Going dark in {seconds} seconds}} | お題表示中の残り秒数 |
| `blindTargetLabel` | お題 {angle}° | Target {angle}° | 暗転中のお題の読み上げ |
| `secondsLeft` | {seconds, plural, other{残り {seconds} 秒}} | {seconds, plural, =1{1 second left} other{{seconds} seconds left}} | 残り秒数の読み上げ |
| `legendTarget` | 目標 {angle}° | Target {angle}° | 答え合わせの凡例（目標） |
| `legendYou` | あなた {angle}° | You {angle}° | 答え合わせの凡例（あなた） |
| `legendYouNoReading` | あなた 計測なし | You: no reading | 答え合わせの凡例（あなた・計測なし） |
| `revealScore` | {points, plural, other{誤差 {error}°  +{points}点}} | {points, plural, =1{Off by {error}°  +1 pt} other{Off by {error}°  +{points} pts}} | 誤差と得点。error=誤差（小数1桁の文字列） |
| `revealNoReading` | 角度を取得できませんでした  +0点 | Couldn't read the angle  +0 pts | 角度が取れなかったとき |
| `next` | 次へ | Next | バトルの最後の問題の次へ |
| `toResults` | 結果へ | See results | ひとりで遊ぶ最後の問題の次へ |
| `nextRound` | 次の問題 | Next round | 次の問題へ |
| `revealFigureLabel` | 答え合わせの図。目標 {target}°、あなた {you} | Answer diagram. Target {target}°, you {you} | 答え合わせの図の読み上げ。you=あなたの角度（「41°」か「計測なし」） |
| `zoomHeading` | 拡大 | Zoom | 拡大図の見出し |
| `zoomLabel` | 拡大図、ズレ {signed} | Zoomed view, off by {signed} | 拡大図の読み上げ。signed=符号つきのズレ（+4.0° など） |

## 結果

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `resultTitle` | 結果 | Results | 結果画面の見出し |
| `rankHeading` | ランク | Rank | ランクの見出し |
| `resultScore` | {max, plural, other{{score} / {max} 点}} | {max, plural, =1{{score} / 1 pt} other{{score} / {max} pts}} | 合計点 / 満点 |
| `newBest` | 自己ベスト更新！ | New personal best! | 自己ベスト更新 |
| `bestScore` | {score, plural, other{自己ベスト {score} 点}} | {score, plural, =1{Best: 1 pt} other{Best: {score} pts}} | 自己ベスト（更新しなかったとき） |
| `home` | ホーム | Home | ホームへ戻るボタン（結果） |
| `yourSenseGap` | あなたの感覚のズレ | How off is your sense? | ズレ図の見出し（ひとり） |
| `roundShort` | {n}問 | R{n} | ズレ図・結果の行の問題番号 |
| `roundSpoken` | {n}問 | Round {n} | 問題番号の読み上げ（VoiceOver） |

## バトル

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `battleTitle` | バトル | Battle | バトルの見出し |
| `battleSetupLead` | 1人1回ずつ、順番に角度を合わせます | Take turns — one try each | バトル設定の説明（1行目） |
| `battleSetupRule` | お題は1人ずつちがいます。誤差の小さい人が勝ち | Everyone gets a different target. Closest wins | バトル設定の説明（2行目） |
| `playerCount` | {count, plural, other{{count} 人}} | {count, plural, =1{1 player} other{{count} players}} | 人数（読み上げ用） |
| `playerUnit` | {count, plural, other{人}} | {count, plural, =1{player} other{players}} | 人数の単位（大きな数字の下に小さく） |
| `removePlayer` | 1人減らす | Remove a player | 人数を減らすボタンの読み上げ |
| `addPlayer` | 1人増やす | Add a player | 人数を増やすボタンの読み上げ |
| `battleStart` | はじめる | Start | バトル開始ボタン |
| `battleQuitTitle` | バトルをやめますか？ | Quit the battle? | バトル中断の確認 |
| `battleQuitBody` | ここまでの結果は消えます。 | Results so far will be lost. | バトル中断の説明 |
| `playerName` | プレイヤー{n} | Player {n} | 名前を入れなかった人の名前 |
| `playerShort` | P{n} | P{n} | ズレ図の短い名前 |
| `turnProgress` | {current} / {total} 人目 | Player {current} of {total} | 何人目か |
| `turnOf` | {name} の番 | {name}'s turn | 誰の番か |
| `nameHint` | 名前（入れなくてもOK） | Name (optional) | 名前の入力欄のヒント |
| `handOverHint` | 本体を受け取ったら、スタートを押してね | Got the device? Tap Start | 本体を渡したあとの案内 |
| `turnStart` | スタート | Start | 自分の番を始めるボタン |
| `battleResultsHeading` | 結果発表 | Results | 結果発表の見出し |
| `place` | {rank}位 | #{rank} | 順位 |
| `everyoneSenseGap` | みんなの感覚のズレ | How off is everyone's sense? | ズレ図の見出し（バトル） |
| `toHome` | ホームへ | Home | ホームへ戻るボタン（バトル） |
| `battleResultLine` | {target}°→{actual}°  誤差{error}° | {target}°→{actual}°  off {error}° | 結果の行。error=誤差（小数1桁の文字列） |

## ズレ図

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `chartUnder` | ← 足りない | ← Under | ズレ図の左端（足りない） |
| `chartSpotOn` | ピタッ | Spot on | ズレ図の真ん中（ピタッ） |
| `chartOver` | 折りすぎ → | Over → | ズレ図の右端（折りすぎ） |
| `sideSpotOn` | ピタッ | spot on | ズレの向きの読み上げ（ぴったり） |
| `sideOver` | 折りすぎ | over | ズレの向きの読み上げ（大きすぎ） |
| `sideUnder` | 足りない | under | ズレの向きの読み上げ（小さすぎ） |
| `chartRowLabel` | {name}、{signed} {side}、{judgement} | {name}, {signed} {side}, {judgement} | ズレ図の 1 行の読み上げ。judgement=PERFECT など |
| `chartRowNoReading` | {name}、計測なし、{judgement} | {name}, no reading, {judgement} | ズレ図の 1 行の読み上げ（計測なし） |

## 外側の画面

| キー | 日本語 | English | 説明 |
| --- | --- | --- | --- |
| `openPrompt` | ひらいてね | Open it up | 外側の画面に移ったときの見出し |
| `openPromptBody` | このゲームは内側の画面で遊びます。<br>直角より大きく開くと内側の画面に戻ります。 | This game is played on the inner screen.<br>Open it wider than a right angle to go back. | 外側の画面に移ったときの説明 |

## ホーム画面のアプリ名（iOS）

| 項目 | 日本語 | English |
| --- | --- | --- |
| CFBundleDisplayName（`ios/Runner/{ja,en}.lproj/InfoPlist.strings`） | ピタッとアングル | Angle Sense |

## 確認したい点（英語の言い回し）

- `yourSenseGap` / `everyoneSenseGap`: 「感覚のズレ」は "How off is your sense?" / "How off is everyone's sense?" に決定（2026/11/14）。
- `place`: 順位は "1st / 2nd" ではなく "#1 / #2" にしました（gen-l10n の plural は =3 を書けないため序数が作れず、幅 52px にも収まるため）。
- `playerCount` / `playerUnit`: バトル設定は、英語だけ数字を大きく・単位を小さく下に添える形（日本語は「2 人」の 1 行のまま。2026/11/14）。読み上げは「2 人」「2 players」。
- `settingsHaptics`: iOS の設定名に合わせて「振動」を "Haptics" にしました。"Vibration" の方が伝わりやすければ差し替えます。
- `homeAngleScale`: ヒンジでも傾きでも同じ文言なので "Flat is 0° · right angle is 90°" としました（傾きでは「立てると 90°」の意味）。
- `handOverHint`: 「本体を受け取ったら、スタートを押してね」→ "Got the device? Tap Start"。
- `roundShort`: 結果の行番号「1問」→ "R1"（2026/11/14 変更。"#1" はバトルの順位と同じ書き方で紛らわしいため）。読み上げは `roundSpoken` の "Round 1"。
