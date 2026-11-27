// Entry point for Play Store screenshots: opens the app and moves to SCENE.
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kotoba_no_mori/main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final key = GlobalKey();
  runApp(ForestApp(key: key));
  final scene = Platform.environment['SCENE'] ?? 'home';
  dynamic state() => key.currentState;
  Timer(const Duration(seconds: 5), () => state().startFromTitle());
  Timer(const Duration(seconds: 8), () {
    if (scene == 'puzzle' || scene == 'win') state().startNormal();
    if (scene == 'map') state().go('ステージマップ');
    if (scene == 'modes') state().go('文字数をえらぶ');
  });
}
