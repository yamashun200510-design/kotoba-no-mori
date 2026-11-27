import 'package:flutter/material.dart';

/// Reusable, high-contrast wooden wordmark shared by the title and home.
class ForestWordmark extends StatelessWidget {
  final double fontSize;
  final bool compact;
  final bool showSideDecorations;
  const ForestWordmark({
    super.key,
    this.fontSize = 38,
    this.compact = false,
    this.showSideDecorations = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 20 : 30,
      vertical: compact ? 8 : 14,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(compact ? 24 : 34),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE6A6), Color(0xFFC87932), Color(0xFF80451F)],
        stops: [0, .28, 1],
      ),
      border: Border.all(color: const Color(0xFFFFF0C7), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x770C351F),
          offset: Offset(0, 7),
          blurRadius: 12,
        ),
      ],
    ),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 20,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 17 : 25),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF98602F), Color(0xFF60371E)],
        ),
        border: Border.all(color: const Color(0xFFFFD88A), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showSideDecorations ? 30 : 8,
            ),
            child: Text(
              'ことばの森',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ZenMaru',
                fontSize: fontSize,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: const Color(0xFFFFF5D5),
                shadows: const [
                  Shadow(
                    color: Color(0xFF734019),
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  ),
                  Shadow(
                    color: Color(0xFFEBA84A),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                  Shadow(
                    color: Color(0xFF3D2918),
                    offset: Offset(0, 3),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          if (showSideDecorations)
            Positioned(
              left: 2,
              child: Icon(
                Icons.eco,
                size: compact ? 22 : 30,
                color: const Color(0xFFB8E36F),
                shadows: const [
                  Shadow(color: Color(0xFF44672C), blurRadius: 3),
                ],
              ),
            ),
          if (showSideDecorations)
            Positioned(
              right: 2,
              child: Icon(
                Icons.local_florist,
                size: compact ? 21 : 28,
                color: const Color(0xFFFFD36E),
                shadows: const [
                  Shadow(color: Color(0xFF754622), blurRadius: 3),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class TaglineRibbon extends StatelessWidget {
  final bool compact;
  const TaglineRibbon({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 18 : 26,
      vertical: compact ? 5 : 8,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE6A8),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFB77332), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x552E321B),
          offset: Offset(0, 3),
          blurRadius: 5,
        ),
      ],
    ),
    child: Text(
      'ゆっくり、ひとことば。',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'ZenMaru',
        fontSize: compact ? 15 : 19,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF553519),
      ),
    ),
  );
}

/// Glossy frame only: labels, semantics and actions remain real Flutter controls.
class StorybookSurface extends StatelessWidget {
  final Widget child;
  final Color color;
  const StorybookSurface({
    super.key,
    required this.child,
    this.color = const Color(0xFF55B83E),
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFFFDA87), width: 3),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, .32)!,
          color,
          Color.lerp(color, Colors.black, .18)!,
        ],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0xFF97612C), offset: Offset(0, 4)),
        BoxShadow(
          color: Color(0x40374423),
          offset: Offset(0, 7),
          blurRadius: 8,
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 4,
          left: 14,
          right: 14,
          height: 10,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .30),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}
