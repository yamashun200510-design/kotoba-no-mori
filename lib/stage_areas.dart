import 'package:flutter/painting.dart';

/// Landscape themes of the journey. Each area paints a matching placeholder
/// until its illustration is supplied (see HANDOVER.md, エリア一覧).
enum AreaTheme {
  // The journey through Japanese nature and seasons.
  forest,
  river,
  hill,
  paddy,
  mountain,
  seaside,
  snowfield,
  meadow,
  // Special worlds visited along the way.
  onsen,
  desert,
  deepSea,
  sweets,
  heaven,
  hell,
  cyber,
  space;

  bool get isSpecial => index >= AreaTheme.onsen.index;
}

/// Season of a nature area; special worlds use [special].
enum AreaSeason { spring, summer, autumn, winter, dusk, special }

/// The character of the road the app draws in an area, so areas do not all
/// look alike: winding, right-angle zigzags, straight stone stairs, a road
/// threading between houses and rocks, a riverside path with bridges, and a
/// mountain switchback.
enum RoadStyle { meander, zigzag, stairs, weave, riverside, switchback }

class ForestArea {
  final int number; // 1-based
  final String name;
  final AreaTheme theme;
  final AreaSeason season;

  /// Scenery for the scrolling map, or null while it is being prepared.
  /// A road-free landscape that tiles vertically without visible seams; it
  /// is repeated down the map and the app draws the road on top, so stage
  /// markers always sit on the road (see HANDOVER.md, エリア一覧).
  final String? image;

  /// Shape of the road drawn over the scenery.
  final RoadStyle road;
  const ForestArea(
    this.number,
    this.name,
    this.theme,
    this.season,
    this.road, {
    this.image,
  });

  int get firstStage => (number - 1) * stagesPerArea + 1;
  int get lastStage => number * stagesPerArea;
}

const stagesPerArea = 40;

/// A journey through Japanese nature and seasons (春の森→川辺→丘→田んぼ→山→
/// 浜辺→夏→夕焼けの草原→秋→冬の雪原→ふるさとの春の森), with eight special
/// worlds on the way (12 温泉郷, 13 砂漠, 16 深海, 19 お菓子の国, 21 天国,
/// 22 地獄, 23 サイバーパンク, 24 宇宙). Area 1 keeps the original 花咲く小道
/// map for stages 1-10. Road shapes are fixed per area.
const forestAreas = <ForestArea>[
  ForestArea(
    1,
    '花咲く小道',
    AreaTheme.forest,
    AreaSeason.spring,
    RoadStyle.meander,
  ),
  ForestArea(
    2,
    'せせらぎの川辺',
    AreaTheme.river,
    AreaSeason.spring,
    RoadStyle.riverside,
  ),
  ForestArea(3, '菜の花の丘', AreaTheme.hill, AreaSeason.spring, RoadStyle.zigzag),
  ForestArea(4, 'れんげの田んぼ', AreaTheme.paddy, AreaSeason.spring, RoadStyle.weave),
  ForestArea(
    5,
    '山桜の峠',
    AreaTheme.mountain,
    AreaSeason.spring,
    RoadStyle.switchback,
  ),
  ForestArea(
    6,
    '春風の浜辺',
    AreaTheme.seaside,
    AreaSeason.spring,
    RoadStyle.meander,
  ),
  ForestArea(7, '青葉の森', AreaTheme.forest, AreaSeason.summer, RoadStyle.weave),
  ForestArea(
    8,
    'ほたるの小川',
    AreaTheme.river,
    AreaSeason.summer,
    RoadStyle.riverside,
  ),
  ForestArea(9, 'ひまわりの丘', AreaTheme.hill, AreaSeason.summer, RoadStyle.zigzag),
  ForestArea(10, '青田の里', AreaTheme.paddy, AreaSeason.summer, RoadStyle.weave),
  ForestArea(
    11,
    '入道雲の山',
    AreaTheme.mountain,
    AreaSeason.summer,
    RoadStyle.stairs,
  ),
  ForestArea(
    12,
    '湯けむりの温泉郷',
    AreaTheme.onsen,
    AreaSeason.special,
    RoadStyle.switchback,
  ),
  ForestArea(
    13,
    'らくだの砂漠',
    AreaTheme.desert,
    AreaSeason.special,
    RoadStyle.meander,
  ),
  ForestArea(14, '夕焼けの草原', AreaTheme.meadow, AreaSeason.dusk, RoadStyle.stairs),
  ForestArea(
    15,
    '月見の川辺',
    AreaTheme.river,
    AreaSeason.autumn,
    RoadStyle.riverside,
  ),
  ForestArea(
    16,
    'きらめく深海',
    AreaTheme.deepSea,
    AreaSeason.special,
    RoadStyle.zigzag,
  ),
  ForestArea(17, '黄金の田んぼ', AreaTheme.paddy, AreaSeason.autumn, RoadStyle.weave),
  ForestArea(
    18,
    '錦の山',
    AreaTheme.mountain,
    AreaSeason.autumn,
    RoadStyle.switchback,
  ),
  ForestArea(
    19,
    'お菓子の国',
    AreaTheme.sweets,
    AreaSeason.special,
    RoadStyle.meander,
  ),
  ForestArea(
    20,
    '銀世界の雪原',
    AreaTheme.snowfield,
    AreaSeason.winter,
    RoadStyle.stairs,
  ),
  ForestArea(
    21,
    '雲の上の天国',
    AreaTheme.heaven,
    AreaSeason.special,
    RoadStyle.riverside,
  ),
  ForestArea(
    22,
    'にぎやか地獄',
    AreaTheme.hell,
    AreaSeason.special,
    RoadStyle.zigzag,
  ),
  ForestArea(
    23,
    'ネオンの夜の街',
    AreaTheme.cyber,
    AreaSeason.special,
    RoadStyle.weave,
  ),
  ForestArea(
    24,
    '星めぐりの宇宙',
    AreaTheme.space,
    AreaSeason.special,
    RoadStyle.zigzag,
  ),
  ForestArea(
    25,
    'ふるさとの春の森',
    AreaTheme.forest,
    AreaSeason.spring,
    RoadStyle.stairs,
  ),
];

ForestArea areaOfStage(int stageId) =>
    forestAreas[((stageId - 1) ~/ stagesPerArea).clamp(
      0,
      forestAreas.length - 1,
    )];

/// Colours for the painted placeholder of each theme and season.
class AreaPalette {
  final Color skyTop, skyBottom, ground, groundShade, trail, trailEdge;
  final Color foliage, foliageShade, accent, accent2;
  const AreaPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.ground,
    required this.groundShade,
    required this.trail,
    required this.trailEdge,
    required this.foliage,
    required this.foliageShade,
    required this.accent,
    required this.accent2,
  });
}

AreaPalette paletteFor(ForestArea area) {
  final special = _specialPalettes[area.theme];
  if (special != null) return special;
  final foliage = switch (area.season) {
    AreaSeason.spring => (const Color(0xFF7CC26B), const Color(0xFF4E9A52)),
    AreaSeason.summer => (const Color(0xFF4FA35A), const Color(0xFF2F7A43)),
    AreaSeason.autumn => (const Color(0xFFE08A3C), const Color(0xFFB85A2B)),
    AreaSeason.winter => (const Color(0xFF9DB0A5), const Color(0xFF6D8077)),
    AreaSeason.dusk ||
    AreaSeason.special => (const Color(0xFFB79A4C), const Color(0xFF8A6C35)),
  };
  final accents = switch (area.season) {
    AreaSeason.spring => (const Color(0xFFF6A9BE), const Color(0xFFFFE07A)),
    AreaSeason.summer => (const Color(0xFFFFD34F), const Color(0xFF7FC8F0)),
    AreaSeason.autumn => (const Color(0xFFD9483B), const Color(0xFFF2C14E)),
    AreaSeason.winter => (const Color(0xFFFFFFFF), const Color(0xFFD7E6F2)),
    AreaSeason.dusk ||
    AreaSeason.special => (const Color(0xFFF59A5B), const Color(0xFFFFD27A)),
  };
  final sky = switch (area.season) {
    AreaSeason.dusk => (const Color(0xFFF7A766), const Color(0xFFFCE0B0)),
    AreaSeason.winter => (const Color(0xFFBFD3E6), const Color(0xFFEFF5FA)),
    AreaSeason.autumn => (const Color(0xFF8FC3E8), const Color(0xFFF3E9D2)),
    _ => (const Color(0xFF8CCBF0), const Color(0xFFE8F6FB)),
  };
  final ground = switch ((area.theme, area.season)) {
    (AreaTheme.snowfield, _) || (_, AreaSeason.winter) => (
      const Color(0xFFF4F7F9),
      const Color(0xFFDDE6EC),
    ),
    (AreaTheme.seaside, _) => (
      const Color(0xFFF1E3BE),
      const Color(0xFFE2CE9C),
    ),
    (_, AreaSeason.autumn) => (
      const Color(0xFFD9C27A),
      const Color(0xFFC4A55C),
    ),
    (_, AreaSeason.dusk) => (const Color(0xFFE2C77E), const Color(0xFFC9A75E)),
    (_, AreaSeason.summer) => (
      const Color(0xFF9CCB6A),
      const Color(0xFF7FB255),
    ),
    _ => (const Color(0xFFB5DB86), const Color(0xFF98C76E)),
  };
  final snowy = area.season == AreaSeason.winter;
  return AreaPalette(
    skyTop: sky.$1,
    skyBottom: sky.$2,
    ground: ground.$1,
    groundShade: ground.$2,
    trail: snowy ? const Color(0xFFE9E4DA) : const Color(0xFFF1D9A6),
    trailEdge: snowy ? const Color(0xFFB9B2A4) : const Color(0xFFC79A5B),
    foliage: foliage.$1,
    foliageShade: foliage.$2,
    accent: accents.$1,
    accent2: accents.$2,
  );
}

AreaPalette _palette(
  int skyTop,
  int skyBottom,
  int ground,
  int groundShade,
  int trail,
  int trailEdge,
  int foliage,
  int foliageShade,
  int accent,
  int accent2,
) => AreaPalette(
  skyTop: Color(skyTop),
  skyBottom: Color(skyBottom),
  ground: Color(ground),
  groundShade: Color(groundShade),
  trail: Color(trail),
  trailEdge: Color(trailEdge),
  foliage: Color(foliage),
  foliageShade: Color(foliageShade),
  accent: Color(accent),
  accent2: Color(accent2),
);

/// Colours of the special worlds. 地獄 is deliberately bright and playful.
final _specialPalettes = <AreaTheme, AreaPalette>{
  AreaTheme.onsen: _palette(
    0xFFB8D8EC,
    0xFFF1EEE6,
    0xFFD9CBB0,
    0xFFC8B795,
    0xFFE9E3D7,
    0xFF9C9284,
    0xFF6FA36A,
    0xFF4C7C4E,
    0xFFE85D4A,
    0xFFFFFFFF,
  ),
  AreaTheme.desert: _palette(
    0xFF8FD0F2,
    0xFFFBE7C4,
    0xFFF0D59A,
    0xFFDDBB76,
    0xFFFFF0CF,
    0xFFC29A5A,
    0xFF6FA35A,
    0xFF4D7E43,
    0xFFE88A5A,
    0xFFFFD86B,
  ),
  AreaTheme.deepSea: _palette(
    0xFF3A86C2,
    0xFF1D4E80,
    0xFF1B4373,
    0xFF143258,
    0xFFE9DDB8,
    0xFFB3A57E,
    0xFF3FA88A,
    0xFF2C7D68,
    0xFFFF8FA3,
    0xFFFFD36B,
  ),
  AreaTheme.sweets: _palette(
    0xFFFFC7E1,
    0xFFFFF0F6,
    0xFFFFE1EC,
    0xFFFFCFE0,
    0xFFF3D19A,
    0xFFB9824A,
    0xFF9EE0C8,
    0xFF6CC3A6,
    0xFFFF6FA0,
    0xFF8ED1FF,
  ),
  AreaTheme.heaven: _palette(
    0xFFBFE4FF,
    0xFFF6FBFF,
    0xFFF1F7FF,
    0xFFE0EBF8,
    0xFFFFF0BF,
    0xFFE2B85A,
    0xFFFFFFFF,
    0xFFDCE8F5,
    0xFFFFE07A,
    0xFFFFB8D9,
  ),
  AreaTheme.hell: _palette(
    0xFF9A5BD6,
    0xFFFFA98A,
    0xFFFFA275,
    0xFFF38A5E,
    0xFFFFE9C2,
    0xFFB04A6A,
    0xFFB45CE0,
    0xFF8A3DB8,
    0xFFFFD34F,
    0xFFFF5C8A,
  ),
  AreaTheme.cyber: _palette(
    0xFF1A1440,
    0xFF3A1F6E,
    0xFF1F1B3D,
    0xFF17142F,
    0xFF2C315E,
    0xFF22E5FF,
    0xFF2E2A5C,
    0xFF242050,
    0xFFFF3DCB,
    0xFF29F0FF,
  ),
  AreaTheme.space: _palette(
    0xFF0E1033,
    0xFF242A72,
    0xFF181C48,
    0xFF10133A,
    0xFFD8DCEF,
    0xFF8C93C2,
    0xFF6FA8FF,
    0xFF4A70D0,
    0xFFFFD86B,
    0xFFFF8FB8,
  ),
};
