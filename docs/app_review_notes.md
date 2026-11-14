# App Review 用メモ（2026/11/14 Guideline 2.1 Information Needed への回答）

App Store Connect →「App Review に関する情報」→「メモ」に下の英文を貼る。画面収録は同じ欄の添付、または App Review への返信に添付する。

## 画面収録の撮り方（実機・最新 iOS）

1. 実機を最新の iOS に更新しておく（設定 → 一般 → ソフトウェアアップデート）
2. コントロールセンターの「画面収録」で録画開始
3. **ホーム画面でアプリのアイコンをタップして起動するところから**撮る
4. ひとりで（5問）を最後まで遊ぶ → 結果画面
5. ホームに戻り、バトルを 2 人で 1 回ずつ → 結果発表
6. ホームの設定（音・振動・ライセンス）を開いて見せる
7. 録画停止。写真アプリから保存

ログイン・課金・投稿機能はないので、それらの場面は不要。

## メモ欄に貼る英文

```
Thank you for reviewing Pitatto Angle.

1. Screen recording
A screen recording captured on a physical iPhone running the latest iOS is attached. It starts from launching the app and shows Solo mode (5 rounds) to the result screen, then Battle mode with 2 players to the ranking screen.
2. Purpose and target audience
Pitatto Angle is a casual party game about angle sense. The concept is "your sense of an angle is different from other people's." The app shows a target angle (for example 45 degrees), then the screen goes dark, and the player bends a foldable iPhone (or tilts a regular iPhone) to that angle without looking. The app then reveals how far off the player was.
Target audience: anyone, including families and friends playing together by passing one device around. It provides a quick, offline game that makes people laugh about how differently everyone perceives the same angle.

3. How to use the main features (no login, no account, no sample files needed)
- Hold the iPhone in landscape.
  - On iPhone Duo (foldable): open the device like a book. Flat (fully open) = 0 degrees, a right angle = 90 degrees. The app reads the hinge angle.
  - On other iPhones: hold the device in landscape. Screen facing up and lying flat = 0 degrees, standing straight up = 90 degrees. The app reads the tilt from the motion sensors.
- Solo: tap "ひとりで" (Solo). A target angle (10-80 degrees) is shown for 3 seconds, then the screen goes dark for 5 seconds. Move the device to the target angle during the dark period; the angle is locked automatically when the countdown ends, and the result is shown. 5 rounds per game.
- Battle: tap "バトル" (Battle), add 2-10 players, and pass the device around. Each player measures once, and the players are ranked by the smallest error.
- Settings (gear icon on the home screen): sound, vibration, and licenses.

4. External services
None. The app makes no network connections. It has no login, no ads, no analytics, no payments, and no AI services. Best scores are stored only on the device.

5. Regional differences
None. The app works the same in all regions. The UI is in Japanese.

6. Third-party material
The app includes the font "DotGothic16", licensed under the SIL Open Font License 1.1. The license text is bundled in the app and shown on the Licenses screen. All sound effects and the app icon were created by the developer. The app does not operate in a regulated industry.
```

## 送る前に確かめること

- 英文 3. の内容はコードで確認済み（お題 3 秒・暗転 5 秒で自動ロック、ホームの歯車アイコン→音・振動・ライセンス、ライセンスに DotGothic16 の OFL を表示）
- 録画に映る内容と英文 1. の説明が合っているか
