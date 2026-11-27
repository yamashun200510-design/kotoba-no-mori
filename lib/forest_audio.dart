import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Bundled, original short tones; no network or playback package is needed.
class ForestAudio {
  static const channel = MethodChannel('kotoba_no_mori/sounds');
  static final _clock = Stopwatch()..start();
  static int _lastTap = -1000, _protectedUntil = 0;
  static String? _musicTrack;
  static const _lengths = {
    'key': 85,
    'wrong': 180,
    'win': 1050,
    'reward': 600,
    'buy': 450,
    'stage': 700,
    'wind': 2200,
  };
  static Future<void> play(String name, bool enabled) async {
    if (!enabled || !_lengths.containsKey(name)) return;
    final now = _clock.elapsedMilliseconds;
    if (name == 'key') {
      if (now - _lastTap < 50 || now < _protectedUntil) return;
      _lastTap = now;
    } else {
      if (now < _protectedUntil) return;
      _protectedUntil = now + _lengths[name]!;
    }
    try {
      await channel.invokeMethod<bool>('play', name);
    } on MissingPluginException {
      // Other platforms can supply the same small channel later.
    } on PlatformException {
      // Sound must never interrupt a puzzle.
    }
  }

  static Future<void> stop() async {
    _lastTap = -1000;
    _protectedUntil = 0;
    try {
      await channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      /* Optional on other platforms. */
    } on PlatformException {
      /* Never block a setting change. */
    }
  }

  /// Keeps one native looping player alive and only changes it when moving
  /// between puzzle and non-puzzle screens.
  static Future<void> setMusic(String? track, bool enabled) async {
    final requested = enabled ? track : null;
    if (requested == _musicTrack) return;
    _musicTrack = requested;
    try {
      await channel.invokeMethod<void>('music', requested);
    } on MissingPluginException {
      // The current music backend is Android-native; other platforms can add
      // an implementation without affecting the game.
    } on PlatformException {
      // Audio setup is optional and must never block navigation.
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _lastTap = -1000;
    _protectedUntil = 0;
  }
}
