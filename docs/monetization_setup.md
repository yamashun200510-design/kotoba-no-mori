# 収益化の公開設定

アプリには、希望者が1日1回の動画広告を視聴して10コインを受け取る任意のRewarded広告を実装しています。広告が読み込めない、同意が得られていない、またはオフラインの場合は広告導線を利用できず、パズルやショップはそのまま使えます。

## 開発・エミュレーター

- DebugビルドはGoogle公式のテスト用AdMobアプリIDとRewarded広告ユニットIDを使います。
- テスト広告をクリック・視聴しても収益は発生しません。実広告でのテストは禁止です。

## 公開前に必要な設定

1. AdMobでAndroidアプリとRewarded広告ユニットを作り、実IDを用意します。
2. Privacy & messagingで対象地域に必要な同意メッセージを作成・公開します。
3. 公開ビルド時に環境変数 `ADMOB_APP_ID` をAndroidのAdMobアプリIDに設定します。未設定ではReleaseビルドを止め、テストIDの誤公開を防ぎます。
4. Rewarded広告ユニットは `--dart-define=ADMOB_REWARDED_ANDROID_ID=実広告ユニットID` で指定します。ReleaseでID未設定の場合、広告導線は無効です。
5. アプリのプライバシーポリシーを公開URLへ掲載し、運営者名・連絡先・最終更新日を `lib/legal.dart` に設定します。Google Play Consoleのデータセーフティ、広告ID、対象年齢・ファミリー関連の申告も実際の広告設定に合わせて完了してください。
6. iOS公開時は `ios/Runner/Info.plist` のテスト用AdMobアプリIDを実IDへ置き換え、iOS用広告ユニットIDも `ADMOB_REWARDED_IOS_ID` で渡します。

実際のアプリID・広告ユニットID、AdMobアカウント、公開用プライバシーポリシーURLは開発者が用意する必要があります。ここではそれらを捏造していません。
