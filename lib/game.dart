import 'dart:convert';
import 'puzzle_records.dart';
import 'local_day.dart';
export 'puzzle_records.dart';
export 'local_day.dart';

part 'word_data.dart';

enum Match { exact, present, absent }

const forestFriendThresholds = <String, int>{
  'squirrel': 5,
  'hedgehog': 15,
  'tanuki': 30,
  'fawn': 50,
};

const firstForestAreaId = 'forest_area_1';

/// Appearance overrides for one placed decoration. Coordinates are kept
/// separate so the same item can be styled independently in each forest area.
class ForestItemAppearance {
  final double scale;
  final bool flipped;
  final int rotationSteps;
  final int? tint;

  const ForestItemAppearance({
    this.scale = 1,
    this.flipped = false,
    this.rotationSteps = 0,
    this.tint,
  });

  double get safeScale => scale.clamp(.7, 1.5);
  int get safeRotationSteps => rotationSteps % 24;

  ForestItemAppearance copyWith({
    double? scale,
    bool? flipped,
    int? rotationSteps,
    int? tint,
    bool clearTint = false,
  }) => ForestItemAppearance(
    scale: (scale ?? this.scale).clamp(.7, 1.5),
    flipped: flipped ?? this.flipped,
    rotationSteps: (rotationSteps ?? this.rotationSteps) % 24,
    tint: clearTint ? null : tint ?? this.tint,
  );

  Map<String, dynamic> encode() => {
    'scale': safeScale,
    'flipped': flipped,
    'rotationSteps': safeRotationSteps,
    if (tint != null) 'tint': tint,
  };

  static ForestItemAppearance? decode(dynamic value) {
    if (value is! Map) return null;
    final rawScale = value['scale'];
    final rawFlipped = value['flipped'];
    final rawRotation = value['rotationSteps'];
    final rawTint = value['tint'];
    if (rawScale is! num ||
        !rawScale.isFinite ||
        rawScale < .7 ||
        rawScale > 1.5 ||
        (rawFlipped != null && rawFlipped is! bool) ||
        (rawRotation != null && rawRotation is! int) ||
        (rawTint != null && rawTint is! int)) {
      return null;
    }
    return ForestItemAppearance(
      scale: rawScale.toDouble(),
      flipped: rawFlipped == true,
      rotationSteps: (rawRotation as int? ?? 0) % 24,
      tint: rawTint as int?,
    );
  }
}

/// Saved state that belongs to one forest area (not to the device viewport).
class ForestAreaProgress {
  bool unlocked;
  final Set<String> animals;
  final Map<String, List<double>> itemPositions;
  final Map<String, ForestItemAppearance> itemAppearances;

  ForestAreaProgress({
    this.unlocked = false,
    Set<String>? animals,
    Map<String, List<double>>? itemPositions,
    Map<String, ForestItemAppearance>? itemAppearances,
  }) : animals = {...?animals},
       itemPositions = Progress._copyItemPositions(itemPositions),
       itemAppearances = {...?itemAppearances};

  Map<String, dynamic> encode() => {
    'unlocked': unlocked,
    'animals': animals.toList(),
    'itemPositions': itemPositions,
    'itemAppearances': {
      for (final entry in itemAppearances.entries)
        entry.key: entry.value.encode(),
    },
  };
}

/// Exact matches consume letters first; remaining letters are used only once.
List<Match> judge(String answer, String guess) {
  final a = answer.runes.toList();
  final g = guess.runes.toList();
  if (a.length != g.length) throw ArgumentError('文字数が違います');
  final result = List.filled(a.length, Match.absent);
  final remaining = <int, int>{};
  for (var i = 0; i < a.length; i++) {
    if (a[i] == g[i]) {
      result[i] = Match.exact;
    } else {
      remaining[a[i]] = (remaining[a[i]] ?? 0) + 1;
    }
  }
  for (var i = 0; i < g.length; i++) {
    if (result[i] == Match.exact) continue;
    if ((remaining[g[i]] ?? 0) > 0) {
      result[i] = Match.present;
      remaining[g[i]] = remaining[g[i]]! - 1;
    }
  }
  return result;
}

String normalize(String input) => String.fromCharCodes(
  input.trim().runes.map((r) => r >= 0x30a1 && r <= 0x30f6 ? r - 0x60 : r),
);

class Word {
  final String text;
  final String clue;
  final String? category;
  final int? declaredLength;
  const Word(this.text, this.clue) : category = null, declaredLength = null;
  const Word.entry(this.text, int length, String genre, this.clue)
    : declaredLength = length,
      category = genre;
  String get genre =>
      category ??
      switch (text) {
        'うさぎ' || 'きつね' || 'りす' || 'ふくろう' || 'すずめ' || 'かめ' => 'どうぶつ',
        'もも' || 'いちご' || 'にんじん' || 'たけのこ' || 'くるみ' => 'たべもの',
        'ここあ' => 'のみもの',
        _ => 'しょくぶつ',
      };
}

// 手作業で表記・意味を確認した一般的な名詞。すべて全角ひらがな。
const legacyWords = <Word>[
  Word('さくら', '春に、うすい桃色の花が咲く木です。'),
  Word('うさぎ', '長い耳があり、ぴょんぴょん跳ねる動物です。'),
  Word('たんぽぽ', '黄色い花のあとに、白い綿毛ができます。'),
  Word('どんぐり', '秋に落ちる、帽子をかぶったような木の実です。'),
  Word('すみれ', '春に咲く、小さな紫色の花です。'),
  Word('きつね', 'ふさふさのしっぽと、とがった耳の動物です。'),
  Word('ひまわり', '夏に咲く、太陽のような大きな黄色い花です。'),
  Word('もみじ', '秋に葉が赤く染まる、手の形に似た葉の木です。'),
  Word('りす', '木の実が好きな、小さなふさふさしっぽの動物です。'),
  Word('あじさい', '梅雨のころ、小さな花が集まって丸く咲きます。'),
  Word('つくし', '春に土から顔を出す、筆のような形の植物です。'),
  Word('ふくろう', '夜に活動する、大きな目をした鳥です。'),
  Word('もも', '夏に実る、甘くて桃色の果物です。'),
  Word('ここあ', 'カカオから作る、甘くて温かい飲み物です。'),
  Word('すずめ', '町でも見かける、茶色い小さな鳥です。'),
  Word('なのはな', '春の畑に、黄色い花が一面に咲きます。'),
  Word('いちご', '赤い実に、小さなつぶつぶがある果物です。'),
  Word('たけのこ', '春に地面から出てくる、竹の若い芽です。'),
  Word('こすもす', '秋に咲く、桃色や白の花です。'),
  Word('にんじん', 'オレンジ色で、土の中で育つ野菜です。'),
  Word('あさがお', '夏の朝、ラッパのような花を咲かせます。'),
  Word('かめ', '背中にかたい甲羅がある動物です。'),
  Word('くるみ', 'かたい殻の中に、食べられる実があります。'),
  Word('しろつめくさ', '白い丸い花が咲く、クローバーの仲間です。'),
];

const words = <Word>[...legacyWords, ...additionalWords];

class ForestItem {
  final String id, name;
  final int price;
  const ForestItem(this.id, this.name, this.price);
}

const forestItems = [
  ForestItem('tulip', 'チューリップ', 30),
  ForestItem('mushroom', 'キノコ', 50),
  ForestItem('sunflower', 'ひまわり', 80),
  ForestItem('butterfly', 'チョウ', 120),
  ForestItem('cherry', '桜の木', 200),
];

const loginRewards = [10, 15, 20, 25, 30, 40, 100];

class TodayPuzzle {
  String date;
  List<String> guesses;
  int hints;
  String draft;
  TodayPuzzle({
    this.date = '',
    List<String>? guesses,
    this.hints = 0,
    this.draft = '',
  }) : guesses = guesses ?? [];
  static Word forDate(String date, {Iterable<Word>? pool}) {
    final candidates = {
      for (final word in pool ?? legacyWords) word.text: word,
    }.values.toList();
    if (candidates.isEmpty) return const Word('さくら', '春に、うすい桃色の花が咲く木です。');
    // Keep the published daily calendar stable when the normal pool grows.
    return candidates[LocalDay.number(date) % candidates.length];
  }

  Word get word => forDate(date);
  bool get won => guesses.contains(word.text);
  bool refresh(DateTime now) {
    final key = Progress.dayKey(now);
    if (date == key) return false;
    date = key;
    guesses = [];
    hints = 0;
    draft = '';
    return true;
  }

  bool submit(String text) {
    final guess = normalize(text);
    if (won ||
        guess.runes.length != word.text.runes.length ||
        !RegExp(r'^[ぁ-ゖー]+$').hasMatch(guess)) {
      return false;
    }
    guesses.add(guess);
    return true;
  }

  Map<String, dynamic> encode() => {
    'date': date,
    'guesses': guesses,
    'hints': hints,
    'draft': draft,
  };
  factory TodayPuzzle.decode(dynamic data) {
    if (data == null) return TodayPuzzle();
    final p = TodayPuzzle(
      date: data['date'] as String,
      hints: data['hints'] as int,
      draft: data['draft'] as String? ?? '',
    );
    TodayPuzzle.forDate(p.date);
    if (p.hints < 0 || p.hints > 2) throw const FormatException('hints');
    if (p.draft.length > p.word.text.length ||
        (p.draft.isNotEmpty && !RegExp(r'^[ぁ-ゖー]+$').hasMatch(p.draft))) {
      throw const FormatException('daily draft');
    }
    for (final guess in (data['guesses'] as List).cast<String>()) {
      if (!p.submit(guess)) throw const FormatException('guess');
    }
    return p;
  }
}

class ModePuzzle {
  final int length;
  final List<String> order;
  int cursor;
  List<String> guesses;
  int hints;
  String draft;
  bool clearRecorded;
  ModePuzzle(
    this.length, {
    List<String>? order,
    this.cursor = 0,
    List<String>? guesses,
    this.hints = 0,
    this.draft = '',
    this.clearRecorded = false,
  }) : order =
           order ??
           words
               .where((w) => w.text.length == length)
               .map((w) => w.text)
               .toList(),
       guesses = guesses ?? [];
  Word get word =>
      words.firstWhere((w) => w.text == order[cursor % order.length]);
  bool get won => guesses.contains(word.text);
  Map<String, dynamic> encode() => {
    'order': order,
    'cursor': cursor,
    'guesses': guesses,
    'hints': hints,
    'draft': draft,
    'clearRecorded': clearRecorded,
  };
  factory ModePuzzle.decode(int length, dynamic data) {
    final p = ModePuzzle(
      length,
      order: List<String>.from(data['order'] as List),
      cursor: data['cursor'] as int,
      guesses: (data['guesses'] as List).cast<String>(),
      hints: data['hints'] as int,
      draft: data['draft'] as String? ?? '',
      clearRecorded: data['clearRecorded'] as bool? ?? false,
    );
    if (![3, 4, 5].contains(length) ||
        p.order.isEmpty ||
        p.cursor < 0 ||
        p.hints < 0 ||
        p.hints > 2 ||
        p.order.toSet().length != p.order.length ||
        p.order.any(
          (text) => !words.any((w) => w.text == text && text.length == length),
        ) ||
        p.guesses.any(
          (g) => g.length != length || !RegExp(r'^[ぁ-ゖー]+$').hasMatch(g),
        ) ||
        p.guesses
            .take(p.guesses.length - (p.won ? 1 : 0))
            .contains(p.word.text) ||
        p.draft.length > length ||
        (p.draft.isNotEmpty && !RegExp(r'^[ぁ-ゖー]+$').hasMatch(p.draft))) {
      throw const FormatException('mode progress');
    }
    // Previously completed saves have no historical statistics to reconstruct.
    if (!data.containsKey('clearRecorded') && p.won) p.clearRecorded = true;
    final added = words
        .where((w) => w.text.length == length && !p.order.contains(w.text))
        .map((w) => w.text)
        .toList();
    if (added.isNotEmpty) {
      // Rotate at the current answer before extending a previously saved cycle.
      // Otherwise an absolute cursor from round 2 could jump to a new answer.
      final index = p.cursor % p.order.length;
      final remaining = p.order.sublist(index);
      final visited = p.order.sublist(0, index);
      p.order
        ..clear()
        ..addAll([remaining.first, ...added, ...remaining.skip(1), ...visited]);
      p.cursor = 0;
    }
    return p;
  }
}

class Progress {
  static const version = 1;
  int _solved;
  List<String> _legacyGuesses;
  int _legacyHints;
  int _legacyIndex;
  String _legacyDraft;
  bool legacyAvailable;
  int? mode;
  final Map<int, ModePuzzle> modes;
  final List<PuzzleRecord> records;
  bool _legacyClearRecorded;
  bool swipeKeyboard;
  bool largeText;
  bool reduceMotion;
  bool soundEnabled;
  bool musicEnabled;
  bool hapticsEnabled;
  bool introductionSeen;
  bool welcomeSeen;
  final TodayPuzzle today;
  final Set<String> todayClears;
  final Set<String> todayRewards;
  int coins;
  final Set<String> rewardedWords;
  final Set<String> ownedItems;
  final Set<int> stageFirstClearRewards;
  final Map<int, String> stageRewardDates;
  final Map<int, int> stageRewardAmounts;
  final Set<String> stageAdRewardClaims;

  /// First-arrival messages already presented to the player.
  final Set<String> forestFriendAnnouncements;

  /// Per-area unlock, animal and decoration state. Item coordinates are
  /// normalized within their own area's canvas, independent of screen size
  /// and zoom. This map is additive so future area IDs do not affect old saves.
  final Map<String, ForestAreaProgress> forestAreas;

  /// Backward-compatible area-1 view used by existing placement widgets.
  Map<String, List<double>> get itemPositions =>
      forestAreaProgress(firstForestAreaId).itemPositions;
  String dailyDate;
  final Set<String> dailyWords;
  bool dailyBonusGiven;
  String loginDate;
  String lastAdCoinRewardDate;
  final Set<String> loginClaims;
  int loginDay;
  int lastReward = 0;
  bool lastDailyBonus = false;
  Progress({
    int solved = 0,
    List<String>? guesses,
    int hints = 0,
    String draft = '',
    int? legacyIndex,
    bool? legacyAvailable,
    this.mode,
    Map<int, ModePuzzle>? modes,
    List<PuzzleRecord>? records,
    bool legacyClearRecorded = false,
    this.swipeKeyboard = true,
    this.largeText = false,
    this.reduceMotion = false,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.introductionSeen = true,
    this.welcomeSeen = false,
    TodayPuzzle? today,
    Set<String>? todayClears,
    Set<String>? todayRewards,
    this.coins = 0,
    Set<String>? rewardedWords,
    Set<String>? ownedItems,
    Set<int>? stageFirstClearRewards,
    Map<int, String>? stageRewardDates,
    Map<int, int>? stageRewardAmounts,
    Set<String>? stageAdRewardClaims,
    Set<String>? forestFriendAnnouncements,
    Map<String, List<double>>? itemPositions,
    Map<String, ForestAreaProgress>? forestAreas,
    this.dailyDate = '',
    Set<String>? dailyWords,
    this.dailyBonusGiven = false,
    this.loginDate = '',
    this.lastAdCoinRewardDate = '',
    Set<String>? loginClaims,
    this.loginDay = 0,
  }) : _solved = solved,
       _legacyGuesses = guesses ?? [],
       _legacyHints = hints,
       _legacyDraft = draft,
       _legacyIndex = legacyIndex ?? solved,
       legacyAvailable = legacyAvailable ?? mode == null,
       modes = {...?modes},
       records = List.of(records ?? const <PuzzleRecord>[]),
       _legacyClearRecorded = legacyClearRecorded,
       today = today ?? TodayPuzzle(),
       todayClears = {...?todayClears},
       todayRewards = {...?(todayRewards ?? todayClears)},
       rewardedWords = {...?rewardedWords},
       ownedItems = {...?ownedItems},
       stageFirstClearRewards = {...?stageFirstClearRewards},
       stageRewardDates = {...?stageRewardDates},
       stageRewardAmounts = {...?stageRewardAmounts},
       stageAdRewardClaims = {...?stageAdRewardClaims},
       forestFriendAnnouncements = {...?forestFriendAnnouncements},
       forestAreas = _copyForestAreas(forestAreas, itemPositions),
       dailyWords = {...?dailyWords},
       loginClaims = {...?loginClaims} {
    this.loginClaims.addAll(loginDate.isEmpty ? <String>{} : {loginDate});
    if (mode != null) this.modes.putIfAbsent(mode!, () => ModePuzzle(mode!));
  }
  Word get word => mode == null
      ? legacyWords[_legacyIndex % legacyWords.length]
      : modes[mode]!.word;
  PuzzleStatistics statistics(int length) =>
      PuzzleStatistics.fromRecords(records, length);
  PlayerPerformance get performance =>
      PlayerPerformance(records, todayClears, totalSolved);

  ForestAreaProgress forestAreaProgress(String areaId) =>
      forestAreas.putIfAbsent(
        areaId,
        () => ForestAreaProgress(
          unlocked: areaId == firstForestAreaId,
          animals: areaId == firstForestAreaId ? {'rabbit'} : null,
        ),
      );

  bool forestAreaUnlocked(String areaId) => forestAreaProgress(areaId).unlocked;

  Set<String> forestAnimalsFor(String areaId) {
    final animals = forestAreaProgress(areaId).animals;
    if (areaId == firstForestAreaId) animals.addAll(forestFriends);
    return {...animals};
  }

  void removeForestItemFromAreas(String id) {
    for (final area in forestAreas.values) {
      area.itemPositions.remove(id);
      area.itemAppearances.remove(id);
    }
  }

  void _recordClear(Word answer, int attempts, DateTime now, String source) {
    final id = records.fold<int>(0, (max, r) => r.id > max ? r.id : max) + 1;
    records.add(
      PuzzleRecord(
        id: id,
        word: answer.text,
        length: answer.text.runes.length,
        attempts: attempts,
        date: dayKey(now),
        source: source,
      ),
    );
  }

  int get solved => _solved;
  set solved(int value) {
    _solved = value;
    if (mode == null) _legacyIndex = value;
  }

  List<String> get guesses =>
      mode == null ? _legacyGuesses : modes[mode]!.guesses;
  set guesses(List<String> value) {
    if (mode == null) {
      _legacyGuesses = value;
    } else {
      modes[mode]!.guesses = value;
    }
  }

  int get hints => mode == null ? _legacyHints : modes[mode]!.hints;
  set hints(int value) {
    if (mode == null) {
      _legacyHints = value;
    } else {
      modes[mode]!.hints = value;
    }
  }

  String get draft => mode == null ? _legacyDraft : modes[mode]!.draft;
  set draft(String value) {
    if (mode == null) {
      _legacyDraft = value;
    } else {
      modes[mode]!.draft = value;
    }
  }

  Word get legacyWord => legacyWords[_legacyIndex % legacyWords.length];
  void selectMode(int length) {
    if (![3, 4, 5].contains(length)) throw ArgumentError('mode');
    if (!modes.containsKey(length)) {
      final pool = words
          .where((w) => w.text.length == length)
          .map((w) => w.text)
          .toList();
      final seen = {
        ...rewardedWords,
        ...legacyWords.take(_legacyIndex).map((w) => w.text),
      };
      final adopt = legacyAvailable && legacyWord.text.length == length;
      final order = [
        if (adopt) legacyWord.text,
        ...pool.where(
          (w) => (!adopt || w != legacyWord.text) && !seen.contains(w),
        ),
        ...pool.where(
          (w) => (!adopt || w != legacyWord.text) && seen.contains(w),
        ),
      ];
      modes[length] = ModePuzzle(
        length,
        order: order,
        guesses: adopt ? List.of(_legacyGuesses) : [],
        hints: adopt ? _legacyHints : 0,
        draft: adopt ? _legacyDraft : '',
        clearRecorded: adopt && _legacyClearRecorded,
      );
      if (adopt) {
        legacyAvailable = false;
        _legacyGuesses = [];
        _legacyHints = 0;
        _legacyDraft = '';
      }
    }
    mode = length;
    lastReward = 0;
    lastDailyBonus = false;
  }

  void resumeLegacy() {
    if (legacyAvailable) {
      mode = null;
      lastReward = 0;
      lastDailyBonus = false;
    }
  }

  bool get won => guesses.contains(word.text);
  bool _accept(String text) {
    final guess = normalize(text);
    if (won ||
        guess.runes.length != word.text.runes.length ||
        !RegExp(r'^[ぁ-ゖー]+$').hasMatch(guess)) {
      return false;
    }
    guesses.add(guess);
    return true;
  }

  static String dayKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // Only move forward: changing the clock backwards cannot reclaim a bonus.
  bool refreshDay(DateTime now) {
    final todayChanged = today.refresh(now);
    final key = dayKey(now);
    if (dailyDate.isNotEmpty && key.compareTo(dailyDate) <= 0) {
      return todayChanged;
    }
    dailyDate = key;
    dailyWords.clear();
    dailyBonusGiven = false;
    return true;
  }

  int claimLogin(DateTime now) {
    final today = dayKey(now);
    // Highest claimed/observed local date is never moved backwards.
    if ((loginDate.isNotEmpty && today.compareTo(loginDate) <= 0) ||
        (dailyDate.isNotEmpty && today.compareTo(dailyDate) < 0)) {
      return 0;
    }
    loginDay = loginDay % loginRewards.length + 1;
    loginDate = today;
    final reward = loginRewards[loginDay - 1];
    coins += reward;
    return reward;
  }

  /// Grants the optional rewarded-ad bonus once per local calendar day.
  /// The ISO date high-water mark also prevents a clock rollback from
  /// re-granting a reward already claimed on a later date.
  bool claimAdCoinReward(DateTime now, {int amount = 10}) {
    final today = dayKey(now);
    if (amount <= 0 ||
        today.isEmpty ||
        (lastAdCoinRewardDate.isNotEmpty &&
            today.compareTo(lastAdCoinRewardDate) <= 0)) {
      return false;
    }
    lastAdCoinRewardDate = today;
    coins += amount;
    return true;
  }

  bool submit(String text, {DateTime? now}) {
    if (!_accept(text)) return false;
    lastReward = 0;
    lastDailyBonus = false;
    final today = now ?? DateTime.now();
    refreshDay(today);
    if (won) {
      final recorded = mode == null
          ? _legacyClearRecorded
          : modes[mode]!.clearRecorded;
      if (!recorded) {
        _recordClear(
          word,
          guesses.length,
          today,
          mode == null ? 'legacy' : 'normal',
        );
        if (mode == null) {
          _legacyClearRecorded = true;
        } else {
          modes[mode]!.clearRecorded = true;
        }
      }
      if (rewardedWords.add(word.text)) {
        coins += 10;
        lastReward = 10;
      }
      recordDailyClear(word.text, today);
    }
    return true;
  }

  void recordDailyClear(String text, DateTime now) {
    if (dailyDate == dayKey(now) && !dailyBonusGiven) {
      dailyWords.add(text);
      if (dailyWords.length >= 3) {
        coins += 30;
        dailyBonusGiven = true;
        lastDailyBonus = true;
      }
    }
  }

  bool submitToday(String text, {DateTime? now}) {
    final time = now ?? DateTime.now();
    refreshDay(time);
    if (todayClears.contains(today.date)) return false;
    if (!today.submit(text)) return false;
    lastReward = 0;
    lastDailyBonus = false;
    if (today.won && todayClears.add(today.date)) {
      _recordClear(today.word, today.guesses.length, time, 'daily');
      final latest = todayRewards.fold<String>(
        '',
        (a, b) => a.compareTo(b) > 0 ? a : b,
      );
      // Keep a local high-water mark; moving the clock back cannot mint rewards.
      if (today.date.compareTo(latest) > 0 &&
          today.date.compareTo(dailyDate) >= 0 &&
          today.date.compareTo(loginDate) >= 0 &&
          todayRewards.add(today.date)) {
        coins += 30;
        lastReward = 30;
      }
      recordDailyClear(today.word.text, time);
    }
    return true;
  }

  bool purchase(String id) {
    final matches = forestItems.where((item) => item.id == id);
    if (matches.isEmpty || ownedItems.contains(id)) return false;
    final item = matches.first;
    if (coins < item.price) return false;
    coins -= item.price;
    ownedItems.add(id);
    return true;
  }

  /// Pays a stage's first clear once, then at most one replay reward per local
  /// calendar day. Existing stage stars are passed as [wasPreviouslyCleared],
  /// so old saves never receive a retroactive first-clear bonus.
  int claimStageClearReward(
    int stageId,
    DateTime now, {
    required bool wasPreviouslyCleared,
  }) {
    if (stageId < 1 || stageId > 100) return 0;
    final today = dayKey(now);
    final previousDate = stageRewardDates[stageId] ?? '';
    if (previousDate.compareTo(today) >= 0) return 0;

    final firstClear =
        !wasPreviouslyCleared && stageFirstClearRewards.add(stageId);
    if (wasPreviouslyCleared) stageFirstClearRewards.add(stageId);
    final amount = firstClear ? 20 : 2;
    stageRewardDates[stageId] = today;
    stageRewardAmounts[stageId] = amount;
    coins += amount;
    return amount;
  }

  int stageRewardFor(int stageId, DateTime now) =>
      stageRewardDates[stageId] == dayKey(now)
      ? stageRewardAmounts[stageId] ?? 0
      : 0;

  bool stageAdRewardClaimed(int stageId, DateTime now) =>
      stageAdRewardClaims.contains('$stageId:${dayKey(now)}');

  /// Adds the matching reward only after the ad SDK confirms completion.
  bool claimStageAdReward(int stageId, DateTime now, {String? rewardDate}) {
    final date = rewardDate ?? dayKey(now);
    final amount = stageRewardDates[stageId] == date
        ? stageRewardAmounts[stageId] ?? 0
        : 0;
    final claim = '$stageId:$date';
    if (amount <= 0 || !stageAdRewardClaims.add(claim)) return false;
    coins += amount;
    return true;
  }

  /// Sells an owned forest decoration for half its catalog purchase price.
  /// Returns zero without changing data when the item is not owned.
  int sellForestItem(String id) {
    if (!ownedItems.contains(id)) return 0;
    final matches = forestItems.where((item) => item.id == id);
    if (matches.isEmpty) return 0;
    final amount = matches.first.price ~/ 2;
    ownedItems.remove(id);
    removeForestItemFromAreas(id);
    coins += amount;
    return amount;
  }

  void next() {
    if (!won) return;
    solved++;
    if (mode != null) {
      modes[mode]!.cursor++;
      modes[mode]!.clearRecorded = false;
    } else {
      _legacyClearRecorded = false;
    }
    guesses = [];
    hints = 0;
    draft = '';
    lastReward = 0;
    lastDailyBonus = false;
  }

  int get totalSolved =>
      solved +
      (legacyAvailable && _legacyGuesses.contains(legacyWord.text) ? 1 : 0) +
      modes.values.where((p) => p.won).length +
      todayClears.length;
  Set<String> get forestFriends => {
    'rabbit',
    for (final entry in forestFriendThresholds.entries)
      if (totalSolved >= entry.value) entry.key,
  };
  List<String> get unannouncedForestFriends => forestFriends
      .where((id) => id != 'rabbit' && !forestFriendAnnouncements.contains(id))
      .toList(growable: false);
  String encode() => jsonEncode({
    'version': version,
    'solved': solved,
    'guesses': _legacyGuesses,
    'hints': _legacyHints,
    'draft': _legacyDraft,
    'legacyIndex': _legacyIndex,
    'legacyAvailable': legacyAvailable,
    'mode': mode,
    'records': records.map((r) => r.encode()).toList(),
    'legacyClearRecorded': _legacyClearRecorded,
    'modes': {
      for (final entry in modes.entries) '${entry.key}': entry.value.encode(),
    },
    'swipeKeyboard': swipeKeyboard,
    'largeText': largeText,
    'reduceMotion': reduceMotion,
    'soundEnabled': soundEnabled,
    'musicEnabled': musicEnabled,
    'hapticsEnabled': hapticsEnabled,
    'introductionSeen': introductionSeen,
    'welcomeSeen': welcomeSeen,
    'today': today.encode(),
    'todayClears': todayClears.toList(),
    'todayRewards': todayRewards.toList(),
    'coins': coins,
    'stageFirstClearRewards': stageFirstClearRewards.toList(),
    'stageRewardDates': {
      for (final entry in stageRewardDates.entries) '${entry.key}': entry.value,
    },
    'stageRewardAmounts': {
      for (final entry in stageRewardAmounts.entries)
        '${entry.key}': entry.value,
    },
    'stageAdRewardClaims': stageAdRewardClaims.toList(),
    'rewardedWords': rewardedWords.toList(),
    'ownedItems': ownedItems.toList(),
    // Keep the flat field for older builds while the nested map becomes the
    // canonical, area-aware format.
    'itemPositions': itemPositions,
    'forestAreas': {
      for (final entry in forestAreas.entries)
        entry.key: ForestAreaProgress(
          unlocked: entry.key == firstForestAreaId || entry.value.unlocked,
          animals: entry.key == firstForestAreaId
              ? {...entry.value.animals, ...forestFriends}
              : entry.value.animals,
          itemPositions: entry.value.itemPositions,
          itemAppearances: entry.value.itemAppearances,
        ).encode(),
    },
    'forestFriendAnnouncements': forestFriendAnnouncements.toList(),
    'dailyDate': dailyDate,
    'dailyWords': dailyWords.toList(),
    'dailyBonusGiven': dailyBonusGiven,
    'loginDate': loginDate,
    'lastAdCoinRewardDate': lastAdCoinRewardDate,
    'loginDay': loginDay,
  });
  factory Progress.decode(String? raw) {
    if (raw == null) return Progress();
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != version) return Progress();
      final solved = data['solved'] as int;
      final hints = data['hints'] as int;
      if (solved < 0 || hints < 0 || hints > 2) return Progress();
      final p = Progress(
        solved: solved,
        hints: hints,
        draft: data['draft'] as String? ?? '',
        legacyIndex: data['legacyIndex'] as int?,
        legacyAvailable: data['legacyAvailable'] as bool?,
        records: PuzzleRecord.decodeList(data['records']),
        legacyClearRecorded: data['legacyClearRecorded'] as bool? ?? false,
        swipeKeyboard: data['swipeKeyboard'] as bool? ?? true,
        largeText: data['largeText'] as bool,
        reduceMotion: data['reduceMotion'] as bool? ?? false,
        soundEnabled: data['soundEnabled'] as bool? ?? true,
        musicEnabled: data['musicEnabled'] as bool? ?? true,
        hapticsEnabled: data['hapticsEnabled'] as bool? ?? true,
        introductionSeen: data['introductionSeen'] as bool? ?? true,
        welcomeSeen: data['welcomeSeen'] as bool? ?? false,
        today: TodayPuzzle.decode(data['today']),
        todayClears: (data['todayClears'] as List?)?.cast<String>().toSet(),
        todayRewards: (data['todayRewards'] as List?)?.cast<String>().toSet(),
        coins: data['coins'] as int? ?? 0,
        stageFirstClearRewards: (data['stageFirstClearRewards'] as List?)
            ?.whereType<int>()
            .toSet(),
        stageRewardDates: _decodeIntStringMap(data['stageRewardDates']),
        stageRewardAmounts: _decodeIntIntMap(data['stageRewardAmounts']),
        stageAdRewardClaims: (data['stageAdRewardClaims'] as List?)
            ?.whereType<String>()
            .toSet(),
        rewardedWords: (data['rewardedWords'] as List?)?.cast<String>().toSet(),
        ownedItems: (data['ownedItems'] as List?)?.cast<String>().toSet(),
        forestFriendAnnouncements: data['forestFriendAnnouncements'] is List
            ? (data['forestFriendAnnouncements'] as List)
                  .whereType<String>()
                  .toSet()
            : null,
        itemPositions: _decodeItemPositions(data['itemPositions']),
        forestAreas: _decodeForestAreas(
          data['forestAreas'],
          _decodeItemPositions(data['itemPositions']),
        ),
        dailyDate: data['dailyDate'] as String? ?? '',
        dailyWords: (data['dailyWords'] as List?)?.cast<String>().toSet(),
        dailyBonusGiven: data['dailyBonusGiven'] as bool? ?? false,
        loginDate: data['loginDate'] as String? ?? '',
        lastAdCoinRewardDate: data['lastAdCoinRewardDate'] as String? ?? '',
        loginDay: data['loginDay'] as int? ?? 0,
      );
      for (final area in p.forestAreas.values) {
        area.itemPositions.removeWhere(
          (id, _) =>
              !p.ownedItems.contains(id) ||
              !forestItems.any((item) => item.id == id),
        );
      }
      p.forestFriendAnnouncements.removeWhere(
        (id) => !forestFriendThresholds.containsKey(id),
      );
      // Existing saves should not receive retroactive unlock popups.
      if (!data.containsKey('forestFriendAnnouncements')) {
        p.forestFriendAnnouncements.addAll(p.unannouncedForestFriends);
      }
      if (!data.containsKey('itemPositions')) {
        // Preserve the original fixed garden locations for existing saves.
        p.itemPositions.addAll({
          if (p.ownedItems.contains('tulip')) 'tulip': [.302, .95],
          if (p.ownedItems.contains('mushroom')) 'mushroom': [.824, .973],
          if (p.ownedItems.contains('sunflower')) 'sunflower': [.617, .95],
          if (p.ownedItems.contains('butterfly')) 'butterfly': [.224, .438],
          if (p.ownedItems.contains('cherry')) 'cherry': [.624, .722],
        });
      }
      for (final guess in (data['guesses'] as List).cast<String>()) {
        if (!p._accept(guess)) return Progress();
      }
      if (p.coins < 0 ||
          p.loginDay < 0 ||
          p.loginDay > 7 ||
          (p.loginDate.isEmpty != (p.loginDay == 0)) ||
          p.dailyWords.length > 3 ||
          p.ownedItems.any((id) => !forestItems.any((item) => item.id == id)) ||
          p.rewardedWords.any(
            (text) => !words.any((word) => word.text == text),
          ) ||
          p.dailyWords.any((text) => !words.any((word) => word.text == text)) ||
          (p.dailyWords.length == 3) != p.dailyBonusGiven) {
        return Progress();
      }
      if (!data.containsKey('rewardedWords')) {
        // Old clears stay cleared; loading them must never issue new rewards.
        p.rewardedWords.addAll(
          legacyWords.take(p.totalSolved).map((word) => word.text),
        );
      }
      final savedModes = data['modes'] as Map<String, dynamic>? ?? {};
      for (final entry in savedModes.entries) {
        final length = int.parse(entry.key);
        p.modes[length] = ModePuzzle.decode(length, entry.value);
      }
      p.mode = data['mode'] as int?;
      if (p.mode != null && !p.modes.containsKey(p.mode)) return Progress();
      return p;
    } catch (_) {
      return Progress();
    }
  }

  static Map<String, List<double>> _decodeItemPositions(dynamic value) {
    if (value is! Map) return {};
    final result = <String, List<double>>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! List) continue;
      final rawCoords = entry.value as List;
      if (rawCoords.any((v) => v is! num)) continue;
      final coords = rawCoords.map((v) => (v as num).toDouble()).toList();
      if (coords.length != 2 ||
          coords.any((v) => !v.isFinite || v < 0 || v > 1)) {
        continue;
      }
      result[entry.key as String] = coords;
    }
    return result;
  }

  static Map<int, String> _decodeIntStringMap(dynamic value) {
    if (value is! Map) return {};
    final result = <int, String>{};
    for (final entry in value.entries) {
      final key = int.tryParse('${entry.key}');
      if (key == null || key < 1) continue;
      final date = entry.value;
      if (date is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        result[key] = date;
      }
    }
    return result;
  }

  static Map<int, int> _decodeIntIntMap(dynamic value) {
    if (value is! Map) return {};
    final result = <int, int>{};
    for (final entry in value.entries) {
      final key = int.tryParse('${entry.key}');
      final amount = entry.value;
      if (key != null && key > 0 && amount is int && amount >= 0) {
        result[key] = amount;
      }
    }
    return result;
  }

  static Map<String, List<double>> _copyItemPositions(
    Map<String, List<double>>? positions,
  ) {
    if (positions == null) return {};
    return {
      for (final entry in positions.entries)
        entry.key: List<double>.of(entry.value),
    };
  }

  static Map<String, ForestItemAppearance> _decodeItemAppearances(
    dynamic value,
  ) {
    if (value is! Map) return {};
    final result = <String, ForestItemAppearance>{};
    for (final entry in value.entries) {
      if (entry.key is! String) continue;
      final appearance = ForestItemAppearance.decode(entry.value);
      if (appearance != null) result[entry.key as String] = appearance;
    }
    return result;
  }

  static Map<String, ForestAreaProgress> _decodeForestAreas(
    dynamic value,
    Map<String, List<double>> legacyPositions,
  ) {
    final result = <String, ForestAreaProgress>{};
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.key is! String || (entry.key as String).isEmpty) continue;
        final raw = entry.value;
        if (raw is! Map) continue;
        final animals = raw['animals'] is List
            ? (raw['animals'] as List).whereType<String>().toSet()
            : <String>{};
        result[entry.key as String] = ForestAreaProgress(
          unlocked: raw['unlocked'] == true,
          animals: animals,
          itemPositions: _decodeItemPositions(raw['itemPositions']),
          itemAppearances: _decodeItemAppearances(raw['itemAppearances']),
        );
      }
    }
    result.putIfAbsent(
      firstForestAreaId,
      () => ForestAreaProgress(
        unlocked: true,
        animals: {'rabbit'},
        itemPositions: legacyPositions,
      ),
    );
    final first = result[firstForestAreaId]!;
    first.unlocked = true;
    first.animals.add('rabbit');
    // Old saves stored placements at the top level. Use them when no nested
    // area-1 placement was saved; never overwrite the canonical nested data.
    if (first.itemPositions.isEmpty) {
      first.itemPositions.addAll(_copyItemPositions(legacyPositions));
    }
    return result;
  }

  static Map<String, ForestAreaProgress> _copyForestAreas(
    Map<String, ForestAreaProgress>? areas,
    Map<String, List<double>>? legacyPositions,
  ) {
    final copied = <String, ForestAreaProgress>{
      for (final entry
          in areas?.entries ?? const <MapEntry<String, ForestAreaProgress>>[])
        entry.key: ForestAreaProgress(
          unlocked: entry.value.unlocked,
          animals: entry.value.animals,
          itemPositions: entry.value.itemPositions,
          itemAppearances: entry.value.itemAppearances,
        ),
    };
    copied.putIfAbsent(
      firstForestAreaId,
      () => ForestAreaProgress(
        unlocked: true,
        animals: {'rabbit'},
        itemPositions: legacyPositions,
      ),
    );
    copied[firstForestAreaId]!.unlocked = true;
    copied[firstForestAreaId]!.animals.add('rabbit');
    if (areas == null && legacyPositions != null) {
      copied[firstForestAreaId]!.itemPositions
        ..clear()
        ..addAll(_copyItemPositions(legacyPositions));
    }
    return copied;
  }
}
