# カートゥーン背景素材

ユーザー提供のChatGPT生成画像2点を、組み込み image_gen で編集。
元画像と旧背景は削除せず保存。旧 enchanted-forest.png はアセット登録・表示対象から除外。

- assets/art/cartoon-home.png：タイトル・ホーム共通。他画面は読みやすさのためクリーム色の膜を追加。
- assets/art/cartoon-map.png：スクロールするマップ内の背景。番号・星・ロック・現在地はFlutterで表示。

画像には操作UIや数値を含めない。コイン、進行、アクションは既存のデータを利用。
10ステージは同じ素材を使った2区間に配置。背景だけを縦に極端に引き伸ばさず、道に沿って実ボタンを配置。
既存のアニメーション付きうさぎはFlutter側で維持し、背景のうさぎとの二重表示を防ぐ。

## 編集プロンプト

Home: Preserve the vivid rounded 2D casual fantasy forest, lime and emerald foliage, blue sky, tree house, waterfall, wooden bridge and colorful flowers. Remove all UI, title, text, counters, buttons, icons and rabbit. Fill naturally with canopy, sky and an uncluttered warm clearing. Background only, no readable text or controls; not realistic or watercolor.

Map: Preserve the vivid rounded cartoon adventure map geography, waterfall, tree house, stream, bridge, flowers and winding salmon path. Remove all stage buttons and bases, numbers, stars, locks, coin counter, back arrow, rabbit and text sign. Inpaint an uninterrupted sandy path. Background only, no UI or text; not photographic or watercolor.
