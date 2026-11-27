# ことばの森

クリーム色と緑を基調にした日本語単語パズル。Flutter / DartでAndroid・iOS共通のアプリ本体を実装しています。

## 現在の状態

Flutter 3.47.7 / Dart 3.13.5とAndroid SDKを導入済み。`flutter analyze`は問題なし、テスト16件・デバッグAPKビルドが成功しました。

パズルは中央の履歴と下部の入力パネルに分離。回答は1マスずつ約0.5〜0.75秒で反転し、正解時は育った森と次問ボタンを表示します。入力場所を鉛筆で示し、「1文字けす」で修正できます。キーボード中は見出しを畳み、小画面では履歴だけを縮めて最新の回答を表示します。ホームも実際の成長状態を描画し、すべてのメニューを大きなボタンにしています。

Androidエミュレーターで日本語フリック入力・削除・確定・回答を操作し、「ううう」を「うさぎ」に対して緑1つ・グレー2つと判定すること、正解・森の成長保存・再起動後の復元・次問への遷移を確認しました。最終版で4文字の入力・回答・保存と、320dp幅のキーボード中に履歴全体が読めることも確認済み。自動テストは文字拡大・3文字/6文字・長い履歴・IME変換途中・反転中の再回答防止・ヒント展開も含みます。実端末とTalkBackの操作確認は未実施です。

画面画像は `build/verification/` 内の `v3-home.png`、`v3-puzzle.png`、`v3-history.png`、`v3-history-keyboard.png`、`v3-delete.png`、`v3-flip.png`、`v3-win.png`、`v3-next.png`。入力と履歴の画像は最終版、正解・遷移の画像は同じゲームロジックの検証時点です。

## 絵本の森と動き

森は外部画像や絵文字を使わないオリジナルのCanvas描画です。輪郭を手描き風のパスで作り、空・木立・小道・花・キノコ・蝶・動物を重ねています。成長に応じて景色が変化し、葉の揺れ・蝶の飛行・花が開く動きは森の描画部分だけを更新します。パズル中の森は静止させ、入力への集中を保ちます。

設定の「動きを減らす」は保存され、端末のアニメーション軽減設定にも対応します。旧保存データの進行状況も保持します。成長段階の描画、動作と停止、設定保存、既存パズルを含む16件のテストとAndroidビルドを確認済み。画像は `build/verification/storybook-home.png` と `storybook-growth-0.png` / `2.png` / `4.png` / `8.png`（成長画像は描画テスト出力）です。

タイトルとボタンは **Zen Maru Gothic Bold**、本文は端末標準の読みやすい書体です。[Google Fonts公式配布](https://github.com/google/fonts/tree/main/ofl/zenmarugothic)の未改変フォントを同梱し、SIL Open Font License 1.1の著作権表示・全文を `assets/fonts/OFL.txt` に収録しています。フォントのネットワーク取得は起動時に行いません。

## このPCで起動する

リポジトリ直下で次を実行します。端末が未接続なら、作成済みのエミュレーターを起動します。

```powershell
powershell -ExecutionPolicy Bypass -File tool/run-android.ps1
```

確認・再ビルドは `powershell -ExecutionPolicy Bypass -File tool/setup.ps1`。

このPCでは、日本語パスに起因する解析サーバーの問題を避けるため、`C:\Users\shunsuke\develop\kotoba-no-mori` を元のリポジトリへのジャンクションとして使用します。別のコピーではありません。また、OneDriveの生成物削除エラーを避けるため、`build` は `C:\Users\shunsuke\develop\kotoba-no-mori-build` へのジャンクションです。スクリプトは英数字パスを自動選択します。FlutterのPATH、ANDROID_HOME、JAVA_HOMEもユーザー設定へ登録済みです。新しいターミナルから反映されます。

## 別のWindows PCでのセットアップ

1. [Flutter公式セットアップ](https://docs.flutter.dev/install)で最新の安定版Flutter SDKを導入し、`flutter/bin`をPATHに追加します。Git for Windowsも必要です。
2. [Android公式セットアップ](https://docs.flutter.dev/platform-integration/android/setup)に従いAndroid Studio、Android SDK、Command-line Tools、エミュレーターを導入します。
3. `flutter doctor -v`、`flutter doctor --android-licenses`を実行し、Android toolchainの問題を解決します。
4. リポジトリ直下で `powershell -ExecutionPolicy Bypass -File tool/setup.ps1` を実行します。公式Android・iOS雛形生成、依存取得、静的解析、テスト、デバッグAPKビルドを順に実行します。既存の`lib/main.dart`は保持されます。
5. AndroidエミュレーターまたはUSBデバッグ有効の端末を用意し、`flutter devices`、`flutter run`で起動します。

APK出力先：`build/app/outputs/flutter-apk/app-debug.apk`。生成後の`pubspec.lock`は依存固定用にコミットしてください。

iOSは同じDartコードを使用します。ビルド・署名・実機確認にはmacOS、XcodeとApple側の設定が必要です。アプリID `jp.kotobanomori.kotoba_no_mori` は公開前に所有する識別子へ変更してください。

## 実装内容

- ホーム、パズル、わたしの森、例題付きあそびかた、文字サイズ設定。
- 時間・挑戦回数制限なし。日本語IME入力、カタカナのひらがな変換。
- 正しい位置を先に確定し、残った文字数で重複を判定。色に加えて◎・△・×と説明を表示。
- ジャンル、具体的な特徴、最初の文字の3段階ヒント。答えそのものは表示しません。課金・広告なし。
- 問題拡充の第1段階：3文字112問・4文字101問・5文字54問、旧2文字3問・6文字1問の計271語。5文字は準備データのみで、通常モードは3・4文字です。外部辞書による自動照合や専門家監修は未実施です。
- 追加データは `lib/word_data.dart` の `Word.entry(答え, 文字数, カテゴリ, ヒント)` で管理します。`dart run tool/audit_words.dart` で重複・文字数・文字種・入力可否・カテゴリ・ヒントを検査し、不正時は終了コード1を返します。型と構文は `flutter analyze` で確認します。
- 保存済みの途中問題・回答・ヒントを保持し、データ追加時はその次に新規問題を優先します。3・4文字で別々に順序と周回位置を保存し、一巡後は再出題します。「今日のことば」と旧形式の進行は既存24語の順序を固定し、追加による答えの変更を防ぎます。
- タップ音は短い木製ボタン風の1種類です。正解・不正解・報酬・購入音は維持しています。800問への拡充は段階的に行い、表記検討中の候補は `docs/word-review.md` に分離します。
- 入力は文字種・文字数を確認し、辞書にない候補も試せます。
- 1問で若葉、2問で苗木と蝶、3問でうさぎ、4問で小鳥、6問で花の木、8問できつねと仲間たち。累計正解数から成長を復元。
- `shared_preferences`で問題番号、回答履歴、ヒント、文字サイズを端末保存。正解直後の終了にも対応。保存失敗は画面に表示。

## 対象ファイル

- `lib/main.dart`：画面・操作・保存
- `lib/letter_board.dart`：入力と判定の文字マス
- `lib/forest_scene.dart`：Flutter描画によるオリジナルの森と動物
- `lib/game.dart`：問題集・判定・進行モデル
- `test/game_test.dart`：重複、入力、復元、問題集のテスト
- `test/widget_test.dart`：ホームから正解・保存・次問の画面テスト
- `tool/setup.ps1`：SDK導入後の初期化・確認

## 未確認・今後の作業

森・植物・動物はFlutterのCanvasで描画するオリジナル素材で、外部素材や絵文字は使用していません。入力はマスをタップして行い、IME変換中は入力を妨げず、確定時に文字数を制限します。回答欄はキーボードの上に残り、履歴は独立してスクロールできます。TalkBackと各社実機IMEの最終確認、アプリアイコン、リリース署名、ストア申請は未対応。Firebase Analytics、AdMob、広告ヒントは今回導入していません。Windows PC上ではAndroidエミュレーターで起動します。
