import 'package:flutter/painting.dart';

/// Landscape themes of the journey. Each area paints a matching placeholder
/// until its illustration is supplied (see HANDOVER.md, エリア一覧).
enum AreaTheme {
  forest,
  river,
  hill,
  paddy,
  mountain,
  seaside,
  snowfield,
  meadow,
}

enum AreaSeason { spring, summer, autumn, winter, dusk }

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

/// A journey through Japanese seasons: 森→川辺→丘→田んぼ→山→海辺→雪原→夕焼けの草原.
/// Area 1 keeps the original 花咲く小道 map for stages 1-10.
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
    '潮騒の海辺',
    AreaTheme.seaside,
    AreaSeason.summer,
    RoadStyle.switchback,
  ),
  ForestArea(
    13,
    '夕焼けの草原',
    AreaTheme.meadow,
    AreaSeason.dusk,
    RoadStyle.meander,
  ),
  ForestArea(14, '紅葉の森', AreaTheme.forest, AreaSeason.autumn, RoadStyle.stairs),
  ForestArea(
    15,
    '月見の川辺',
    AreaTheme.river,
    AreaSeason.autumn,
    RoadStyle.riverside,
  ),
  ForestArea(16, 'すすきの丘', AreaTheme.hill, AreaSeason.autumn, RoadStyle.zigzag),
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
    '茜色の草原',
    AreaTheme.meadow,
    AreaSeason.autumn,
    RoadStyle.meander,
  ),
  ForestArea(
    20,
    '冬木立の森',
    AreaTheme.forest,
    AreaSeason.winter,
    RoadStyle.stairs,
  ),
  ForestArea(
    21,
    '朝霧の川辺',
    AreaTheme.river,
    AreaSeason.winter,
    RoadStyle.riverside,
  ),
  ForestArea(22, '雪化粧の丘', AreaTheme.hill, AreaSeason.winter, RoadStyle.zigzag),
  ForestArea(
    23,
    '銀世界の雪原',
    AreaTheme.snowfield,
    AreaSeason.winter,
    RoadStyle.weave,
  ),
  ForestArea(
    24,
    '冬の海辺',
    AreaTheme.seaside,
    AreaSeason.winter,
    RoadStyle.zigzag,
  ),
  ForestArea(
    25,
    'ふたたび春の森',
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
  final foliage = switch (area.season) {
    AreaSeason.spring => (const Color(0xFF7CC26B), const Color(0xFF4E9A52)),
    AreaSeason.summer => (const Color(0xFF4FA35A), const Color(0xFF2F7A43)),
    AreaSeason.autumn => (const Color(0xFFE08A3C), const Color(0xFFB85A2B)),
    AreaSeason.winter => (const Color(0xFF9DB0A5), const Color(0xFF6D8077)),
    AreaSeason.dusk => (const Color(0xFFB79A4C), const Color(0xFF8A6C35)),
  };
  final accents = switch (area.season) {
    AreaSeason.spring => (const Color(0xFFF6A9BE), const Color(0xFFFFE07A)),
    AreaSeason.summer => (const Color(0xFFFFD34F), const Color(0xFF7FC8F0)),
    AreaSeason.autumn => (const Color(0xFFD9483B), const Color(0xFFF2C14E)),
    AreaSeason.winter => (const Color(0xFFFFFFFF), const Color(0xFFD7E6F2)),
    AreaSeason.dusk => (const Color(0xFFF59A5B), const Color(0xFFFFD27A)),
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
