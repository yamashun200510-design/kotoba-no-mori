# 申し送りノート（むせ ⇄ Claude Code）

このプロジェクトは二刀流体制で開発しています。

- **むせ（Muse）**: 企画・段取り・Play Console・運用・このリポジトリの小さい変更。GitHub に触る前は必ず最新コミットを確認する。
- **Claude Code**: PC 側の実装・ビルド・テスト・大きいファイルの push。
- 作業したら、このファイルの「現状」と「次にやること」を更新してください。相手への伝言もここに書けます。

## 現状（2026-11-27 むせ記）

- Google Play 開発者登録は完了（開発者名「Amuse工房」）。
- プライバシーポリシーを GitHub Pages に公開済み（2026-11-27 むせ）: https://yamashun200510-design.github.io/kotoba-no-mori/privacy.html （privacy.html、Play Console 登録時にこのURLを使う）
- 融合（Flutter 本体＋Web版の設計移植）は実装完了:
  - 5文字モード開放、履歴圧縮（プレイ画面ノースクロール）、吹き出し小型化、Web版単語22語追加（総数633語・検証エラー0）、applicationId を jp.amuse.kotobanomori に統一。
  - 上記のうち **lib/main.dart 以外は GitHub に push 済み**。
- **lib/main.dart の最終版がまだリモートにありません**（むせの道具ではファイルサイズ上限で push 不可でした）。最終版は しゅん にファイルで渡し済みです。このファイルを受け取ったら lib/main.dart に上書きして commit & push し、flutter test を回してください。今のままだと widget_test が1件落ちる中間状態です。
- Web版（index.html）はブラウザ体験版として残します。消さないでください。

## 現状（2026-11-27 Claude Code 記）

- lib/main.dart の最終版を push 済み（ブランチ `claude/previous-pc-work-u16z5i`）。
- Flutter 3.47.7 で `flutter analyze` 問題なし、`flutter test` 全127件成功。
- 直したこと:
  - テストが古いボタン名「3文字・4文字をえらぶ」を探していたので「3文字・4文字・5文字をえらぶ」に更新。
  - 文字サイズ「大きめ」の小画面（320×568 / 320×640）でプレイ画面がはみ出していた問題を修正（履歴の行の高さを固定）。
  - ショップのスワイプ、正解お祝いのテストのタイミング・位置を修正（アプリの動作は変更なし）。
- 問題の品質見直しと800問到達（3文字300・4文字300・5文字200）。不正な語11語の削除、伸ばす音の表記統一、182語追加。詳細は docs/word-review.md。テスト全127件成功。
- デバッグAPKをビルドして しゅん に送付済み（実機確認待ち）。
- 実機（Galaxy）指摘3点を修正:
  - 効果音: マナーモード（バイブ/サイレント）だと効果音を全部止める判定があり、それが原因。メディア音量で鳴らすよう変更。アプリ中の音量ボタンはメディア音量を操作するようにした（MainActivity.kt）。
  - ロード画面: Android の起動画面をクリーム色＋アイコンに。アプリ内に「ことばの森／よみこみ中…」のロード画面を追加し、その間に大きな背景画像を先読み（最長5秒で必ず進む）。lib/loading_screen.dart。
  - ステージマップ: 見出し・「星の見かた」・下のボタン・タイトルが1行に収まるよう縮小表示に。狭い画面ではステージの丸も縮めて8〜10の重なりを解消。
  - テスト全133件成功。
- main への取り込みは しゅん の確認待ち（PR #1）。

## リリース準備（2026-11-27 クロ記）

### 署名済みAAB（1回目・広告なし版）

- ファイル: `build/app/outputs/bundle/release/app-release.aab`（84.6MB）。クロの作業環境は消えるため、しゅん にチャットで送付済み。手元の保存先を正とする。
- ビルド日時: 2026-11-27 11:31 UTC（20:31 JST）
- バージョン: 1.0.0（versionCode 1）。applicationId `jp.amuse.kotobanomori`
- 元にしたコミット: main `385e651` ＋ 署名設定の追加（Flutter 3.47.7）
- 広告: なし（`KOTOBA_RELEASE_WITHOUT_ADS=true` でビルド。リリース版は広告ユニットID未設定のため広告を読み込まない）。AdMob の本番ID取得後に、広告ありで作り直す。
- 署名確認済み（jarsigner で verified）。証明書 SHA-256: `DF:E0:36:15:00:DE:6C:91:F6:1F:9C:8B:13:A5:5C:6F:66:71:7F:4D:AA:51:93:E8:B4:1A:EF:0B:84:4B:66:A4`

### アップロード鍵（キーストア）

- ファイル名 `kotoba-no-mori-upload.jks`、エイリアス `upload`、RSA 2048、有効期限 2056-11-19、証明書の名前 `CN=Amuse Kobo, O=Amuse Kobo, C=JP`。
- キーストアとパスワードはリポジトリに置かない（公開リポジトリのため）。キーストアは しゅん に送付済みで、しゅん が保管する。パスワードは しゅん が管理（ここには書かない）。
- なくすと次回の更新に署名できない。Play アプリ署名を使っていれば、Play Console から「アップロード鍵のリセット」を依頼できる。

### 次回ビルドのしかた（Claude Code / PC）

署名情報は環境変数で渡す（ファイルに書かない）:

```
export KOTOBA_UPLOAD_STORE_FILE=/保管場所/kotoba-no-mori-upload.jks
export KOTOBA_UPLOAD_STORE_PASSWORD=（しゅん に確認）
export ADMOB_APP_ID=ca-app-pub-…~…            # 広告ありの場合
flutter build appbundle --release --dart-define=ADMOB_REWARDED_ANDROID_ID=ca-app-pub-…/…
# 広告なしのテスト版だけは ADMOB_APP_ID の代わりに KOTOBA_RELEASE_WITHOUT_ADS=true
```

- 更新のたびに pubspec.yaml の `version:` の `+` 以降（versionCode）を1つ上げる（同じ番号は Play に上げられない）。
- 署名情報がないとリリースビルドは止まる（署名なしのAABを誤って作らないため）。

### Play Console へのアップロード手順（むせ・しゅん）

1. Play Console →「アプリを作成」: アプリ名「ことばの森」、言語 日本語、アプリ／ゲーム＝ゲーム、無料。
2. 「テスト」→「クローズド テスト」→ トラックを作成 → テスター（メールアドレスのリスト、12人以上）を登録。
3. 「新しいリリースを作成」→ 「Play アプリ署名」は Google 管理（既定）のまま進める → `app-release.aab` をアップロード → リリースノートを書く → 審査に送信。
4. 「アプリのコンテンツ」で必須項目を入力:
   - プライバシーポリシー: https://yamashun200510-design.github.io/kotoba-no-mori/privacy.html
   - 広告: このAABは広告を表示しない（広告ありで作り直したら「含む」に変更）。
   - 広告ID: AdMob SDK の都合で AD_ID 権限が入っているため、広告IDの申告が求められる。用途を正しく申告する。
   - データセーフティ、コンテンツのレーティング（質問票）、ターゲット年齢層。**決定（2026-11-27 しゅん）: 子ども向けではない・一般向け。主なターゲットは60〜80代。** Play Console 側の申告は むせ が担当。
5. ストアの掲載情報: 短い説明・詳しい説明・アイコン（512×512）・フィーチャーグラフィック（1024×500）・スクリーンショット（2枚以上）。
6. クローズドテストを 12人以上 × 14日間 続けたあと、製品版の申請ができる。

### 未決・注意

- AdMob 本番アプリID・報酬広告ユニットIDの取得（製品版の前に、広告ありで作り直す）。
- 署名設定と本ノートは main に反映済み（しゅん 承認、2026-11-27）。HANDOVER.md は main が正本。

## 次にやること

1. ~~lib/main.dart の push と flutter test / analyze の通過確認（Claude Code）~~ 完了。`claude/previous-pc-work-u16z5i` を main に取り込む（しゅん確認後）
2. ~~リリース署名（signingConfig）の設定（Play 提出前）~~ 完了（上の「リリース準備」）。1回目の署名済みAAB（広告なし）作成済み
3. AdMob 本番アプリID・広告ユニットIDの取得と設定（Play 提出前）
4. Play Console にアプリ登録 → クローズドテスト（テスター12人×14日）

## 注意

- ユーザーの確定要件: プレイ画面はスクロールなし（絶対）、文字数はホーム画面で選択、五十音キーボードは画面中央から下に大きく、コイン残高は右上、うさぎの吹き出しは小さく。
- 世界観の軸は「外部素材を使わない Canvas 描画」。Web版の AI 生成イラスト素材は持ち込まない。
