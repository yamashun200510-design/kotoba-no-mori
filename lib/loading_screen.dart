import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'letter_board.dart' show forestGreen;

/// The large illustrated backdrops are 2–3 MB PNGs. Decoding one the first
/// time a screen opens left a blank frame on real devices, so they are warmed
/// up behind the loading screen. Each provider matches how the screen asks
/// for it (same asset and cache width), so the warmed image is the one used.
List<ImageProvider> forestArtProviders() {
  ImageProvider backdrop(String asset) =>
      ResizeImage(AssetImage(asset), width: 960);
  return [
    backdrop('assets/art/title-portal.png'),
    const AssetImage('assets/art/magic-tree.png'),
    backdrop('assets/art/home-glade.png'),
    backdrop('assets/art/cartoon-home.png'),
    backdrop('assets/art/cartoon-map.png'),
    backdrop('assets/art/forest-garden.png'),
    ResizeImage(const AssetImage('assets/art/cartoon-map.png'), width: 1000),
    const AssetImage('assets/art/forest-garden.png'),
    const AssetImage('assets/art/forest-shop-cottage.png'),
    const AssetImage('assets/art/daily-reward-chest.png'),
  ];
}

/// Widget tests cannot finish real image decoding inside their fake clock, so
/// they skip the warm-up; the app itself always waits for it.
final bool warmArtOnStartup = !Platform.environment.containsKey('FLUTTER_TEST');

/// Decodes every backdrop, giving up after [timeout] so a slow device or a
/// broken asset can never keep the player on the loading screen.
Future<void> warmForestArt(
  BuildContext context, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final jobs = [
    for (final provider in forestArtProviders())
      precacheImage(provider, context, onError: (_, _) {}),
  ];
  await Future.wait(jobs).timeout(timeout, onTimeout: () => const []);
}

/// Shown from the first Flutter frame until saved progress is read and the
/// artwork is ready, so startup never looks blank or frozen.
class ForestLoadingScreen extends StatelessWidget {
  const ForestLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ことばの森、よみこみ中',
    liveRegion: true,
    child: ExcludeSemantics(
      // Material supplies the app's text style; this overlay sits above the
      // screens' Scaffolds, so without it text would get debug underlines.
      child: Material(
        key: const ValueKey('loading-screen'),
        color: const Color(0xFFFAF6EA),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              // Shrinks as a whole on short screens (landscape, large text).
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/branding/app-icon-rounded.png',
                        width: 132,
                        height: 132,
                        cacheWidth: 264,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ことばの森',
                        style: TextStyle(
                          fontFamily: 'ZenMaru',
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: forestGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: const LinearProgressIndicator(
                          minHeight: 8,
                          color: forestGreen,
                          backgroundColor: Color(0xFFDDE5D2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'よみこみ中…',
                      style: TextStyle(fontSize: 17, color: Color(0xFF4C6547)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
