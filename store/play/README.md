# Google Play 掲載用素材

| ファイル | サイズ | 用途 |
| --- | --- | --- |
| `icon-512.png` | 512×512 PNG | アプリのアイコン（角は四角のまま。Play が角を丸める） |
| `feature-1024x500.png` | 1024×500 PNG | フィーチャー グラフィック |
| `screenshots/01-puzzle.png` | 1080×2160 PNG | スマートフォンのスクリーンショット1「ひらがなのことば当て」 |
| `screenshots/02-win.png` | 1080×2160 PNG | 2「正解すると森が育つ」 |
| `screenshots/03-modes.png` | 1080×2160 PNG | 3「3・4・5文字からえらべる」（全1,000問） |
| `screenshots/04-home.png` | 1080×2160 PNG | 4「時間制限なし 自分のペースで」（文字サイズ「大きめ」で撮影） |
| `screenshots/05-map.png` | 1080×2160 PNG | 5「花咲く小道をすすもう」 |

- スクリーンショットは 1080×2160（縦長、9:18）。Galaxy は 19.5:9 だが、Play は縦横比 2:1 までしか受け付けないため、その上限に合わせた。
- 画面部分は、実際のアプリを 3倍スケールで動かして撮ったもの（Galaxy の 360dp 幅と同じレイアウト）。上の説明文は、アプリにある機能だけを書いている。
- 文字は、ターゲット（60〜80代）に合わせて、見出し 96px・補足 50px の丸ゴシック（Zen Maru Gothic Bold、アプリ同梱のフォント）。

## 作り直し方

1. 生の画面を撮る（PC・Linux）。リポジトリのコピーで `flutter create --platforms=linux .` を実行し、`linux/runner/my_application.cc` の初期ウィンドウサイズを 360×720 にする。`tool/store_capture/` の2ファイルを使う:
   - `seed_test.dart` を `flutter test` で実行すると、場面ごとの保存データが `build/seeds/` にできる。
   - `flutter build linux --debug -t tool/store_capture/store_main.dart` でビルドし、保存データを `~/.local/share/jp.amuse.kotoba_no_mori/shared_preferences.json` に置いて、`GDK_SCALE=3 SCENE=puzzle` などで起動して画面を撮る（1080×2160）。
2. `python3 tool/store_assets.py 生画面のフォルダ` で、このフォルダの素材を作り直す。
