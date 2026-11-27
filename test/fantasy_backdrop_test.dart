import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/fantasy_backdrop.dart';

void main() {
  testWidgets('森の背景は全面を覆い、バックグラウンドと軽減設定で動きを止める', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    Widget page(bool quiet) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: quiet),
        child: const FantasyBackdrop(),
      ),
    );
    await tester.pumpWidget(page(false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      ((tester.widget<Image>(find.byType(Image)).image as ResizeImage)
                  .imageProvider
              as AssetImage)
          .assetName,
      'assets/art/cartoon-home.png',
    );
    expect(
      tester.getRect(find.byType(FantasyBackdrop)),
      const Rect.fromLTWH(0, 0, 390, 844),
    );
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(page(true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
