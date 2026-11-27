# 魔法の森の背景

素材: `assets/art/enchanted-forest.png`（約3MB）。
内蔵image_genによる独自生成。外部作品・既存キャラクターの画像は使用していない。
タイトル、ホーム、モード選択、パズル等で同じキャッシュ画像を再利用する。
植物の育成・購入品・白うさぎは既存描画を別レイヤーで維持する。
動くのは軽い光・蝶・花びらの描画。背景画像そのものは動かさない。
背景復帰と動きの軽減設定に対応し、パズル等では背景の環境アニメーションを止める。

## 生成プロンプト（内蔵ツール）

Create one original production game background illustration, portrait 9:16, no text no typography no logo no UI. A luminous enchanted forest for a refined Japanese storybook word puzzle aimed at adult women, inviting and joyful, painterly gouache and soft hand-painted animation-background finish, rich depth and sophisticated warm colors. Very tall ancient trees curve into an arch along LEFT and RIGHT edges, sculpted emerald and teal leaf canopy, sunlit pale mint clearing in CENTER, warm honey rays from upper left, winding cream golden pathway at bottom, pink foxgloves, butter-yellow daisies, coral blossoms, lavender and violet flowers concentrated along lower side borders, tiny blue songbird and two delicate butterflies at edges. Dense beautiful organically varied vegetation, exquisite soft textures and believable shapes, no geometric clip art. Keep middle 65% relatively pale, low-contrast and calm so dark green text and cream menu panels can be overlaid. Upper-middle quiet bright clearing for title, no empty solid-color background: atmospheric trees everywhere. Foreground florals frame bottom corners, magical but subtle floating pollen, bright daytime, elegant not childish, no dark scary forest. NO rabbit or other large characters (existing animated rabbit will be overlaid). Entire image is forest with depth, no framed panel. Independent original fantasy world, do not imitate specific existing films or characters. Save the resulting image file for use in a Flutter mobile application.
