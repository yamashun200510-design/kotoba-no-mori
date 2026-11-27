import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_no_mori/forest_audio.dart';
import 'package:kotoba_no_mori/game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    ForestAudio.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ForestAudio.channel, (call) async {
          calls.add(call);
          return call.method == 'play' ? true : null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ForestAudio.channel, null),
  );

  test('連打と正解・報酬音の重なりを抑え、消音で再生中の音も停止する', () async {
    await ForestAudio.play('key', true);
    await ForestAudio.play('key', true);
    expect(calls.map((c) => c.arguments), ['key']);
    await ForestAudio.play('win', true);
    await ForestAudio.play('reward', true);
    await ForestAudio.play('key', true);
    expect(calls.map((c) => c.arguments), ['key', 'win']);
    await ForestAudio.stop();
    await ForestAudio.play('buy', false);
    expect(calls.last.method, 'stop');
    expect(calls.length, 3);
    expect(
      Progress.decode(Progress(soundEnabled: false).encode()).soundEnabled,
      false,
    );
  });

  test('ステージ開始音は専用キューで連打を抑える', () async {
    await ForestAudio.play('stage', true);
    await ForestAudio.play('stage', true);
    expect(calls.map((c) => c.arguments), ['stage']);
  });

  test('タイトルの花びら風音は効果音オフなら再生しない', () async {
    await ForestAudio.play('wind', true);
    expect(calls.map((c) => c.arguments), ['wind']);
    ForestAudio.resetForTesting();
    calls.clear();
    await ForestAudio.play('wind', false);
    expect(calls, isEmpty);
  });

  test('再生未対応・再生エラーでもゲーム処理へ例外を返さない', () async {
    for (final error in [
      MissingPluginException(),
      PlatformException(code: 'audio-unavailable'),
    ]) {
      ForestAudio.resetForTesting();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            ForestAudio.channel,
            (_) async => throw error,
          );
      await ForestAudio.play('wrong', true);
      await ForestAudio.stop();
    }
  });

  test('7種類のオリジナル音源が有効なPCM WAVで、短く控えめなレベル', () {
    for (final name in [
      'key',
      'wrong',
      'win',
      'reward',
      'buy',
      'stage',
      'wind',
    ]) {
      final bytes = File('assets/sounds/$name.wav').readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(data.getUint16(22, Endian.little), 1);
      expect(data.getUint32(24, Endian.little), 22050);
      final duration = (bytes.length - 44) / 44100;
      expect(
        duration,
        name == 'win'
            ? inInclusiveRange(.5, 1.5)
            : name == 'stage'
            ? inInclusiveRange(.65, .75)
            : name == 'wind'
            ? inInclusiveRange(2.0, 2.3)
            : inInclusiveRange(.05, .65),
      );
      var peak = 0;
      for (var i = 44; i < bytes.length; i += 2) {
        final sample = data.getInt16(i, Endian.little).abs();
        if (sample > peak) peak = sample;
      }
      expect(peak, inInclusiveRange(1000, 16000));
      expect(
        data.getInt16(bytes.length - 2, Endian.little).abs(),
        lessThan(200),
      );
    }
  });
}
